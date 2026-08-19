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

#[derive(Serialize, Deserialize)]
struct SyncBookPayload {
    uuid: String,
    title: String,
    author: String,
    #[serde(rename = "totalChapters")]
    total_chapters: i32,
    #[serde(rename = "coverExtension")]
    cover_extension: Option<String>,
    #[serde(rename = "dateAdded")]
    date_added: String,
    chapters: Vec<SyncChapterPayload>,
}

#[derive(Serialize, Deserialize)]
struct SyncChapterPayload {
    #[serde(rename = "chapterIndex")]
    chapter_index: i32,
    title: String,
    paragraphs: Vec<String>,
}

pub async fn export_and_upload_book(book_uuid: String) -> Result<bool, String> {
    use std::io::Write;
    use flate2::write::GzEncoder;
    use flate2::Compression;

    // 1. Get book and chapters from SQLite
    let book = crate::api::database::get_book_by_uuid(book_uuid.clone())?
        .ok_or_else(|| format!("Book not found: {}", book_uuid))?;
    
    let chapters = crate::api::database::get_chapters(book_uuid.clone())?;

    // 2. Build payload
    let date_added_iso = chrono::DateTime::from_timestamp_millis(book.date_added)
        .map(|dt| dt.to_rfc3339())
        .unwrap_or_else(|| chrono::Utc::now().to_rfc3339());

    let cover_extension = book.cover_path.as_ref().map(|p| {
        Path::new(p)
            .extension()
            .and_then(|ext| ext.to_str())
            .map(|ext| format!(".{}", ext))
            .unwrap_or_else(|| ".jpg".to_string())
    });

    let sync_chapters = chapters.into_iter().map(|c| SyncChapterPayload {
        chapter_index: c.chapter_index,
        title: c.title,
        paragraphs: c.paragraphs,
    }).collect();

    let payload = SyncBookPayload {
        uuid: book.uuid.clone(),
        title: book.title,
        author: book.author,
        total_chapters: book.total_chapters,
        cover_extension,
        date_added: date_added_iso,
        chapters: sync_chapters,
    };

    // 3. Serialize and Compress Gzip
    let json_bytes = serde_json::to_vec(&payload).map_err(|e| e.to_string())?;
    
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(&json_bytes).map_err(|e| e.to_string())?;
    let compressed_bytes = encoder.finish().map_err(|e| e.to_string())?;

    // 4. Upload book to WebDAV
    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    let c = client.ok_or_else(|| "WebDAV client not initialized".to_string())?;
    
    let remote_path = format!("/AudireReader/books/{}.json.gz", book_uuid);
    c.upload_bytes(&remote_path, compressed_bytes).await?;

    // 5. Upload cover if exists
    if let Some(ref cover_path_str) = book.cover_path {
        let cover_path = Path::new(cover_path_str);
        if cover_path.exists() {
            let ext = cover_path.extension().and_then(|s| s.to_str()).unwrap_or("jpg");
            let remote_cover = format!("/AudireReader/covers/{}.{}", book_uuid, ext);
            let _ = c.upload_file(&remote_cover, cover_path_str).await;
        }
    }

    Ok(true)
}

pub async fn download_and_import_book(book_uuid: String, documents_dir: String) -> Result<crate::api::models::Book, String> {
    use flate2::read::GzDecoder;
    use std::fs;

    let client = {
        let opt = WEBDAV_CLIENT.lock();
        opt.clone()
    };
    let c = client.ok_or_else(|| "WebDAV client not initialized".to_string())?;

    // 1. Download bytes from WebDAV
    let remote_path = format!("/AudireReader/books/{}.json.gz", book_uuid);
    let compressed_bytes = c.download_bytes(&remote_path).await?;

    // 2. Decompress Gzip
    let mut decoder = GzDecoder::new(&compressed_bytes[..]);
    let mut json_bytes = Vec::new();
    std::io::Read::read_to_end(&mut decoder, &mut json_bytes).map_err(|e| e.to_string())?;

    // 3. Deserialize JSON
    let payload: SyncBookPayload = serde_json::from_slice(&json_bytes).map_err(|e| e.to_string())?;

    // 4. Save Cover if exists on WebDAV
    let mut cover_path = None;
    if let Some(ref ext) = payload.cover_extension {
        let remote_cover = format!("/AudireReader/covers/{}{}", book_uuid, ext);
        if let Ok(exists) = c.file_exists(&remote_cover).await {
            if exists {
                let local_cover_dir = Path::new(&documents_dir).join("covers");
                if !local_cover_dir.exists() {
                    let _ = fs::create_dir_all(&local_cover_dir);
                }
                let local_cover_path = local_cover_dir.join(format!("{}{}", book_uuid, ext));
                let local_cover_str = local_cover_path.to_string_lossy().to_string();
                if c.download_file(&remote_cover, &local_cover_str).await.is_ok() {
                    cover_path = Some(local_cover_str);
                }
            }
        }
    }

    // 5. Convert to models & Insert into SQLite
    let date_added_millis = chrono::DateTime::parse_from_rfc3339(&payload.date_added)
        .map(|dt| dt.timestamp_millis())
        .unwrap_or_else(|_| chrono::Utc::now().timestamp_millis());

    let book = crate::api::models::Book {
        id: None,
        uuid: payload.uuid.clone(),
        title: payload.title,
        author: payload.author,
        cover_path,
        total_chapters: payload.total_chapters,
        date_added: date_added_millis,
        status: "unread".to_string(),
        tags: vec![],
    };

    let chapters: Vec<crate::api::models::Chapter> = payload.chapters.into_iter().map(|c| crate::api::models::Chapter {
        id: None,
        book_uuid: payload.uuid.clone(),
        chapter_index: c.chapter_index,
        title: c.title,
        paragraphs: c.paragraphs,
    }).collect();

    // 6. DB operations
    crate::api::database::insert_book(book.clone())?;
    crate::api::database::insert_chapters(chapters)?;

    if let Ok(conn) = crate::api::database::get_conn() {
        let _ = conn.execute_batch("PRAGMA shrink_memory;");
    }

    Ok(book)
}

