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

fn get_silent_wav() -> Vec<u8> {
    let mut header = vec![0u8; 44];
    header[0..4].copy_from_slice(b"RIFF");
    let file_size: u32 = 36;
    header[4..8].copy_from_slice(&file_size.to_le_bytes());
    header[8..12].copy_from_slice(b"WAVE");
    header[12..16].copy_from_slice(b"fmt ");
    let chunk_size: u32 = 16;
    header[16..20].copy_from_slice(&chunk_size.to_le_bytes());
    let format_type: u16 = 1;
    header[20..22].copy_from_slice(&format_type.to_le_bytes());
    let channels: u16 = 1;
    header[22..24].copy_from_slice(&channels.to_le_bytes());
    let sample_rate: u32 = 16000;
    header[24..28].copy_from_slice(&sample_rate.to_le_bytes());
    let byte_rate: u32 = 32000;
    header[28..32].copy_from_slice(&byte_rate.to_le_bytes());
    let block_align: u16 = 2;
    header[32..34].copy_from_slice(&block_align.to_le_bytes());
    let bits_per_sample: u16 = 16;
    header[34..36].copy_from_slice(&bits_per_sample.to_le_bytes());
    header[36..40].copy_from_slice(b"data");
    let data_size: u32 = 0;
    header[40..44].copy_from_slice(&data_size.to_le_bytes());
    header
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
    if !text.chars().any(|c| c.is_alphanumeric()) {
        return Ok(get_silent_wav());
    }

    let client = &*REQWEST_CLIENT;
    let mut token = get_token(&client).await?;
    
    let mut actual_voice_id = voice_id.clone();
    if actual_voice_id.starts_with('{') && actual_voice_id.contains("name:") {
        if let Some(name_start) = actual_voice_id.find("name:") {
            let name_sub = &actual_voice_id[name_start + 5..];
            let name_sub_trimmed = name_sub.trim();
            if let Some(comma_pos) = name_sub_trimmed.find(',') {
                actual_voice_id = name_sub_trimmed[..comma_pos].trim().to_string();
            } else if let Some(brace_pos) = name_sub_trimmed.find('}') {
                actual_voice_id = name_sub_trimmed[..brace_pos].trim().to_string();
            }
        }
    }

    let rate_str = convert_rate(rate);
    let parts: Vec<&str> = actual_voice_id.split('-').collect();
    let xml_lang = if parts.len() >= 2 {
        format!("{}-{}", parts[0], parts[1])
    } else {
        "en-US".to_string()
    };
    
    let gender = if actual_voice_id.to_lowercase().contains("male") { "Male" } else { "Female" };
    
    let escaped_text = text
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;");
        
    let ssml = format!(
        "<speak version='1.0' xml:lang='{}'><voice xml:lang='{}' xml:gender='{}' name='{}'><prosody rate='{}'>{}</prosody></voice></speak>",
        xml_lang, xml_lang, gender, actual_voice_id, rate_str, escaped_text
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
            println!("[Edge TTS Error] Retry failed. Status: {}, SSML: {}", res.status(), ssml);
            return Err(format!("Bing TTS failed on retry: {}", res.status()));
        }
    } else if !res.status().is_success() {
        println!("[Edge TTS Error] First try failed. Status: {}, SSML: {}", res.status(), ssml);
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

pub async fn synthesize_openai_tts(
    text: String,
    voice: String,
    api_key: String,
    speed: f64,
    endpoint: Option<String>,
    model: Option<String>,
) -> Result<Vec<u8>, String> {
    if !text.chars().any(|c| c.is_alphanumeric()) {
        return Ok(get_silent_wav());
    }

    let client = &*REQWEST_CLIENT;

    let base_endpoint = endpoint
        .filter(|e| !e.trim().is_empty())
        .unwrap_or_else(|| "https://api.openai.com/v1".to_string());
    
    let trimmed_endpoint = base_endpoint.trim_end_matches('/');
    let url = if trimmed_endpoint.ends_with("/audio/speech") {
        trimmed_endpoint.to_string()
    } else {
        format!("{}/audio/speech", trimmed_endpoint)
    };

    let model_name = model
        .filter(|m| !m.trim().is_empty())
        .unwrap_or_else(|| "tts-1".to_string());

    let mut headers = HeaderMap::new();
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    if !api_key.is_empty() {
        if let Ok(auth_val) = HeaderValue::from_str(&format!("Bearer {}", api_key)) {
            headers.insert(reqwest::header::AUTHORIZATION, auth_val);
        }
    }

    let mut calculated_speed = speed * 2.0;
    if calculated_speed < 0.25 {
        calculated_speed = 0.25;
    }
    if calculated_speed > 4.0 {
        calculated_speed = 4.0;
    }

    let mut payload = serde_json::json!({
        "model": model_name,
        "input": text,
        "response_format": "mp3",
        "speed": calculated_speed
    });

    if !voice.is_empty() {
        payload["voice"] = serde_json::json!(voice);
    }

    if !url.contains("api.openai.com") {
        if let Some(obj) = payload.as_object_mut() {
            obj.remove("response_format");
            if (calculated_speed - 1.0).abs() < 0.01 {
                obj.remove("speed");
            }
        }
    }

    let res = client
        .post(&url)
        .headers(headers)
        .json(&payload)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    if !res.status().is_success() {
        let status = res.status();
        let err_text = res.text().await.unwrap_or_default();
        return Err(format!("OpenAI TTS failed: {} - {}", status, err_text));
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

#[cfg(target_os = "windows")]
pub async fn synthesize_system_tts_to_wav(
    text: String,
    voice_name: Option<String>,
    rate: f64,
) -> Result<Vec<u8>, String> {
    use windows::Media::SpeechSynthesis::SpeechSynthesizer;
    use windows::Storage::Streams::DataReader;

    let synth = SpeechSynthesizer::new().map_err(|e| format!("Failed to create SpeechSynthesizer: {}", e))?;

    // Voice Selection
    let voices = SpeechSynthesizer::AllVoices().map_err(|e| format!("Failed to get voices: {}", e))?;
    let mut target_voice = None;

    if let Some(ref selected_name) = voice_name {
        if !selected_name.is_empty() && selected_name != "default" {
            for v in &voices {
                if let Ok(display_name) = v.DisplayName() {
                    let display_str = display_name.to_string();
                    if display_str == *selected_name || display_str.contains(selected_name.as_str()) {
                        target_voice = Some(v);
                        break;
                    }
                }
            }
        }
    }

    if target_voice.is_none() {
        for v in &voices {
            if let Ok(lang) = v.Language() {
                let lang_str = lang.to_string();
                if lang_str.to_lowercase().contains("vi") {
                    target_voice = Some(v);
                    break;
                }
            }
        }
    }

    if let Some(v) = target_voice {
        let _ = synth.SetVoice(&v);
    }

    // Rate Options
    if let Ok(options) = synth.Options() {
        let mut winrt_rate = rate * 2.0;
        if winrt_rate < 0.5 {
            winrt_rate = 0.5;
        }
        if winrt_rate > 6.0 {
            winrt_rate = 6.0;
        }
        let _ = options.SetSpeakingRate(winrt_rate);
    }

    let hstring_text = windows::core::HSTRING::from(&text);
    let stream_op = synth
        .SynthesizeTextToStreamAsync(&hstring_text)
        .map_err(|e| format!("SynthesizeTextToStreamAsync failed: {}", e))?;

    let stream = stream_op
        .get()
        .map_err(|e| format!("Synthesize stream get failed: {}", e))?;

    let size = stream
        .Size()
        .map_err(|e| format!("Failed to get stream size: {}", e))? as u32;

    let input_stream = stream
        .GetInputStreamAt(0)
        .map_err(|e| format!("Failed to get input stream: {}", e))?;

    let reader = DataReader::CreateDataReader(&input_stream)
        .map_err(|e| format!("Failed to create DataReader: {}", e))?;

    let _ = reader
        .LoadAsync(size)
        .map_err(|e| format!("LoadAsync failed: {}", e))?
        .get();

    let mut buffer = vec![0u8; size as usize];
    reader
        .ReadBytes(&mut buffer)
        .map_err(|e| format!("ReadBytes failed: {}", e))?;

    Ok(buffer)
}

#[cfg(not(target_os = "windows"))]
pub async fn synthesize_system_tts_to_wav(
    _text: String,
    _voice_name: Option<String>,
    _rate: f64,
) -> Result<Vec<u8>, String> {
    Err("System TTS to WAV is only supported on Windows".to_string())
}


