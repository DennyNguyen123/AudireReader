use reqwest::{Client, header::{HeaderMap, HeaderValue, USER_AGENT, CONTENT_TYPE, ACCEPT}};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use regex::Regex;
use parking_lot::RwLock;
use once_cell::sync::Lazy;

static REQWEST_CLIENT: Lazy<Client> = Lazy::new(|| Client::new());

const TRUSTED_CLIENT_TOKEN: &str = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
const USER_AGENT_STR: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EdgeToken {
    pub key: String,
    pub token: String,
    pub cookie: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EdgeVoice {
    #[serde(rename = "Name")]
    pub name: String,
    #[serde(rename = "ShortName")]
    pub short_name: String,
    #[serde(rename = "Gender")]
    pub gender: String,
    #[serde(rename = "Locale")]
    pub locale: String,
}

static CACHED_TOKEN: Lazy<RwLock<Option<(EdgeToken, u64)>>> = Lazy::new(|| RwLock::new(None));
static TOKEN_LOCK: Lazy<tokio::sync::Mutex<()>> = Lazy::new(|| tokio::sync::Mutex::new(()));
const TOKEN_TTL: u64 = 5 * 60 * 1000; // 5 mins

fn current_time_ms() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_millis() as u64
}

async fn fetch_bing_token_internal(client: &Client) -> Result<EdgeToken, String> {
    let mut retries = 0;
    let mut last_err = String::new();

    while retries < 3 {
        let mut headers = HeaderMap::new();
        headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_STR));
        headers.insert("Accept", HeaderValue::from_static("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"));
        headers.insert("Accept-Language", HeaderValue::from_static("vi,en-US;q=0.9,en;q=0.8"));
        headers.insert("Sec-Ch-Ua", HeaderValue::from_static("\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Microsoft Edge\";v=\"120\""));
        headers.insert("Sec-Ch-Ua-Mobile", HeaderValue::from_static("?0"));
        headers.insert("Sec-Ch-Ua-Platform", HeaderValue::from_static("\"Windows\""));
        headers.insert("Sec-Fetch-Dest", HeaderValue::from_static("document"));
        headers.insert("Sec-Fetch-Mode", HeaderValue::from_static("navigate"));
        headers.insert("Sec-Fetch-Site", HeaderValue::from_static("none"));
        headers.insert("Sec-Fetch-User", HeaderValue::from_static("?1"));
        headers.insert("Upgrade-Insecure-Requests", HeaderValue::from_static("1"));

        match client.get("https://www.bing.com/translator").headers(headers).send().await {
            Ok(res) => {
                let cookie = if let Some(cookie_header) = res.headers().get("set-cookie") {
                    let cookie_str = cookie_header.to_str().unwrap_or("");
                    let parts: Vec<&str> = cookie_str.split(',').collect();
                    let mut clean_cookies = Vec::new();
                    for p in parts {
                        if let Some(c) = p.split(';').next() {
                            clean_cookies.push(c);
                        }
                    }
                    clean_cookies.join("; ")
                } else {
                    String::new()
                };

                if let Ok(html) = res.text().await {
                    // Pattern 1: params_AbusePreventionHelper = [key, token, TTL]
                    let re1 = Regex::new(r"params_AbusePreventionHelper\s*=\s*\[([^,]+),([^,]+),").unwrap();
                    if let Some(caps) = re1.captures(&html) {
                        let key = caps.get(1).map_or("", |m| m.as_str()).to_string();
                        let token = caps.get(2).map_or("", |m| m.as_str()).replace('"', "");
                        if !key.is_empty() && !token.is_empty() {
                            return Ok(EdgeToken { key, token, cookie });
                        }
                    }

                    // Pattern 2: IG:"...", token:"..." or key:"..."
                    let re_ig = Regex::new(r#"IG:"([^"]+)""#).unwrap();
                    let re_tok = Regex::new(r#"token:"([^"]+)""#).unwrap();
                    if let (Some(c1), Some(c2)) = (re_ig.captures(&html), re_tok.captures(&html)) {
                        let key = c1.get(1).map_or("", |m| m.as_str()).to_string();
                        let token = c2.get(1).map_or("", |m| m.as_str()).to_string();
                        if !key.is_empty() && !token.is_empty() {
                            return Ok(EdgeToken { key, token, cookie });
                        }
                    }

                    last_err = "HTML received but params_AbusePreventionHelper token pattern not found".to_string();
                } else {
                    last_err = "Failed to read response body text".to_string();
                }
            }
            Err(e) => {
                last_err = format!("HTTP GET bing.com/translator failed: {}", e);
            }
        }

        retries += 1;
        tokio::time::sleep(std::time::Duration::from_millis(1500 * retries as u64)).await;
    }

    Err(format!("Failed to parse Bing token after 3 retries: {}", last_err))
}

