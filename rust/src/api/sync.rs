use reqwest::{Client, Method, header::{HeaderMap, HeaderValue, AUTHORIZATION}};
use once_cell::sync::Lazy;
use quick_xml::Reader;
use quick_xml::events::Event;
use std::path::Path;
use serde::{Deserialize, Serialize};
use base64::{Engine as _, engine::general_purpose::STANDARD as b64};

#[derive(Debug, Serialize, Deserialize)]
pub struct WebDavFile {
    pub name: String,
    pub path: String,
    pub is_dir: bool,
    pub size: i64,
    pub last_modified: String,
}

#[derive(Clone)]
pub struct WebDavClient {
    client: Client,
    base_url: String,
    auth_header: String,
}

impl WebDavClient {
    pub fn new(url: &str, user: &str, pass: &str) -> Result<Self, String> {
        let mut formatted_url = url.trim().to_string();
        if !formatted_url.starts_with("http://") && !formatted_url.starts_with("https://") {
            formatted_url = format!("https://{}", formatted_url);
        }
        
        let auth = format!("{}:{}", user.trim(), pass);
        let auth_b64 = b64.encode(auth);
        let auth_header = format!("Basic {}", auth_b64);
        
        Ok(WebDavClient {
            client: Client::new(),
            base_url: formatted_url,
            auth_header,
        })
    }
    
    fn headers(&self) -> HeaderMap {
        let mut h = HeaderMap::new();
        h.insert(AUTHORIZATION, HeaderValue::from_str(&self.auth_header).unwrap());
        h
    }

    pub async fn test_connection(&self) -> Result<bool, String> {
        // Simple PROPFIND to root
        let propfind = Method::from_bytes(b"PROPFIND").unwrap();
        let mut h = self.headers();
        h.insert("Depth", HeaderValue::from_static("0"));
        
        let res = self.client.request(propfind, &self.base_url)
            .headers(h)
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        Ok(res.status().is_success() || res.status().as_u16() == 207)
    }

    pub async fn mkdir(&self, remote_path: &str) -> Result<bool, String> {
        let url = format!("{}/{}", self.base_url.trim_end_matches('/'), remote_path.trim_start_matches('/'));
        let mkcol = Method::from_bytes(b"MKCOL").unwrap();
        
        let res = self.client.request(mkcol, &url)
            .headers(self.headers())
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        // 201 Created or 405 Method Not Allowed (Already exists)
        Ok(res.status().is_success() || res.status().as_u16() == 405)
    }

    pub async fn upload_bytes(&self, remote_path: &str, bytes: Vec<u8>) -> Result<bool, String> {
        let url = format!("{}/{}", self.base_url.trim_end_matches('/'), remote_path.trim_start_matches('/'));
        
        let res = self.client.put(&url)
            .headers(self.headers())
            .body(bytes)
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        Ok(res.status().is_success())
    }

    pub async fn download_bytes(&self, remote_path: &str) -> Result<Vec<u8>, String> {
        let url = format!("{}/{}", self.base_url.trim_end_matches('/'), remote_path.trim_start_matches('/'));
        
        let res = self.client.get(&url)
            .headers(self.headers())
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        if !res.status().is_success() {
            return Err(format!("Download failed: {}", res.status()));
        }
        
        let bytes = res.bytes().await.map_err(|e| e.to_string())?;
        Ok(bytes.to_vec())
    }

    pub async fn upload_file(&self, remote_path: &str, local_path: &str) -> Result<bool, String> {
        let path = Path::new(local_path);
        if !path.exists() {
            return Err(format!("Local file does not exist: {}", local_path));
        }
        
        let bytes = tokio::fs::read(path).await.map_err(|e| e.to_string())?;
        self.upload_bytes(remote_path, bytes).await
    }

