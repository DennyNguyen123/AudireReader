use crate::api::models::{Book, Chapter, Bookmark, Highlight, ReadingProgress, AppSettings, PronunciationRule, BgmTrack, OfflineTtsRecord, SyncHistoryEntry};
use once_cell::sync::OnceCell;
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite::{params, OptionalExtension};
use std::path::Path;
use flutter_rust_bridge::frb;

type DbPool = Pool<SqliteConnectionManager>;
static DB_POOL: OnceCell<DbPool> = OnceCell::new();

#[frb(sync)]
pub fn init_database(db_path: String) -> Result<(), String> {
    let path = Path::new(&db_path).join("audire_reader.db");
    let manager = SqliteConnectionManager::file(&path);
    let pool = Pool::new(manager).map_err(|e| format!("Failed to create connection pool: {}", e))?;
    
    // Attempt to initialize the database
    if DB_POOL.set(pool).is_err() {
        return Err("Database already initialized".into());
    }

    // Run migrations
    run_migrations().map_err(|e| format!("Migration failed: {}", e))?;

    Ok(())
}

pub(crate) fn get_conn() -> Result<r2d2::PooledConnection<SqliteConnectionManager>, String> {
    DB_POOL
        .get()
        .ok_or_else(|| "Database not initialized".to_string())?
        .get()
        .map_err(|e| format!("Failed to get connection from pool: {}", e))
}

fn run_migrations() -> Result<(), rusqlite::Error> {
    let conn = get_conn().unwrap();
    
    conn.execute_batch(
        "
        PRAGMA auto_vacuum = FULL;
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous = NORMAL;
        PRAGMA cache_size = -2000;
        PRAGMA temp_store = MEMORY;
        PRAGMA mmap_size = 0;
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            cover_path TEXT,
            total_chapters INTEGER NOT NULL,
            date_added INTEGER NOT NULL,
            status TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS book_tags (
            book_id INTEGER NOT NULL,
            tag TEXT NOT NULL,
            FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS chapters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_uuid TEXT NOT NULL,
            chapter_index INTEGER NOT NULL,
            title TEXT NOT NULL,
            paragraphs_json TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_chapters_book_uuid ON chapters(book_uuid);
        CREATE INDEX IF NOT EXISTS idx_chapters_book_uuid_index ON chapters(book_uuid, chapter_index);

        CREATE TABLE IF NOT EXISTS bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_uuid TEXT NOT NULL,
            chapter_index INTEGER NOT NULL,
            paragraph_index INTEGER NOT NULL,
            content_snippet TEXT NOT NULL,
            date_added INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_bookmarks_book_uuid ON bookmarks(book_uuid);

        CREATE TABLE IF NOT EXISTS highlights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_uuid TEXT NOT NULL,
            chapter_index INTEGER NOT NULL,
            paragraph_index INTEGER NOT NULL,
            start_offset INTEGER,
            end_offset INTEGER,
            text TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            note TEXT,
            date_added INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_highlights_book_uuid ON highlights(book_uuid);

        CREATE TABLE IF NOT EXISTS reading_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_uuid TEXT UNIQUE NOT NULL,
            current_chapter_index INTEGER NOT NULL,
            current_paragraph_index INTEGER NOT NULL,
            current_character_offset INTEGER NOT NULL,
            last_read INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS app_settings (
            id INTEGER PRIMARY KEY DEFAULT 1,
            settings_json TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS pronunciation_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            target TEXT UNIQUE NOT NULL,
            replacement TEXT NOT NULL,
            is_regex INTEGER NOT NULL DEFAULT 0,
            active INTEGER NOT NULL DEFAULT 1
        );

        CREATE TABLE IF NOT EXISTS bgm_tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            source_type TEXT NOT NULL,
            source_path TEXT NOT NULL,
            date_added INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS offline_tts_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_uuid TEXT NOT NULL,
            chapter_index INTEGER NOT NULL,
            tts_provider TEXT NOT NULL,
            voice_name TEXT NOT NULL,
            speech_rate REAL NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            total_paragraphs INTEGER NOT NULL DEFAULT 0,
            downloaded_paragraphs INTEGER NOT NULL DEFAULT 0,
            total_size_bytes INTEGER NOT NULL DEFAULT 0,
            downloaded_at INTEGER NOT NULL,
            UNIQUE(book_uuid, chapter_index)
        );
        CREATE INDEX IF NOT EXISTS idx_offline_tts_book_uuid ON offline_tts_records(book_uuid);

        CREATE TABLE IF NOT EXISTS sync_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            action TEXT NOT NULL,
            status TEXT NOT NULL,
            details TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_sync_history_timestamp ON sync_history(timestamp DESC);
        "
    )?;

    Ok(())
}

