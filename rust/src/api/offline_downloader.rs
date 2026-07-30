use crate::api::database::get_chapters;
use crate::api::tts::{synthesize_edge_tts, synthesize_openai_tts};
use chrono::Local;
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::fs::OpenOptions;
use tokio::io::AsyncWriteExt;
use tokio::sync::Semaphore;
use tokio::time::sleep;

static IS_PAUSED: AtomicBool = AtomicBool::new(false);
static IS_CANCELED: AtomicBool = AtomicBool::new(false);
static IS_RUNNING: AtomicBool = AtomicBool::new(false);

static ACTIVE_CHAPTERS: Lazy<parking_lot::Mutex<HashSet<i32>>> =
    Lazy::new(|| parking_lot::Mutex::new(HashSet::new()));

static FAILED_CHAPTERS: Lazy<parking_lot::Mutex<HashSet<i32>>> =
    Lazy::new(|| parking_lot::Mutex::new(HashSet::new()));

static RECENT_LOGS: Lazy<parking_lot::Mutex<VecDeque<String>>> =
    Lazy::new(|| parking_lot::Mutex::new(VecDeque::with_capacity(20)));

fn push_log(msg: String) {
    let mut logs = RECENT_LOGS.lock();
    if logs.len() >= 20 {
        logs.pop_front();
    }
    logs.push_back(msg);
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ChapterStorageSize {
    pub chapter_index: i32,
    pub bytes: u64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DownloadStatusInfo {
    pub is_running: bool,
    pub is_paused: bool,
    pub total_chapters: usize,
    pub completed_chapters: usize,
    pub total_bytes: u64,
    pub active_chapter_indices: Vec<i32>,
    pub downloaded_chapter_indices: Vec<i32>,
    pub failed_chapter_indices: Vec<i32>,
    pub chapter_sizes: Vec<ChapterStorageSize>,
    pub recent_logs: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BookStorageInfo {
    pub total_bytes: u64,
    pub chapter_indices: Vec<i32>,
    pub chapter_sizes: Vec<ChapterStorageSize>,
}

pub fn pause_offline_download() {
    IS_PAUSED.store(true, Ordering::Relaxed);
    push_log("Download paused by user".to_string());
}

pub fn resume_offline_download() {
    IS_PAUSED.store(false, Ordering::Relaxed);
    push_log("Download resumed by user".to_string());
}

pub fn cancel_offline_download() {
    IS_CANCELED.store(true, Ordering::Relaxed);
    IS_PAUSED.store(false, Ordering::Relaxed);
    ACTIVE_CHAPTERS.lock().clear();
    push_log("Download canceled by user".to_string());
}

pub fn is_download_running() -> bool {
    IS_RUNNING.load(Ordering::Relaxed)
}

/// Scan disk in < 2ms to verify real audio files, total bytes, and size per chapter
pub fn get_book_storage_info(base_dir: String, book_uuid: String) -> BookStorageInfo {
    let mut total_bytes: u64 = 0;
    let mut chapter_indices = Vec::new();
    let mut chapter_sizes = Vec::new();

    let book_dir = Path::new(&base_dir).join("tts_offline").join(&book_uuid);
    if !book_dir.exists() {
        return BookStorageInfo {
            total_bytes: 0,
            chapter_indices,
            chapter_sizes,
        };
    }

    if let Ok(entries) = fs::read_dir(book_dir) {
        for entry in entries.flatten() {
            if entry.path().is_dir() {
                if let Some(folder_name) = entry.file_name().to_str() {
                    if let Ok(ch_idx) = folder_name.parse::<i32>() {
                        let mut ch_bytes: u64 = 0;
                        if let Ok(files) = fs::read_dir(entry.path()) {
                            for f in files.flatten() {
                                let path = f.path();
                                if path.extension().map_or(false, |ext| ext == "wav" || ext == "mp3") {
                                    if let Ok(meta) = f.metadata() {
                                        let len = meta.len();
                                        if len > 0 {
                                            ch_bytes += len;
                                        }
                                    }
                                }
                            }
                        }
                        // Only add chapter if it has real valid audio bytes > 0
                        if ch_bytes > 0 {
                            total_bytes += ch_bytes;
                            chapter_indices.push(ch_idx);
                            chapter_sizes.push(ChapterStorageSize {
                                chapter_index: ch_idx,
                                bytes: ch_bytes,
                            });
                        }
                    }
                }
            }
        }
    }

    BookStorageInfo {
        total_bytes,
        chapter_indices,
        chapter_sizes,
    }
}

pub fn get_download_status(base_dir: String, book_uuid: String) -> DownloadStatusInfo {
    let is_running = IS_RUNNING.load(Ordering::Relaxed);
    let is_paused = IS_PAUSED.load(Ordering::Relaxed);

    let active_chapter_indices: Vec<i32> = ACTIVE_CHAPTERS.lock().iter().copied().collect();
    let failed_chapter_indices: Vec<i32> = FAILED_CHAPTERS.lock().iter().copied().collect();
    let storage_info = get_book_storage_info(base_dir, book_uuid);

    let recent_logs: Vec<String> = {
        let mut logs = RECENT_LOGS.lock();
        let list = logs.iter().cloned().collect();
        logs.clear();
        list
    };

    DownloadStatusInfo {
        is_running,
        is_paused,
        total_chapters: 0,
        completed_chapters: storage_info.chapter_indices.len(),
        total_bytes: storage_info.total_bytes,
        active_chapter_indices,
        downloaded_chapter_indices: storage_info.chapter_indices,
        failed_chapter_indices,
        chapter_sizes: storage_info.chapter_sizes,
        recent_logs,
    }
}

async fn log_to_file(base_dir: &str, message: &str) {
    push_log(message.to_string());

    let log_dir = Path::new(base_dir).join("logs");
    if !log_dir.exists() {
        let _ = fs::create_dir_all(&log_dir);
    }
    let log_file_path = log_dir.join("tts_downloader.log");
    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
    let line = format!("[{}] {}\n", timestamp, message);

    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_file_path)
        .await
    {
        let _ = file.write_all(line.as_bytes()).await;
    }
}

struct TaskItem {
    chapter_index: i32,
    paragraph_index: usize,
    text: String,
}

pub async fn start_offline_download_job(
    book_uuid: String,
    chapter_indices: Vec<i32>,
    concurrency: usize,
    base_dir: String,
    provider: String,
    voice_name: String,
    speech_rate: f64,
    openai_api_key: Option<String>,
) -> Result<(), String> {
    if IS_RUNNING.swap(true, Ordering::Relaxed) {
        return Err("Download job already running".to_string());
    }

    IS_PAUSED.store(false, Ordering::Relaxed);
    IS_CANCELED.store(false, Ordering::Relaxed);
    ACTIVE_CHAPTERS.lock().clear();
    FAILED_CHAPTERS.lock().clear();

    tokio::spawn(async move {
        let all_chapters = match get_chapters(book_uuid.clone()) {
            Ok(c) => c,
            Err(e) => {
                IS_RUNNING.store(false, Ordering::Relaxed);
                log_to_file(&base_dir, &format!("Error reading chapters: {}", e)).await;
                return;
            }
        };

        let target_chapters: Vec<_> = all_chapters
            .into_iter()
            .filter(|c| chapter_indices.contains(&c.chapter_index))
            .collect();

        let total_chapters = target_chapters.len();
        log_to_file(
            &base_dir,
            &format!("Started download job for book {}. Total chapters: {}", book_uuid, total_chapters),
        ).await;

        if total_chapters == 0 {
            IS_RUNNING.store(false, Ordering::Relaxed);
            return;
        }

        let mut tasks = Vec::new();
        let mut chapter_total_p = std::collections::HashMap::new();

        for ch in &target_chapters {
            let ch_dir = Path::new(&base_dir)
                .join("tts_offline")
                .join(&book_uuid)
                .join(ch.chapter_index.to_string());
            if !ch_dir.exists() {
                let _ = fs::create_dir_all(&ch_dir);
            }

            let paragraphs = &ch.paragraphs;
            chapter_total_p.insert(ch.chapter_index, paragraphs.len());

            for (p_idx, text) in paragraphs.iter().enumerate() {
                let audio_file = ch_dir.join(format!("p_{}.wav", p_idx));
                if !audio_file.exists() || audio_file.metadata().map(|m| m.len()).unwrap_or(0) == 0 {
                    tasks.push(TaskItem {
                        chapter_index: ch.chapter_index,
                        paragraph_index: p_idx,
                        text: text.clone(),
                    });
                }
            }
        }

        let concurrency_limit = concurrency.clamp(1, 100);
        let semaphore = Arc::new(Semaphore::new(concurrency_limit));
        let mut worker_handles = Vec::new();

        let completed_paragraphs = Arc::new(parking_lot::Mutex::new(std::collections::HashMap::<i32, usize>::new()));
        let completed_chapters_count = Arc::new(parking_lot::Mutex::new(0usize));

        let completed_c_clone = completed_chapters_count.clone();
        let base_dir_for_log = base_dir.clone();
        let reporter_handle = tokio::spawn(async move {
            let mut last_logged_c = 0;
            while IS_RUNNING.load(Ordering::Relaxed) && !IS_CANCELED.load(Ordering::Relaxed) {
                sleep(Duration::from_millis(500)).await;
                let comp_c = *completed_c_clone.lock();

                if comp_c != last_logged_c {
                    last_logged_c = comp_c;
                    log_to_file(
                        &base_dir_for_log,
                        &format!("Progress: {}/{} chapters completed", comp_c, total_chapters),
                    ).await;
                }
            }
        });

        for task in tasks {
            if IS_CANCELED.load(Ordering::Relaxed) {
                break;
            }

            while IS_PAUSED.load(Ordering::Relaxed) {
                if IS_CANCELED.load(Ordering::Relaxed) {
                    break;
                }
                sleep(Duration::from_millis(200)).await;
            }

            let permit = semaphore.clone().acquire_owned().await.unwrap();
            let book_uuid_inner = book_uuid.clone();
            let base_dir_inner = base_dir.clone();
            let provider_inner = provider.clone();
            let voice_inner = voice_name.clone();
            let api_key_inner = openai_api_key.clone();
            let completed_p_inner = completed_paragraphs.clone();
            let completed_c_inner = completed_chapters_count.clone();
            let total_p_count = *chapter_total_p.get(&task.chapter_index).unwrap_or(&1);

            ACTIVE_CHAPTERS.lock().insert(task.chapter_index);

            worker_handles.push(tokio::spawn(async move {
                let _permit = permit;
                let raw_text = task.text.trim();

                let mut success = true;
                let mut retries = 0;
                let mut last_err = String::from("Unknown error");

                if !raw_text.is_empty() {
                    let audio_path = Path::new(&base_dir_inner)
                        .join("tts_offline")
                        .join(&book_uuid_inner)
                        .join(task.chapter_index.to_string())
                        .join(format!("p_{}.wav", task.paragraph_index));

                    success = false;

                    while !success && retries < 20 && !IS_CANCELED.load(Ordering::Relaxed) {
                        let res = if provider_inner == "microsoft_edge" {
                            synthesize_edge_tts(raw_text.to_string(), voice_inner.clone(), speech_rate).await
                        } else if provider_inner == "openai" {
                            synthesize_openai_tts(
                                raw_text.to_string(),
                                voice_inner.clone(),
                                api_key_inner.clone().unwrap_or_default(),
                                speech_rate,
                            ).await
                        } else {
                            Err("Unsupported provider".to_string())
                        };

                        match res {
                            Ok(bytes) => {
                                if tokio::fs::write(&audio_path, &bytes).await.is_ok() {
                                    success = true;
                                } else {
                                    last_err = "Disk write failed".to_string();
                                    retries += 1;
                                }
                            }
                            Err(e) => {
                                last_err = e.clone();
                                retries += 1;
                                push_log(format!(
                                    "[Retry {}/20] Chapter {} p_{}: {}",
                                    retries, task.chapter_index + 1, task.paragraph_index, e
                                ));
                                sleep(Duration::from_secs(1)).await;
                            }
                        }
                    }
                }

                if success {
                    let mut p_map = completed_p_inner.lock();
                    let count = p_map.entry(task.chapter_index).or_insert(0);
                    *count += 1;

                    if *count >= total_p_count {
                        let mut c_count = completed_c_inner.lock();
                        *c_count += 1;
                        ACTIVE_CHAPTERS.lock().remove(&task.chapter_index);
                    }
                } else {
                    FAILED_CHAPTERS.lock().insert(task.chapter_index);
                    ACTIVE_CHAPTERS.lock().remove(&task.chapter_index);
                    let err_msg = format!(
                        "Chapter {} p_{} failed after 20 retries: {}",
                        task.chapter_index + 1, task.paragraph_index, last_err
                    );
                    log_to_file(&base_dir_inner, &err_msg).await;
                }
            }));
        }

        for handle in worker_handles {
            let _ = handle.await;
        }

        IS_RUNNING.store(false, Ordering::Relaxed);
        ACTIVE_CHAPTERS.lock().clear();
        let _ = reporter_handle.await;

        log_to_file(
            &base_dir,
            &format!("Download job completed for book {}", book_uuid),
        ).await;
    });

    Ok(())
}
