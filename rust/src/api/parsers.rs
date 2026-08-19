use crate::api::models::{Book, Chapter};
use regex::Regex;
use std::path::Path;
use std::fs::{self, File};
use std::io::Read;
use chrono::Utc;
use flutter_rust_bridge::frb;
use quick_xml::Reader;
use quick_xml::events::Event;
use zip::ZipArchive;

pub struct ParsedBookData {
    pub book: Book,
    pub chapters: Vec<Chapter>,
}

pub fn import_book_file(file_path: String, documents_dir_path: String) -> Result<Book, String> {
    let parsed = match Path::new(&file_path).extension().and_then(|s| s.to_str()).map(|s| s.to_lowercase()).as_deref() {
        Some("epub") => parse_epub_file(file_path, documents_dir_path)?,
        Some("txt") => parse_txt_file(file_path)?,
        Some("pdf") => parse_pdf_file(file_path)?,
        Some("docx") => parse_docx_file(file_path)?,
        _ => return Err("Unsupported file format".to_string()),
    };

    crate::api::database::insert_book(parsed.book.clone())?;
    crate::api::database::insert_chapters(parsed.chapters)?;

    if let Ok(conn) = crate::api::database::get_conn() {
        let _ = conn.execute_batch("PRAGMA shrink_memory;");
    }

    Ok(parsed.book)
}

#[frb(sync)]
pub fn parse_txt_file(file_path: String) -> Result<ParsedBookData, String> {
    let mut file = File::open(&file_path).map_err(|e| e.to_string())?;
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer).map_err(|e| e.to_string())?;
    let raw_text = String::from_utf8_lossy(&buffer).to_string();

    let path = Path::new(&file_path);
    let filename = path.file_stem().unwrap_or_default().to_string_lossy();
    let title = filename.replace('_', " ").trim().to_string();
    let author = "Unknown Author".to_string();
    let uuid = format!("{}_{}", Utc::now().timestamp_millis(), title.chars().map(|c| c as u32).sum::<u32>());

    let chapters = segment_text_into_chapters(&raw_text, &uuid);

    let book = Book {
        id: None,
        uuid: uuid.clone(),
        title,
        author,
        cover_path: None,
        total_chapters: chapters.len() as i32,
        date_added: Utc::now().timestamp_millis(),
        status: "reading".to_string(),
        tags: vec![],
    };

    Ok(ParsedBookData { book, chapters })
}

#[frb(sync)]
pub fn parse_pdf_file(file_path: String) -> Result<ParsedBookData, String> {
    let raw_text = pdf_extract::extract_text(&file_path).map_err(|e| format!("PDF parse error: {}", e))?;
    
    let path = Path::new(&file_path);
    let filename = path.file_stem().unwrap_or_default().to_string_lossy();
    let title = filename.replace('_', " ").trim().to_string();
    let author = "Unknown Author".to_string();
    let uuid = format!("{}_{}", Utc::now().timestamp_millis(), title.chars().map(|c| c as u32).sum::<u32>());

    let chapters = segment_text_into_chapters(&raw_text, &uuid);

    let book = Book {
        id: None,
        uuid: uuid.clone(),
        title,
        author,
        cover_path: None,
        total_chapters: chapters.len() as i32,
        date_added: Utc::now().timestamp_millis(),
        status: "reading".to_string(),
        tags: vec![],
    };

    Ok(ParsedBookData { book, chapters })
}