// --- Book CRUD ---

pub fn get_all_books() -> Result<Vec<Book>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare(
        "SELECT b.id, b.uuid, b.title, b.author, b.cover_path, b.total_chapters, b.date_added, b.status,
                GROUP_CONCAT(t.tag, '|||') as tags
         FROM books b
         LEFT JOIN book_tags t ON b.id = t.book_id
         GROUP BY b.id
         ORDER BY b.date_added DESC"
    ).map_err(|e| format!("Query error: {}", e))?;
    
    let book_iter = stmt.query_map([], |row| {
        let tags_str: Option<String> = row.get(8)?;
        let tags = tags_str
            .map(|s| s.split("|||").filter(|t| !t.is_empty()).map(|t| t.to_string()).collect())
            .unwrap_or_default();

        Ok(Book {
            id: row.get(0)?,
            uuid: row.get(1)?,
            title: row.get(2)?,
            author: row.get(3)?,
            cover_path: row.get(4)?,
            total_chapters: row.get(5)?,
            date_added: row.get(6)?,
            status: row.get(7)?,
            tags,
        })
    }).map_err(|e| format!("Query map error: {}", e))?;

    let mut books = Vec::new();
    for book in book_iter {
        books.push(book.map_err(|e| format!("Row error: {}", e))?);
    }
    
    Ok(books)
}

pub fn get_books_filtered(
    tag: Option<String>,
    status: Option<String>,
    sort_by: Option<String>,
) -> Result<Vec<Book>, String> {
    let conn = get_conn()?;
    
    let mut where_clauses = Vec::new();
    let mut params_vec: Vec<Box<dyn rusqlite::ToSql>> = Vec::new();

    if let Some(ref t) = tag {
        let trimmed = t.trim();
        if !trimmed.is_empty() && trimmed != "All" {
            where_clauses.push(format!("b.id IN (SELECT book_id FROM book_tags WHERE tag = ?{})", params_vec.len() + 1));
            params_vec.push(Box::new(trimmed.to_string()));
        }
    }

    if let Some(ref s) = status {
        let trimmed = s.trim();
        if !trimmed.is_empty() && trimmed != "All" {
            where_clauses.push(format!("LOWER(CASE WHEN TRIM(b.status) = '' THEN 'unread' ELSE b.status END) = LOWER(?{})", params_vec.len() + 1));
            params_vec.push(Box::new(trimmed.to_string()));
        }
    }

    let where_str = if where_clauses.is_empty() {
        String::new()
    } else {
        format!("WHERE {}", where_clauses.join(" AND "))
    };

    let order_clause = match sort_by.as_deref() {
        Some("title") => "ORDER BY b.title COLLATE NOCASE ASC",
        Some("author") => "ORDER BY b.author COLLATE NOCASE ASC",
        Some("recentlyRead") => "ORDER BY COALESCE(rp.last_read, 0) DESC, b.date_added DESC",
        _ => "ORDER BY b.date_added DESC",
    };

    let sql = format!(
        "SELECT b.id, b.uuid, b.title, b.author, b.cover_path, b.total_chapters, b.date_added, b.status,
                GROUP_CONCAT(t.tag, '|||') as tags
         FROM books b
         LEFT JOIN book_tags t ON b.id = t.book_id
         LEFT JOIN reading_progress rp ON b.uuid = rp.book_uuid
         {}
         GROUP BY b.id
         {}",
        where_str, order_clause
    );

    let mut stmt = conn.prepare(&sql).map_err(|e| format!("Query error: {}", e))?;
    let params_slice: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|b| b.as_ref()).collect();

    let book_iter = stmt.query_map(params_slice.as_slice(), |row| {
        let tags_str: Option<String> = row.get(8)?;
        let tags = tags_str
            .map(|s| s.split("|||").filter(|t| !t.is_empty()).map(|t| t.to_string()).collect())
            .unwrap_or_default();

        Ok(Book {
            id: row.get(0)?,
            uuid: row.get(1)?,
            title: row.get(2)?,
            author: row.get(3)?,
            cover_path: row.get(4)?,
            total_chapters: row.get(5)?,
            date_added: row.get(6)?,
            status: row.get(7)?,
            tags,
        })
    }).map_err(|e| format!("Query map error: {}", e))?;

    let mut books = Vec::new();
    for book in book_iter {
        books.push(book.map_err(|e| format!("Row error: {}", e))?);
    }
    
    Ok(books)
}

