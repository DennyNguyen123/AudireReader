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
    if let Some((cover_bytes, _mime)) = doc.get_cover() {
        let covers_dir = Path::new(&documents_dir_path).join("covers");
        if !covers_dir.exists() {
            let _ = fs::create_dir_all(&covers_dir);
        }
        let cover_file_path = covers_dir.join(format!("{}.png", uuid));
        if let Ok(mut f) = File::create(&cover_file_path) {
            use std::io::Write;
            let _ = f.write_all(&cover_bytes);
            cover_path = Some(cover_file_path.to_string_lossy().to_string());
        }
    }

    let mut chapters = Vec::new();
    let mut chapter_index = 0;

    let num_pages = doc.get_num_chapters();
    for i in 0..num_pages {
        let _ = doc.set_current_chapter(i);
        if let Some((content, _mime)) = doc.get_current_str() {
                let mut ch_title = format!("Chapter {}", chapter_index + 1);
                
                // Attempt to get title from TOC if possible
                // (epub crate doesn't easily map spine page to toc entry, so fallback to Chapter N)
                
                let paragraphs = parse_html_to_paragraphs(&content);
                if !paragraphs.is_empty() {
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

    let book = Book {
        id: None,
        uuid: uuid.clone(),
        title,
        author,
        cover_path,
        total_chapters: chapters.len() as i32,
        date_added: Utc::now().timestamp_millis(),
        status: "reading".to_string(),
        tags: vec![],
    };

    Ok(ParsedBookData { book, chapters })
}

fn parse_html_to_paragraphs(html_content: &str) -> Vec<String> {
    if html_content.is_empty() {
        return vec![];
    }
    
    let fragment = scraper::Html::parse_document(html_content);
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
    
    if clean_paras.is_empty() {
        let body_selector = scraper::Selector::parse("body").unwrap();
        if let Some(body) = fragment.select(&body_selector).next() {
            let txt: String = body.text().collect::<Vec<_>>().join(" ");
            let lines: Vec<String> = txt.split('\n')
                .map(|s| s.trim().to_string())
                .filter(|s| s.len() > 2)
                .collect();
            return lines;
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