#[frb(sync)]
pub fn parse_docx_file(file_path: String) -> Result<ParsedBookData, String> {
    let file = File::open(&file_path).map_err(|e| e.to_string())?;
    let mut archive = ZipArchive::new(file).map_err(|e| format!("Failed to open DOCX zip: {}", e))?;
    
    let mut document_xml = archive.by_name("word/document.xml").map_err(|e| format!("word/document.xml not found: {}", e))?;
    let mut xml_content = String::new();
    document_xml.read_to_string(&mut xml_content).map_err(|e| e.to_string())?;

    let mut reader = Reader::from_str(&xml_content);
    // Removed trim_text config, we'll trim manually if needed
    let mut raw_text = String::new();
    let mut buf = Vec::new();

    let mut in_text = false;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) if e.name().as_ref() == b"w:t" => {
                in_text = true;
            },
            Ok(Event::End(ref e)) if e.name().as_ref() == b"w:t" => {
                in_text = false;
            },
            Ok(Event::Text(e)) => {
                if in_text {
                    let text = e.unescape().unwrap_or_default();
                    raw_text.push_str(&text);
                }
            },
            Ok(Event::Start(ref e)) if e.name().as_ref() == b"w:p" => {
                raw_text.push('\n');
            },
            Ok(Event::Eof) => break,
            Err(e) => return Err(e.to_string()),
            _ => (),
        }
        buf.clear();
    }

    let path = Path::new(&file_path);
    let filename = path.file_stem().unwrap_or_default().to_string_lossy();
    let title = filename.replace('_', " ").trim().to_string();
    let author = "Unknown Author".to_string();
    let uuid = format!("{}_{}", Utc::now().timestamp_millis(), title.chars().map(|c| c as u32).sum::<u32>());

    let chapters = segment_text_into_chapters(&raw_text, &uuid);

    let book = Book {
        id: None,
        uuid: uuid.clone(),
        title,
        author,
        cover_path: None,
        total_chapters: chapters.len() as i32,
        date_added: Utc::now().timestamp_millis(),
        status: "reading".to_string(),
        tags: vec![],
    };

    Ok(ParsedBookData { book, chapters })
}