pub fn get_all_book_tags() -> Result<Vec<String>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT DISTINCT tag FROM book_tags WHERE TRIM(tag) != '' ORDER BY tag ASC")
        .map_err(|e| format!("Query error: {}", e))?;

    let rows = stmt.query_map([], |row| {
        let tag: String = row.get(0)?;
        Ok(tag)
    }).map_err(|e| format!("Query map error: {}", e))?;

    let mut list = Vec::new();
    for row in rows {
        if let Ok(t) = row {
            list.push(t);
        }
    }
    Ok(list)
}

pub fn get_book_by_uuid(uuid: String) -> Result<Option<Book>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare(
        "SELECT b.id, b.uuid, b.title, b.author, b.cover_path, b.total_chapters, b.date_added, b.status,
                GROUP_CONCAT(t.tag, '|||') as tags
         FROM books b
         LEFT JOIN book_tags t ON b.id = t.book_id
         WHERE b.uuid = ?1
         GROUP BY b.id LIMIT 1"
    ).map_err(|e| format!("Query error: {}", e))?;

    let book = stmt.query_row(params![uuid], |row| {
        let tags_str: Option<String> = row.get(8)?;
        let tags = tags_str
            .map(|s| s.split("|||").filter(|t| !t.is_empty()).map(|t| t.to_string()).collect())
            .unwrap_or_default();

        Ok(Book {
            id: row.get(0)?,
            uuid: row.get(1)?,
            title: row.get(2)?,
            author: row.get(3)?,
            cover_path: row.get(4)?,
            total_chapters: row.get(5)?,
            date_added: row.get(6)?,
            status: row.get(7)?,
            tags,
        })
    }).optional().map_err(|e| format!("Query row error: {}", e))?;

    Ok(book)
}

pub fn insert_book(book: Book) -> Result<i64, String> {
    let mut conn = get_conn()?;
    let tx = conn.transaction().map_err(|e| e.to_string())?;

    tx.execute(
        "INSERT OR REPLACE INTO books (uuid, title, author, cover_path, total_chapters, date_added, status)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        params![book.uuid, book.title, book.author, book.cover_path, book.total_chapters, book.date_added, book.status],
    ).map_err(|e| e.to_string())?;

    let book_id = tx.last_insert_rowid();

    for tag in &book.tags {
        tx.execute(
            "INSERT INTO book_tags (book_id, tag) VALUES (?1, ?2)",
            params![book_id, tag],
        ).map_err(|e| e.to_string())?;
    }

    tx.commit().map_err(|e| e.to_string())?;
    Ok(book_id)
}

pub fn delete_book(uuid: String) -> Result<(), String> {
    let mut conn = get_conn()?;
    let tx = conn.transaction().map_err(|e| e.to_string())?;

    tx.execute("DELETE FROM chapters WHERE book_uuid = ?1", params![uuid]).map_err(|e| e.to_string())?;
    tx.execute("DELETE FROM reading_progress WHERE book_uuid = ?1", params![uuid]).map_err(|e| e.to_string())?;
    tx.execute("DELETE FROM bookmarks WHERE book_uuid = ?1", params![uuid]).map_err(|e| e.to_string())?;
    tx.execute("DELETE FROM highlights WHERE book_uuid = ?1", params![uuid]).map_err(|e| e.to_string())?;
    tx.execute("DELETE FROM offline_tts_records WHERE book_uuid = ?1", params![uuid]).map_err(|e| e.to_string())?;

    let deleted = tx.execute("DELETE FROM books WHERE uuid = ?1", params![uuid]).map_err(|e| e.to_string())?;

    if deleted == 0 {
        return Err("Book not found".into());
    }

    tx.commit().map_err(|e| e.to_string())?;
    Ok(())
}

pub fn delete_book_cascade(uuid: String, base_dir: Option<String>) -> Result<(), String> {
    let book = get_book_by_uuid(uuid.clone())?;
    
    // Delete database records
    let _ = delete_book(uuid.clone());

    // Delete cover file
    if let Some(b) = book {
        if let Some(ref cover_path) = b.cover_path {
            let p = Path::new(cover_path);
            if p.exists() {
                let _ = std::fs::remove_file(p);
            }
        }
    }

    // Delete offline TTS audio directory
    if let Some(dir) = base_dir {
        let tts_dir = Path::new(&dir).join("tts_offline").join(&uuid);
        if tts_dir.exists() {
            let _ = std::fs::remove_dir_all(tts_dir);
        }
    }

    Ok(())
}