async fn get_token(client: &Client) -> Result<EdgeToken, String> {
    let now = current_time_ms();
    
    // Fast read check
    {
        let cache = CACHED_TOKEN.read();
        if let Some((token, time)) = &*cache {
            if now - time < TOKEN_TTL {
                return Ok(token.clone());
            }
        }
    }

    // Single-Flight Barrier: Only ONE thread fetches fresh token
    let _guard = TOKEN_LOCK.lock().await;

    // Double check cache after acquiring lock
    {
        let cache = CACHED_TOKEN.read();
        if let Some((token, time)) = &*cache {
            if now - time < TOKEN_TTL {
                return Ok(token.clone());
            }
        }
    }

    let token = fetch_bing_token_internal(client).await?;
    {
        let mut cache = CACHED_TOKEN.write();
        *cache = Some((token.clone(), now));
    }

    Ok(token)
}

fn convert_rate(rate: f64) -> String {
    let percentage = ((rate - 0.5) / 0.5 * 100.0).round() as i32;
    if percentage >= 0 {
        format!("+{}%", percentage)
    } else {
        format!("{}%", percentage)
    }
}

pub async fn get_edge_voices() -> Result<Vec<EdgeVoice>, String> {
    let url = format!("https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken={}", TRUSTED_CLIENT_TOKEN);
    let client = Client::new();
    
    let mut headers = HeaderMap::new();
    headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_STR));
    headers.insert("Accept-Language", HeaderValue::from_static("en-US,en;q=0.9"));
    
    let res = client.get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| format!("Failed to fetch voices: {}", e))?;
        
    if res.status().is_success() {
        let voices: Vec<EdgeVoice> = res.json().await.map_err(|e| format!("JSON parse error: {}", e))?;
        Ok(voices)
    } else {
        Err(format!("Error fetching voices: {}", res.status()))
    }
}

pub async fn synthesize_edge_tts(text: String, voice_id: String, rate: f64) -> Result<Vec<u8>, String> {
    let client = &*REQWEST_CLIENT;
    let mut token = get_token(&client).await?;
    
    let rate_str = convert_rate(rate);
    let parts: Vec<&str> = voice_id.split('-').collect();
    let xml_lang = if parts.len() >= 2 {
        format!("{}-{}", parts[0], parts[1])
    } else {
        "en-US".to_string()
    };
    
    let gender = if voice_id.to_lowercase().contains("male") { "Male" } else { "Female" };
    
    let escaped_text = text
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;");
        
    let ssml = format!(
        "<speak version='1.0' xml:lang='{}'><voice xml:lang='{}' xml:gender='{}' name='{}'><prosody rate='{}'>{}</prosody></voice></speak>",
        xml_lang, xml_lang, gender, voice_id, rate_str, escaped_text
    );
    
    let url = "https://www.bing.com/tfettts?isVertical=1&&IG=1&IID=translator.5023&SFX=1";
    
    let get_req = |t: &EdgeToken| {
        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/x-www-form-urlencoded"));
        headers.insert(ACCEPT, HeaderValue::from_static("*/*"));
        headers.insert("Origin", HeaderValue::from_static("https://www.bing.com"));
        headers.insert("Referer", HeaderValue::from_static("https://www.bing.com/translator"));
        headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_STR));
        
        if !t.cookie.is_empty() {
            if let Ok(cookie_val) = HeaderValue::from_str(&t.cookie) {
                headers.insert("Cookie", cookie_val);
            }
        }
        
        let params = [
            ("ssml", ssml.clone()),
            ("token", t.token.clone()),
            ("key", t.key.clone()),
        ];
        
        client.post(url).headers(headers).form(&params)
    };
    
    let mut res = get_req(&token).send().await.map_err(|e| e.to_string())?;
    
    if res.status().as_u16() == 429 || res.status().as_u16() == 403 {
        // Clear token and retry
        {
            let mut cache = CACHED_TOKEN.write();
            *cache = None;
        }
        token = get_token(&client).await?;
        res = get_req(&token).send().await.map_err(|e| e.to_string())?;
        
        if !res.status().is_success() {
            return Err(format!("Bing TTS failed on retry: {}", res.status()));
        }
    } else if !res.status().is_success() {
        return Err(format!("Bing TTS failed: {}", res.status()));
    }
    
    let bytes = res.bytes().await.map_err(|e| e.to_string())?;
    if bytes.len() < 1024 {
        {
            let mut cache = CACHED_TOKEN.write();
            *cache = None;
        }
        return Err(format!("Bing TTS returned small audio ({} bytes). Token invalidated.", bytes.len()));
    }
    
    Ok(bytes.to_vec())
}