#[frb(sync)]
pub fn parse_epub_file(file_path: String, documents_dir_path: String) -> Result<ParsedBookData, String> {
    let mut doc = epub::doc::EpubDoc::new(&file_path).map_err(|e| format!("EPUB load error: {}", e))?;
    
    // In epub 2.x, mdata returns Option<Vec<String>> or Option<MetadataItem> depending on crate.
    let title = doc.mdata("title").map(|m| m.value.clone()).unwrap_or_else(|| "Unknown Title".to_string());
    let author = doc.mdata("creator").map(|m| m.value.clone()).unwrap_or_else(|| "Unknown Author".to_string());
    let uuid = format!("{}_{}", Utc::now().timestamp_millis(), title.chars().map(|c| c as u32).sum::<u32>());

    let mut cover_path = None;

    // Method 1: Standard doc.get_cover()
    if let Some((cover_bytes, _mime)) = doc.get_cover() {
        cover_path = save_cover_image(&cover_bytes, &documents_dir_path, &uuid);
    }

    // Method 2: Scan doc.resources with smart scoring
    if cover_path.is_none() {
        let mut best_entry: Option<(String, std::path::PathBuf)> = None;
        let mut best_score = 0;
        for (key, res_item) in &doc.resources {
            let k_lower = key.to_lowercase();
            let p_lower = res_item.path.to_string_lossy().to_lowercase();
            let m_lower = res_item.mime.to_lowercase();
            let is_image = m_lower.starts_with("image/")
                || k_lower.ends_with(".jpg") || k_lower.ends_with(".jpeg") || k_lower.ends_with(".png") || k_lower.ends_with(".webp") || k_lower.ends_with(".gif") || k_lower.ends_with(".jfif")
                || p_lower.ends_with(".jpg") || p_lower.ends_with(".jpeg") || p_lower.ends_with(".png") || p_lower.ends_with(".webp") || p_lower.ends_with(".gif") || p_lower.ends_with(".jfif");

            if is_image {
                let score = if k_lower.contains("cover") || p_lower.contains("cover") {
                    100
                } else if k_lower.contains("bia") || p_lower.contains("bia") {
                    90
                } else if k_lower.contains("thumb") || p_lower.contains("thumb") || k_lower.contains("front") || p_lower.contains("front") {
                    80
                } else if k_lower.contains("image") || p_lower.contains("image") || k_lower.contains("img") || p_lower.contains("img") || k_lower.contains("avatar") {
                    50
                } else {
                    20
                };
                if score > best_score {
                    best_score = score;
                    best_entry = Some((key.clone(), res_item.path.clone()));
                }
            }
        }

        if let Some((key, path)) = best_entry {
            let bytes_opt = doc.get_resource(&key)
                .map(|(b, _)| b)
                .or_else(|| doc.get_resource_by_path(&path))
                .or_else(|| {
                    let file_name = path.file_name()?;
                    doc.get_resource_by_path(Path::new(file_name))
                });
            if let Some(bytes) = bytes_opt {
                cover_path = save_cover_image(&bytes, &documents_dir_path, &uuid);
            }
        }
    }

    // Method 3: Direct zip archive inspection (Super-fallback, matches Dart AllFiles)
    if cover_path.is_none() {
        if let Ok(file) = File::open(&file_path) {
            if let Ok(mut archive) = zip::ZipArchive::new(file) {
                let mut best_index = None;
                let mut best_score = 0;

                for i in 0..archive.len() {
                    if let Ok(file_in_zip) = archive.by_index(i) {
                        let name_lower = file_in_zip.name().to_lowercase();
                        let is_image = name_lower.ends_with(".jpg")
                            || name_lower.ends_with(".jpeg")
                            || name_lower.ends_with(".png")
                            || name_lower.ends_with(".webp")
                            || name_lower.ends_with(".gif")
                            || name_lower.ends_with(".jfif");
                        if is_image {
                            let score = if name_lower.contains("cover") {
                                100
                            } else if name_lower.contains("bia") {
                                90
                            } else if name_lower.contains("thumb") || name_lower.contains("front") {
                                80
                            } else if name_lower.contains("image") || name_lower.contains("img") || name_lower.contains("avatar") {
                                50
                            } else {
                                20
                            };
                            if score > best_score {
                                best_score = score;
                                best_index = Some(i);
                            }
                        }
                    }
                }

                if let Some(i) = best_index {
                    if let Ok(mut file_in_zip) = archive.by_index(i) {
                        let mut bytes = Vec::new();
                        if file_in_zip.read_to_end(&mut bytes).is_ok() && !bytes.is_empty() {
                            cover_path = save_cover_image(&bytes, &documents_dir_path, &uuid);
                        }
                    }
                }
            }
        }
    }

    let mut chapters = Vec::new();

    fn flatten_nav_points(nav_points: &[epub::doc::NavPoint], result: &mut Vec<(String, String)>) {
        for np in nav_points {
            let label = np.label.trim().to_string();
            let path_str = np.content.to_string_lossy().to_string();
            let clean_path = path_str.split('#').next().unwrap_or("").to_string();
            if !label.is_empty() && !clean_path.is_empty() {
                result.push((label, clean_path));
            }
            flatten_nav_points(&np.children, result);
        }
    }

    let mut toc_entries = Vec::new();
    flatten_nav_points(&doc.toc, &mut toc_entries);

    // Attempt 1: Extract chapters from TOC if TOC exists
    if !toc_entries.is_empty() {
        let mut chapter_index = 0;
        for (label, path_str) in &toc_entries {
            let clean_path = Path::new(path_str);
            let content_bytes = doc.get_resource_by_path(clean_path)
                .or_else(|| {
                    let file_name = clean_path.file_name()?;
                    doc.get_resource_by_path(Path::new(file_name))
                });

            if let Some(bytes) = content_bytes {
                let html = String::from_utf8_lossy(&bytes);
                let paragraphs = parse_html_to_paragraphs(&html);
                if !paragraphs.is_empty() {
                    chapters.push(Chapter {
                        id: None,
                        book_uuid: uuid.clone(),
                        chapter_index: chapter_index as i32,
                        title: label.clone(),
                        paragraphs,
                    });
                    chapter_index += 1;
                }
            }
        }
    }

    // Attempt 2: Fallback to reading all spine pages if TOC was empty or yielded no chapters
    if chapters.is_empty() {
        let num_pages = doc.get_num_chapters();
        let mut chapter_index = 0;
        for i in 0..num_pages {
            let _ = doc.set_current_chapter(i);
            if let Some((content, _mime)) = doc.get_current_str() {
                let paragraphs = parse_html_to_paragraphs(&content);
                if !paragraphs.is_empty() {
                    let ch_title = extract_title_from_html(&content)
                        .unwrap_or_else(|| format!("Chapter {}", chapter_index + 1));

                    chapters.push(Chapter {
                        id: None,
                        book_uuid: uuid.clone(),
                        chapter_index: chapter_index as i32,
                        title: ch_title,
                        paragraphs,
                    });
                    chapter_index += 1;
                }
            }
        }
    }

    // Sort chapters naturally if possible
    if !chapters.is_empty() {
        chapters.sort_by(|a, b| natural_sort_compare(&a.title, &b.title));
        for (i, ch) in chapters.iter_mut().enumerate() {
            ch.chapter_index = i as i32;
        }
    }

    let book = Book {
        id: None,
        uuid: uuid.clone(),
        title,
        author,
        cover_path,
        total_chapters: chapters.len() as i32,
        date_added: Utc::now().timestamp_millis(),
        status: "unread".to_string(),
        tags: vec![],
    };

    Ok(ParsedBookData { book, chapters })
}