pub fn vacuum_database() -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("PRAGMA wal_checkpoint(TRUNCATE)", []).map_err(|e| e.to_string())?;
    conn.execute("VACUUM", []).map_err(|e| e.to_string())?;
    conn.execute("PRAGMA wal_checkpoint(TRUNCATE)", []).map_err(|e| e.to_string())?;
    Ok(())
}
pub struct SearchResultItem {
    pub chapter_index: i32,
    pub chapter_title: String,
    pub paragraph_index: i32,
    pub text: String,
}

pub fn search_inside_book(book_uuid: String, query: String) -> Result<Vec<SearchResultItem>, String> {
    let conn = get_conn()?;
    let query_lower = query.trim().to_lowercase();
    if query_lower.is_empty() {
        return Ok(vec![]);
    }

    let mut stmt = conn.prepare(
        "SELECT chapter_index, title, paragraphs_json FROM chapters WHERE book_uuid = ? ORDER BY chapter_index ASC"
    ).map_err(|e| e.to_string())?;

    let rows = stmt.query_map([book_uuid], |row| {
        let chapter_index: i32 = row.get(0)?;
        let title: String = row.get(1)?;
        let paragraphs_json: String = row.get(2)?;
        Ok((chapter_index, title, paragraphs_json))
    }).map_err(|e| e.to_string())?;

    let mut results = Vec::new();
    for row in rows {
        if let Ok((chapter_index, title, paragraphs_json)) = row {
            if let Ok(paragraphs) = serde_json::from_str::<Vec<String>>(&paragraphs_json) {
                for (paragraph_index, paragraph) in paragraphs.iter().enumerate() {
                    if paragraph.to_lowercase().contains(&query_lower) {
                        results.push(SearchResultItem {
                            chapter_index,
                            chapter_title: title.clone(),
                            paragraph_index: paragraph_index as i32,
                            text: paragraph.clone(),
                        });
                    }
                }
            }
        }
    }

    Ok(results)
}

// --- Chapter CRUD ---

pub fn get_chapter(book_uuid: String, chapter_index: i32) -> Result<Option<Chapter>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare(
        "SELECT id, book_uuid, chapter_index, title, paragraphs_json FROM chapters WHERE book_uuid = ?1 AND chapter_index = ?2 LIMIT 1"
    ).map_err(|e| format!("Query error: {}", e))?;

    let chapter = stmt.query_row(params![book_uuid, chapter_index], |row| {
        let paragraphs_json: String = row.get(4)?;
        let paragraphs: Vec<String> = serde_json::from_str(&paragraphs_json).unwrap_or_default();
        Ok(Chapter {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            title: row.get(3)?,
            paragraphs,
        })
    }).optional().map_err(|e| format!("Query row error: {}", e))?;

    Ok(chapter)
}

pub fn get_chapter_headers(book_uuid: String) -> Result<Vec<Chapter>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, title FROM chapters WHERE book_uuid = ?1 ORDER BY chapter_index ASC")
        .map_err(|e| format!("Query error: {}", e))?;
    
    let chapter_iter = stmt.query_map(params![book_uuid], |row| {
        Ok(Chapter {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            title: row.get(3)?,
            paragraphs: Vec::new(),
        })
    }).map_err(|e| format!("Query map error: {}", e))?;

    let mut chapters = Vec::new();
    for chapter in chapter_iter {
        chapters.push(chapter.map_err(|e| format!("Row error: {}", e))?);
    }
    
    Ok(chapters)
}

pub fn get_chapters(book_uuid: String) -> Result<Vec<Chapter>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, title, paragraphs_json FROM chapters WHERE book_uuid = ?1 ORDER BY chapter_index ASC")
        .map_err(|e| format!("Query error: {}", e))?;
    
    let chapter_iter = stmt.query_map(params![book_uuid], |row| {
        let paragraphs_json: String = row.get(4)?;
        let paragraphs: Vec<String> = serde_json::from_str(&paragraphs_json).unwrap_or_default();
        
        Ok(Chapter {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            title: row.get(3)?,
            paragraphs,
        })
    }).map_err(|e| format!("Query map error: {}", e))?;

    let mut chapters = Vec::new();
    for chapter in chapter_iter {
        chapters.push(chapter.map_err(|e| format!("Row error: {}", e))?);
    }
    
    Ok(chapters)
}