    pub async fn download_file(&self, remote_path: &str, local_path: &str) -> Result<bool, String> {
        let bytes = self.download_bytes(remote_path).await?;
        
        let path = Path::new(local_path);
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent).await.map_err(|e| e.to_string())?;
        }
        
        tokio::fs::write(path, bytes).await.map_err(|e| e.to_string())?;
        Ok(true)
    }

    pub async fn list_files(&self, remote_path: &str) -> Result<Vec<WebDavFile>, String> {
        let url = format!("{}/{}", self.base_url.trim_end_matches('/'), remote_path.trim_start_matches('/'));
        let propfind = Method::from_bytes(b"PROPFIND").unwrap();
        let mut h = self.headers();
        h.insert("Depth", HeaderValue::from_static("1"));
        
        let res = self.client.request(propfind, &url)
            .headers(h)
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        if !res.status().is_success() && res.status().as_u16() != 207 {
            return Err(format!("PROPFIND failed with status: {}", res.status()));
        }
        
        let xml_text = res.text().await.map_err(|e| e.to_string())?;
        parse_webdav_xml(&xml_text)
    }

    pub async fn remove(&self, remote_path: &str) -> Result<bool, String> {
        let url = format!("{}/{}", self.base_url.trim_end_matches('/'), remote_path.trim_start_matches('/'));
        
        let res = self.client.delete(&url)
            .headers(self.headers())
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        Ok(res.status().is_success())
    }

    pub async fn file_exists(&self, remote_path: &str) -> Result<bool, String> {
        let url = format!("{}/{}", self.base_url.trim_end_matches('/'), remote_path.trim_start_matches('/'));
        
        let res = self.client.request(Method::from_bytes(b"PROPFIND").unwrap(), &url)
            .headers(self.headers())
            .header("Depth", "0")
            .send()
            .await
            .map_err(|e| e.to_string())?;
            
        Ok(res.status().is_success() || res.status().as_u16() == 207)
    }
}

fn parse_webdav_xml(xml: &str) -> Result<Vec<WebDavFile>, String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    
    let mut files = Vec::new();
    let mut buf = Vec::new();
    
    let mut current_href = String::new();
    let mut current_displayname = String::new();
    let mut current_size: i64 = 0;
    let mut current_last_modified = String::new();
    let mut is_dir = false;
    
    let mut in_response = false;
    let mut current_tag = String::new();
    
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                let name_bytes = e.local_name();
                let tag_name = String::from_utf8_lossy(name_bytes.as_ref()).to_lowercase();
                if tag_name == "response" {
                    in_response = true;
                    current_href.clear();
                    current_displayname.clear();
                    current_size = 0;
                    current_last_modified.clear();
                    is_dir = false;
                }
                if tag_name == "collection" && in_response {
                    is_dir = true;
                }
                current_tag = tag_name;
            }
            Ok(Event::Empty(ref e)) => {
                let name_bytes = e.local_name();
                let tag_name = String::from_utf8_lossy(name_bytes.as_ref()).to_lowercase();
                if tag_name == "collection" && in_response {
                    is_dir = true;
                }
            }
            Ok(Event::Text(e)) => {
                if in_response {
                    let text = e.unescape().unwrap_or_default().trim().to_string();
                    match current_tag.as_str() {
                        "href" => current_href = text,
                        "displayname" => current_displayname = text,
                        "getcontentlength" => current_size = text.parse().unwrap_or(0),
                        "getlastmodified" => current_last_modified = text,
                        _ => {}
                    }
                }
            }
            Ok(Event::End(ref e)) => {
                let name_bytes = e.local_name();
                let tag_name = String::from_utf8_lossy(name_bytes.as_ref()).to_lowercase();
                if tag_name == "response" {
                    in_response = false;
                    let name = if !current_displayname.is_empty() {
                        current_displayname.clone()
                    } else {
                        current_href.trim_end_matches('/').split('/').last().unwrap_or("").to_string()
                    };
                    if !name.is_empty() {
                        files.push(WebDavFile {
                            name,
                            path: current_href.clone(),
                            is_dir,
                            size: current_size,
                            last_modified: current_last_modified.clone(),
                        });
                    }
                }
                current_tag.clear();
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("XML error at position {}: {:?}", reader.buffer_position(), e)),
            _ => {}
        }
        buf.clear();
    }
    
    Ok(files)
}

use parking_lot::Mutex;

static WEBDAV_CLIENT: Lazy<Mutex<Option<WebDavClient>>> = Lazy::new(|| Mutex::new(None));

pub fn webdav_init(url: String, username: String, password: String) -> Result<(), String> {
    let client = WebDavClient::new(&url, &username, &password)?;
    let mut cache = WEBDAV_CLIENT.lock();
    *cache = Some(client);
    Ok(())
}

pub async fn webdav_test_connection() -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.test_connection().await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_mkdir(remote_path: String) -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.mkdir(&remote_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_upload_bytes(remote_path: String, bytes: Vec<u8>) -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.upload_bytes(&remote_path, bytes).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_upload_file(remote_path: String, local_path: String) -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.upload_file(&remote_path, &local_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_download_bytes(remote_path: String) -> Result<Vec<u8>, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.download_bytes(&remote_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_download_file(remote_path: String, local_path: String) -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.download_file(&remote_path, &local_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_list_files(remote_path: String) -> Result<Vec<WebDavFile>, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.list_files(&remote_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_remove(remote_path: String) -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.remove(&remote_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

pub async fn webdav_file_exists(remote_path: String) -> Result<bool, String> {
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    if let Some(c) = client {
        c.file_exists(&remote_path).await
    } else {
        Err("Client not initialized".to_string())
    }
}