fn save_cover_image(cover_bytes: &[u8], documents_dir_path: &str, uuid: &str) -> Option<String> {
    if cover_bytes.is_empty() {
        return None;
    }
    let covers_dir = Path::new(documents_dir_path).join("covers");
    if !covers_dir.exists() {
        let _ = fs::create_dir_all(&covers_dir);
    }
    let cover_file_path = covers_dir.join(format!("{}.jpg", uuid));

    if let Ok(img) = image::load_from_memory(cover_bytes) {
        let thumbnail = img.thumbnail(400, 600);
        if let Ok(mut f) = File::create(&cover_file_path) {
            if thumbnail.write_to(&mut f, image::ImageFormat::Jpeg).is_ok() {
                return Some(cover_file_path.to_string_lossy().to_string());
            }
        }
    }

    // Fallback raw save if decoding fails
    if let Ok(mut f) = File::create(&cover_file_path) {
        use std::io::Write;
        if f.write_all(cover_bytes).is_ok() {
            return Some(cover_file_path.to_string_lossy().to_string());
        }
    }
    None
}

fn natural_sort_compare(a: &str, b: &str) -> std::cmp::Ordering {
    let re = Regex::new(r"(\d+)|([^\d]+)").unwrap();
    let parts_a: Vec<&str> = re.find_iter(a).map(|m| m.as_str()).collect();
    let parts_b: Vec<&str> = re.find_iter(b).map(|m| m.as_str()).collect();

    let min_len = parts_a.len().min(parts_b.len());
    for i in 0..min_len {
        let part_a = parts_a[i];
        let part_b = parts_b[i];

        if let (Ok(num_a), Ok(num_b)) = (part_a.parse::<u64>(), part_b.parse::<u64>()) {
            match num_a.cmp(&num_b) {
                std::cmp::Ordering::Equal => {},
                ord => return ord,
            }
        } else {
            match part_a.to_lowercase().cmp(&part_b.to_lowercase()) {
                std::cmp::Ordering::Equal => {},
                ord => return ord,
            }
        }
    }
    parts_a.len().cmp(&parts_b.len())
}

fn extract_title_from_html(html_content: &str) -> Option<String> {
    let fragment = scraper::Html::parse_document(html_content);
    if let Ok(sel) = scraper::Selector::parse("h1, h2, h3, title") {
        for el in fragment.select(&sel) {
            let txt = el.text().collect::<Vec<_>>().join(" ").trim().to_string();
            if !txt.is_empty() && txt.len() < 120 {
                return Some(txt);
            }
        }
    }
    None
}