pub fn insert_chapters(chapters: Vec<Chapter>) -> Result<(), String> {
    if chapters.is_empty() { return Ok(()); }
    
    let mut conn = get_conn()?;
    let tx = conn.transaction().map_err(|e| e.to_string())?;

    for chapter in chapters {
        let paragraphs_json = serde_json::to_string(&chapter.paragraphs).unwrap_or_else(|_| "[]".to_string());
        tx.execute(
            "INSERT OR REPLACE INTO chapters (id, book_uuid, chapter_index, title, paragraphs_json)
             VALUES ((SELECT id FROM chapters WHERE book_uuid = ?1 AND chapter_index = ?2), ?1, ?2, ?3, ?4)",
            params![chapter.book_uuid, chapter.chapter_index, chapter.title, paragraphs_json],
        ).map_err(|e| e.to_string())?;
    }

    tx.commit().map_err(|e| e.to_string())?;
    Ok(())
}

// --- AppSettings CRUD ---

pub fn get_settings() -> Result<Option<AppSettings>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT settings_json FROM app_settings WHERE id = 1")
        .map_err(|e| e.to_string())?;

    let settings_json: Option<String> = stmt.query_row([], |row| row.get(0))
        .optional()
        .map_err(|e| e.to_string())?;

    if let Some(json_str) = settings_json {
        let settings: AppSettings = serde_json::from_str(&json_str)
            .map_err(|e| format!("JSON parse error: {}", e))?;
        Ok(Some(settings))
    } else {
        Ok(None)
    }
}

pub fn save_settings(settings: AppSettings) -> Result<(), String> {
    let conn = get_conn()?;
    let json_str = serde_json::to_string(&settings).map_err(|e| e.to_string())?;

    conn.execute(
        "INSERT OR REPLACE INTO app_settings (id, settings_json) VALUES (1, ?1)",
        params![json_str],
    ).map_err(|e| e.to_string())?;

    Ok(())
}

// --- ReadingProgress CRUD ---

pub fn get_reading_progress(book_uuid: String) -> Result<Option<ReadingProgress>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, current_chapter_index, current_paragraph_index, current_character_offset, last_read FROM reading_progress WHERE book_uuid = ?1")
        .map_err(|e| e.to_string())?;

    let progress = stmt.query_row(params![book_uuid], |row| {
        Ok(ReadingProgress {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            current_chapter_index: row.get(2)?,
            current_paragraph_index: row.get(3)?,
            current_character_offset: row.get(4)?,
            last_read: row.get(5)?,
        })
    }).optional().map_err(|e| e.to_string())?;

    Ok(progress)
}

pub fn get_all_reading_progress() -> Result<Vec<ReadingProgress>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, current_chapter_index, current_paragraph_index, current_character_offset, last_read FROM reading_progress")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map([], |row| {
        Ok(ReadingProgress {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            current_chapter_index: row.get(2)?,
            current_paragraph_index: row.get(3)?,
            current_character_offset: row.get(4)?,
            last_read: row.get(5)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row.map_err(|e| e.to_string())?);
    }
    Ok(result)
}

pub fn save_reading_progress(progress: ReadingProgress) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute(
        "INSERT OR REPLACE INTO reading_progress (book_uuid, current_chapter_index, current_paragraph_index, current_character_offset, last_read)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        params![
            progress.book_uuid,
            progress.current_chapter_index,
            progress.current_paragraph_index,
            progress.current_character_offset,
            progress.last_read
        ],
    ).map_err(|e| e.to_string())?;

    Ok(())
}

pub fn delete_reading_progress(book_uuid: String) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM reading_progress WHERE book_uuid = ?1", params![book_uuid])
        .map_err(|e| e.to_string())?;
    Ok(())
}

// --- Bookmark CRUD ---