pub async fn synthesize_openai_tts(text: String, voice: String, api_key: String, speed: f64) -> Result<Vec<u8>, String> {
    let client = &*REQWEST_CLIENT;
    let url = "https://api.openai.com/v1/audio/speech";

    let mut headers = HeaderMap::new();
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    if let Ok(auth_val) = HeaderValue::from_str(&format!("Bearer {}", api_key)) {
        headers.insert(reqwest::header::AUTHORIZATION, auth_val);
    }

    let payload = serde_json::json!({
        "model": "tts-1",
        "input": text,
        "voice": voice,
        "speed": speed
    });

    let res = client.post(url)
        .headers(headers)
        .json(&payload)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    if !res.status().is_success() {
        return Err(format!("OpenAI TTS failed: {}", res.status()));
    }

    let bytes = res.bytes().await.map_err(|e| e.to_string())?;
    Ok(bytes.to_vec())
}

use tts::Tts;

static OFFLINE_TTS: Lazy<parking_lot::Mutex<Option<Tts>>> = Lazy::new(|| parking_lot::Mutex::new(None));

pub fn init_offline_tts() -> Result<bool, String> {
    let mut tts_opt = OFFLINE_TTS.lock();
    if tts_opt.is_none() {
        match Tts::default() {
            Ok(t) => {
                *tts_opt = Some(t);
                Ok(true)
            },
            Err(e) => Err(format!("Failed to init offline TTS: {}", e))
        }
    } else {
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;
    use tokio::task::JoinHandle;

    #[tokio::test]
    async fn test_concurrent_100_threads_get_token() {
        println!("Starting 100 concurrent threads get_token test...");
        let client = Arc::new(Client::new());
        let mut handles: Vec<JoinHandle<Result<EdgeToken, String>>> = Vec::new();

        for i in 0..100 {
            let client_clone = client.clone();
            handles.push(tokio::spawn(async move {
                let token = get_token(&client_clone).await?;
                println!("Thread {} successfully got token (key len: {})", i, token.key.len());
                Ok(token)
            }));
        }

        let mut success_count = 0;
        for handle in handles {
            let res = handle.await.unwrap();
            assert!(res.is_ok(), "Thread failed to get Bing token: {:?}", res.err());
            success_count += 1;
        }

        assert_eq!(success_count, 100);
        println!("TEST PASSED: 100/100 threads successfully acquired Bing token without error!");
    }
}

pub fn offline_tts_speak(text: String, _rate: f32) -> Result<bool, String> {
    let mut tts_opt = OFFLINE_TTS.lock();
    if let Some(t) = &mut *tts_opt {
        t.speak(text, true).map_err(|e| e.to_string())?;
        Ok(true)
    } else {
        Err("Offline TTS not initialized".to_string())
    }
}

pub fn offline_tts_stop() -> Result<bool, String> {
    let mut tts_opt = OFFLINE_TTS.lock();
    if let Some(t) = &mut *tts_opt {
        t.stop().map_err(|e| e.to_string())?;
        Ok(true)
    } else {
        Err("Offline TTS not initialized".to_string())
    }
}