fn parse_html_to_paragraphs(html_content: &str) -> Vec<String> {
    if html_content.is_empty() {
        return vec![];
    }

    let br_re = Regex::new(r"(?i)<br\s*/?>").unwrap();
    let p_close_re = Regex::new(r"(?i)</p>").unwrap();
    let div_close_re = Regex::new(r"(?i)</div>").unwrap();
    let span_close_re = Regex::new(r"(?i)</span>").unwrap();

    let formatted_html = br_re.replace_all(html_content, "\n");
    let formatted_html = p_close_re.replace_all(&formatted_html, "</p>\n");
    let formatted_html = div_close_re.replace_all(&formatted_html, "</div>\n");
    let formatted_html = span_close_re.replace_all(&formatted_html, "</span>\n");

    let fragment = scraper::Html::parse_document(&formatted_html);
    let selector = scraper::Selector::parse("p, h1, h2, h3, h4, h5, h6, li").unwrap();
    let mut clean_paras = Vec::new();
    let space_re = Regex::new(r"\s+").unwrap();

    for el in fragment.select(&selector) {
        let txt: String = el.text().collect::<Vec<_>>().join(" ");
        let cleaned = txt.trim().replace('\n', " ");
        let cleaned = space_re.replace_all(&cleaned, " ").to_string();
        if cleaned.len() > 2 {
            if clean_paras.is_empty() || clean_paras.last().unwrap() != &cleaned {
                clean_paras.push(cleaned);
            }
        }
    }

    let body_selector = scraper::Selector::parse("body").unwrap();
    if let Some(body) = fragment.select(&body_selector).next() {
        let raw_text = body.text().collect::<Vec<_>>().join("");
        let raw_text_trimmed = raw_text.trim();
        let total_clean_len: usize = clean_paras.iter().map(|p| p.len()).sum();

        let is_missing_significant_content = (raw_text_trimmed.len() > total_clean_len + 40)
            && (total_clean_len < (raw_text_trimmed.len() as f64 * 0.7) as usize);

        if clean_paras.is_empty() || is_missing_significant_content {
            let mut fallback_paras = Vec::new();
            for line in raw_text_trimmed.split('\n') {
                let trimmed = line.trim().replace('\n', " ");
                let cleaned = space_re.replace_all(&trimmed, " ").to_string();
                if cleaned.len() > 2 {
                    if fallback_paras.is_empty() || fallback_paras.last().unwrap() != &cleaned {
                        fallback_paras.push(cleaned);
                    }
                }
            }
            if !fallback_paras.is_empty() {
                return fallback_paras;
            }
        }
    }

    clean_paras
}

fn sanitize_text(text: &str) -> String {
    let mut s = text.to_string();
    s = s.replace('\u{200B}', "")
         .replace('\u{200C}', "")
         .replace('\u{200D}', "")
         .replace('\u{FEFF}', "");
    
    // Fix X capital letter issue (e.g. sXách -> sách)
    let re_x = Regex::new(r"([a-zàáảãạâầấẩẫậăằắẳẵặeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ])X([a-zàáảãạâầấẩẫậăằắẳẵặeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ])").unwrap();
    s = re_x.replace_all(&s, "$1$2").to_string();

    s = s.replace("VV", "W");
    s = s.replace("vv", "w");
    s = s.replace("tinL.", "tin.");
    s = s.replace("tinL ", "tin. ");

    s
}