pub fn get_bookmarks(book_uuid: String) -> Result<Vec<Bookmark>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, paragraph_index, content_snippet, date_added FROM bookmarks WHERE book_uuid = ?1 ORDER BY chapter_index ASC, paragraph_index ASC")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map(params![book_uuid], |row| {
        Ok(Bookmark {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            paragraph_index: row.get(3)?,
            content_snippet: row.get(4)?,
            date_added: row.get(5)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn get_bookmark_at(book_uuid: String, chapter_index: i32, paragraph_index: i32) -> Result<Option<Bookmark>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, paragraph_index, content_snippet, date_added FROM bookmarks WHERE book_uuid = ?1 AND chapter_index = ?2 AND paragraph_index = ?3 LIMIT 1")
        .map_err(|e| e.to_string())?;

    let bookmark = stmt.query_row(params![book_uuid, chapter_index, paragraph_index], |row| {
        Ok(Bookmark {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            paragraph_index: row.get(3)?,
            content_snippet: row.get(4)?,
            date_added: row.get(5)?,
        })
    }).optional().map_err(|e| e.to_string())?;

    Ok(bookmark)
}

pub fn get_all_bookmarks() -> Result<Vec<Bookmark>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, paragraph_index, content_snippet, date_added FROM bookmarks ORDER BY date_added DESC")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map([], |row| {
        Ok(Bookmark {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            paragraph_index: row.get(3)?,
            content_snippet: row.get(4)?,
            date_added: row.get(5)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn add_bookmark(bookmark: Bookmark) -> Result<i64, String> {
    let conn = get_conn()?;
    conn.execute(
        "INSERT INTO bookmarks (book_uuid, chapter_index, paragraph_index, content_snippet, date_added)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        params![
            bookmark.book_uuid,
            bookmark.chapter_index,
            bookmark.paragraph_index,
            bookmark.content_snippet,
            bookmark.date_added
        ],
    ).map_err(|e| e.to_string())?;

    Ok(conn.last_insert_rowid())
}

pub fn delete_bookmark(id: i64) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM bookmarks WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn delete_bookmarks_for_book(book_uuid: String) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM bookmarks WHERE book_uuid = ?1", params![book_uuid])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn replace_all_bookmarks(book_uuid: String, bookmarks: Vec<Bookmark>) -> Result<(), String> {
    let mut conn = get_conn()?;
    let tx = conn.transaction().map_err(|e| e.to_string())?;
    tx.execute("DELETE FROM bookmarks WHERE book_uuid = ?1", params![book_uuid])
        .map_err(|e| e.to_string())?;

    for b in bookmarks {
        tx.execute(
            "INSERT INTO bookmarks (book_uuid, chapter_index, paragraph_index, content_snippet, date_added)
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![
                b.book_uuid,
                b.chapter_index,
                b.paragraph_index,
                b.content_snippet,
                b.date_added
            ],
        ).map_err(|e| e.to_string())?;
    }

    tx.commit().map_err(|e| e.to_string())?;
    Ok(())
}

// --- Highlight CRUD ---

pub fn get_highlights(book_uuid: String) -> Result<Vec<Highlight>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, paragraph_index, start_offset, end_offset, text, color_hex, note, date_added FROM highlights WHERE book_uuid = ?1 ORDER BY chapter_index ASC, paragraph_index ASC")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map(params![book_uuid], |row| {
        Ok(Highlight {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            paragraph_index: row.get(3)?,
            start_offset: row.get(4)?,
            end_offset: row.get(5)?,
            text: row.get(6)?,
            color_hex: row.get(7)?,
            note: row.get(8)?,
            date_added: row.get(9)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn get_highlight_at(book_uuid: String, chapter_index: i32, paragraph_index: i32) -> Result<Option<Highlight>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, paragraph_index, start_offset, end_offset, text, color_hex, note, date_added FROM highlights WHERE book_uuid = ?1 AND chapter_index = ?2 AND paragraph_index = ?3 LIMIT 1")
        .map_err(|e| e.to_string())?;

    let highlight = stmt.query_row(params![book_uuid, chapter_index, paragraph_index], |row| {
        Ok(Highlight {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            paragraph_index: row.get(3)?,
            start_offset: row.get(4)?,
            end_offset: row.get(5)?,
            text: row.get(6)?,
            color_hex: row.get(7)?,
            note: row.get(8)?,
            date_added: row.get(9)?,
        })
    }).optional().map_err(|e| e.to_string())?;

    Ok(highlight)
}

pub fn get_all_highlights() -> Result<Vec<Highlight>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, paragraph_index, start_offset, end_offset, text, color_hex, note, date_added FROM highlights ORDER BY date_added DESC")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map([], |row| {
        Ok(Highlight {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            paragraph_index: row.get(3)?,
            start_offset: row.get(4)?,
            end_offset: row.get(5)?,
            text: row.get(6)?,
            color_hex: row.get(7)?,
            note: row.get(8)?,
            date_added: row.get(9)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn add_highlight(highlight: Highlight) -> Result<i64, String> {
    let conn = get_conn()?;
    conn.execute(
        "INSERT INTO highlights (book_uuid, chapter_index, paragraph_index, start_offset, end_offset, text, color_hex, note, date_added)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
        params![
            highlight.book_uuid,
            highlight.chapter_index,
            highlight.paragraph_index,
            highlight.start_offset,
            highlight.end_offset,
            highlight.text,
            highlight.color_hex,
            highlight.note,
            highlight.date_added
        ],
    ).map_err(|e| e.to_string())?;

    Ok(conn.last_insert_rowid())
}

pub fn delete_highlight(id: i64) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM highlights WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn delete_highlights_for_book(book_uuid: String) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM highlights WHERE book_uuid = ?1", params![book_uuid])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn replace_all_highlights(book_uuid: String, highlights: Vec<Highlight>) -> Result<(), String> {
    let mut conn = get_conn()?;
    let tx = conn.transaction().map_err(|e| e.to_string())?;
    tx.execute("DELETE FROM highlights WHERE book_uuid = ?1", params![book_uuid])
        .map_err(|e| e.to_string())?;

    for h in highlights {
        tx.execute(
            "INSERT INTO highlights (book_uuid, chapter_index, paragraph_index, start_offset, end_offset, text, color_hex, note, date_added)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            params![
                h.book_uuid,
                h.chapter_index,
                h.paragraph_index,
                h.start_offset,
                h.end_offset,
                h.text,
                h.color_hex,
                h.note,
                h.date_added
            ],
        ).map_err(|e| e.to_string())?;
    }

    tx.commit().map_err(|e| e.to_string())?;
    Ok(())
}

// --- PronunciationRule CRUD ---

pub fn get_pronunciation_rules() -> Result<Vec<PronunciationRule>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, target, replacement, is_regex, active FROM pronunciation_rules ORDER BY id ASC")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map([], |row| {
        let is_regex_int: i32 = row.get(3)?;
        let active_int: i32 = row.get(4)?;
        Ok(PronunciationRule {
            id: row.get(0)?,
            target: row.get(1)?,
            replacement: row.get(2)?,
            is_regex: is_regex_int != 0,
            active: active_int != 0,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn save_pronunciation_rule(rule: PronunciationRule) -> Result<i64, String> {
    let conn = get_conn()?;
    let is_regex_int = if rule.is_regex { 1 } else { 0 };
    let active_int = if rule.active { 1 } else { 0 };

    if let Some(id) = rule.id {
        conn.execute(
            "UPDATE pronunciation_rules SET target = ?1, replacement = ?2, is_regex = ?3, active = ?4 WHERE id = ?5",
            params![rule.target, rule.replacement, is_regex_int, active_int, id],
        ).map_err(|e| e.to_string())?;
        Ok(id)
    } else {
        conn.execute(
            "INSERT INTO pronunciation_rules (target, replacement, is_regex, active) VALUES (?1, ?2, ?3, ?4)",
            params![rule.target, rule.replacement, is_regex_int, active_int],
        ).map_err(|e| e.to_string())?;
        Ok(conn.last_insert_rowid())
    }
}

pub fn delete_pronunciation_rule(id: i64) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM pronunciation_rules WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

// --- BgmTrack CRUD ---

pub fn get_bgm_tracks() -> Result<Vec<BgmTrack>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, name, source_type, source_path, date_added FROM bgm_tracks ORDER BY id ASC")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map([], |row| {
        Ok(BgmTrack {
            id: row.get(0)?,
            name: row.get(1)?,
            source_type: row.get(2)?,
            source_path: row.get(3)?,
            date_added: row.get(4)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn get_bgm_track_by_id(id: i64) -> Result<Option<BgmTrack>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, name, source_type, source_path, date_added FROM bgm_tracks WHERE id = ?1 LIMIT 1")
        .map_err(|e| e.to_string())?;

    let track = stmt.query_row(params![id], |row| {
        Ok(BgmTrack {
            id: row.get(0)?,
            name: row.get(1)?,
            source_type: row.get(2)?,
            source_path: row.get(3)?,
            date_added: row.get(4)?,
        })
    }).optional().map_err(|e| e.to_string())?;

    Ok(track)
}

pub fn add_bgm_track(track: BgmTrack) -> Result<i64, String> {
    let conn = get_conn()?;
    conn.execute(
        "INSERT INTO bgm_tracks (name, source_type, source_path, date_added) VALUES (?1, ?2, ?3, ?4)",
        params![track.name, track.source_type, track.source_path, track.date_added],
    ).map_err(|e| e.to_string())?;

    Ok(conn.last_insert_rowid())
}

pub fn delete_bgm_track(id: i64) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM bgm_tracks WHERE id = ?1", params![id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

// --- OfflineTtsRecord CRUD ---

pub fn get_offline_tts_records(book_uuid: String) -> Result<Vec<OfflineTtsRecord>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, tts_provider, voice_name, speech_rate, is_completed, total_paragraphs, downloaded_paragraphs, total_size_bytes, downloaded_at FROM offline_tts_records WHERE book_uuid = ?1")
        .map_err(|e| e.to_string())?;

    let rows = stmt.query_map(params![book_uuid], |row| {
        let is_completed_int: i32 = row.get(6)?;
        Ok(OfflineTtsRecord {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            tts_provider: row.get(3)?,
            voice_name: row.get(4)?,
            speech_rate: row.get(5)?,
            is_completed: is_completed_int != 0,
            total_paragraphs: row.get(7)?,
            downloaded_paragraphs: row.get(8)?,
            total_size_bytes: row.get(9)?,
            downloaded_at: row.get(10)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for row in rows {
        list.push(row.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn get_offline_tts_record(book_uuid: String, chapter_index: i32) -> Result<Option<OfflineTtsRecord>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, book_uuid, chapter_index, tts_provider, voice_name, speech_rate, is_completed, total_paragraphs, downloaded_paragraphs, total_size_bytes, downloaded_at FROM offline_tts_records WHERE book_uuid = ?1 AND chapter_index = ?2")
        .map_err(|e| e.to_string())?;

    let record = stmt.query_row(params![book_uuid, chapter_index], |row| {
        let is_completed_int: i32 = row.get(6)?;
        Ok(OfflineTtsRecord {
            id: row.get(0)?,
            book_uuid: row.get(1)?,
            chapter_index: row.get(2)?,
            tts_provider: row.get(3)?,
            voice_name: row.get(4)?,
            speech_rate: row.get(5)?,
            is_completed: is_completed_int != 0,
            total_paragraphs: row.get(7)?,
            downloaded_paragraphs: row.get(8)?,
            total_size_bytes: row.get(9)?,
            downloaded_at: row.get(10)?,
        })
    }).optional().map_err(|e| e.to_string())?;

    Ok(record)
}

pub fn save_offline_tts_record(record: OfflineTtsRecord) -> Result<(), String> {
    let conn = get_conn()?;
    let is_completed_int = if record.is_completed { 1 } else { 0 };

    conn.execute(
        "INSERT OR REPLACE INTO offline_tts_records (book_uuid, chapter_index, tts_provider, voice_name, speech_rate, is_completed, total_paragraphs, downloaded_paragraphs, total_size_bytes, downloaded_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
        params![
            record.book_uuid,
            record.chapter_index,
            record.tts_provider,
            record.voice_name,
            record.speech_rate,
            is_completed_int,
            record.total_paragraphs,
            record.downloaded_paragraphs,
            record.total_size_bytes,
            record.downloaded_at
        ],
    ).map_err(|e| e.to_string())?;

    Ok(())
}

pub fn delete_offline_tts_record(book_uuid: String, chapter_index: i32) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM offline_tts_records WHERE book_uuid = ?1 AND chapter_index = ?2", params![book_uuid, chapter_index])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn delete_offline_tts_records_for_book(book_uuid: String) -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM offline_tts_records WHERE book_uuid = ?1", params![book_uuid])
        .map_err(|e| e.to_string())?;
    Ok(())
}

// --- Sync History CRUD ---

pub fn insert_sync_history(entry: SyncHistoryEntry) -> Result<i64, String> {
    let conn = get_conn()?;
    conn.execute(
        "INSERT INTO sync_history (timestamp, action, status, details) VALUES (?1, ?2, ?3, ?4)",
        params![entry.timestamp, entry.action, entry.status, entry.details],
    ).map_err(|e| e.to_string())?;
    Ok(conn.last_insert_rowid())
}

pub fn get_sync_history(limit: Option<i64>) -> Result<Vec<SyncHistoryEntry>, String> {
    let conn = get_conn()?;
    let limit_val = limit.unwrap_or(100);
    let mut stmt = conn.prepare(
        "SELECT id, timestamp, action, status, details FROM sync_history ORDER BY timestamp DESC LIMIT ?1"
    ).map_err(|e| e.to_string())?;

    let iter = stmt.query_map(params![limit_val], |row| {
        Ok(SyncHistoryEntry {
            id: row.get(0)?,
            timestamp: row.get(1)?,
            action: row.get(2)?,
            status: row.get(3)?,
            details: row.get(4)?,
        })
    }).map_err(|e| e.to_string())?;

    let mut list = Vec::new();
    for item in iter {
        list.push(item.map_err(|e| e.to_string())?);
    }
    Ok(list)
}

pub fn clear_sync_history() -> Result<(), String> {
    let conn = get_conn()?;
    conn.execute("DELETE FROM sync_history", []).map_err(|e| e.to_string())?;
    Ok(())
}