fn clean_and_merge_lines(raw_lines: Vec<&str>) -> Vec<String> {
    let mut merged: Vec<String> = Vec::new();
    
    // For drop cap checks
    let drop_cap_re = Regex::new(r"^[A-ZÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶEÈÉẺẼẸÊỀẾỂỄỆIÌÍỈĨỊOÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢUÙÚỦŨỤƯỪỨỬỮỰYỲÝỶỸỴĐ]$").unwrap();
    let lower_start_re = Regex::new(r"^[a-zàáảãạâầấẩẫậăằắẳẵặeèéẻẽẹêềếểễệiìíỉĩịoòóỏõọôồốổỗộơờớởỡợuùúủũụưừứửữựyỳýỷỹỵđ]").unwrap();
    let punct_end_re = Regex::new(r#"[.!?:;"'\)\]]$"#).unwrap();

    for line in raw_lines {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        if merged.is_empty() {
            merged.push(trimmed.to_string());
            continue;
        }

        let last_idx = merged.len() - 1;
        let last = &merged[last_idx];

        if last.len() == 1 && drop_cap_re.is_match(last) {
            merged[last_idx] = format!("{}{}", last, trimmed);
            continue;
        }

        if last.ends_with('-') && !last.ends_with(" - ") {
            let without_dash = &last[0..last.len()-1];
            merged[last_idx] = format!("{}{}", without_dash, trimmed);
            continue;
        }

        let starts_with_lower = lower_start_re.is_match(trimmed);
        let ends_with_punct = punct_end_re.is_match(last);
        let is_long = last.len() > 30;

        if starts_with_lower || (!ends_with_punct && is_long) {
            let updated = format!("{} {}", last, trimmed);
            merged[last_idx] = updated;
        } else {
            merged.push(trimmed.to_string());
        }
    }

    merged
}

fn segment_text_into_chapters(raw_text: &str, book_uuid: &str) -> Vec<Chapter> {
    if raw_text.trim().is_empty() {
        return vec![];
    }

    let sanitized = sanitize_text(raw_text);
    let lines: Vec<&str> = sanitized.lines().collect();
    let merged_lines = clean_and_merge_lines(lines);

    let mut chapters = Vec::new();
    let chapter_re = Regex::new(r"(?i)^\s*(chương|chapter|tập|quyển|phần|tiết|q|ch|lớp)\s+([0-9\-\.\s]+|[ivxlcdm\s]+|[一二三四五六七八九十百千万\s]+)(\s*[:\-\._]|\s+|$)").unwrap();

    let mut current_paragraphs = Vec::new();
    let mut current_chapter_title = String::new();
    let mut chapter_index = 0;

    for line in merged_lines {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        if chapter_re.is_match(trimmed) && trimmed.len() < 150 {
            if !current_paragraphs.is_empty() || !current_chapter_title.is_empty() {
                let title = if current_chapter_title.is_empty() {
                    format!("Chương {}", chapter_index)
                } else {
                    current_chapter_title.clone()
                };

                chapters.push(Chapter {
                    id: None,
                    book_uuid: book_uuid.to_string(),
                    chapter_index,
                    title,
                    paragraphs: current_paragraphs.clone(),
                });
                chapter_index += 1;
                current_paragraphs.clear();
            }
            current_chapter_title = trimmed.to_string();
        } else {
            current_paragraphs.push(trimmed.to_string());
        }
    }

    if !current_paragraphs.is_empty() || !current_chapter_title.is_empty() {
        let title = if current_chapter_title.is_empty() {
            format!("Chương {}", chapter_index)
        } else {
            current_chapter_title
        };
        chapters.push(Chapter {
            id: None,
            book_uuid: book_uuid.to_string(),
            chapter_index,
            title,
            paragraphs: current_paragraphs,
        });
    }

    let needs_fallback = chapters.is_empty() || (chapters.len() == 1 && chapters[0].paragraphs.len() > 300);

    if needs_fallback {
        return segment_fallback(raw_text, book_uuid);
    }

    chapters
}

fn segment_fallback(raw_text: &str, book_uuid: &str) -> Vec<Chapter> {
    let lines: Vec<&str> = raw_text.lines().map(|l| l.trim()).filter(|l| !l.is_empty()).collect();
    let mut chapters = Vec::new();
    let mut chunk = Vec::new();
    let mut word_count = 0;
    let mut chapter_index = 0;

    const MAX_WORDS: usize = 2000;

    for line in lines {
        chunk.push(line.to_string());
        let words = line.split_whitespace().count();
        word_count += words;

        if word_count >= MAX_WORDS {
            chapters.push(Chapter {
                id: None,
                book_uuid: book_uuid.to_string(),
                chapter_index,
                title: format!("Phần {}", chapter_index + 1),
                paragraphs: chunk.clone(),
            });
            chapter_index += 1;
            chunk.clear();
            word_count = 0;
        }
    }

    if !chunk.is_empty() {
        chapters.push(Chapter {
            id: None,
            book_uuid: book_uuid.to_string(),
            chapter_index,
            title: format!("Phần {}", chapter_index + 1),
            paragraphs: chunk,
        });
    }

    chapters
}
