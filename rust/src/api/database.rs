use crate::api::models::{Book, Chapter, Bookmark, Highlight, ReadingProgress, AppSettings};
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

fn get_conn() -> Result<r2d2::PooledConnection<SqliteConnectionManager>, String> {
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
        "
    )?;

    Ok(())
}

// Basic Book CRUD example
pub fn get_all_books() -> Result<Vec<Book>, String> {
    let conn = get_conn()?;
    let mut stmt = conn.prepare("SELECT id, uuid, title, author, cover_path, total_chapters, date_added, status FROM books")
        .map_err(|e| format!("Query error: {}", e))?;
    
    let book_iter = stmt.query_map([], |row| {
        Ok(Book {
            id: row.get(0)?,
            uuid: row.get(1)?,
            title: row.get(2)?,
            author: row.get(3)?,
            cover_path: row.get(4)?,
            total_chapters: row.get(5)?,
            date_added: row.get(6)?,
            status: row.get(7)?,
            tags: vec![], // Tags would be fetched separately or via JOIN
        })
    }).map_err(|e| format!("Query map error: {}", e))?;

    let mut books = Vec::new();
    for book in book_iter {
        let mut b = book.map_err(|e| format!("Row error: {}", e))?;
        // Fetch tags
        let mut tag_stmt = conn.prepare("SELECT tag FROM book_tags WHERE book_id = ?").unwrap();
        let tags_iter = tag_stmt.query_map(params![b.id], |row| row.get::<_, String>(0)).unwrap();
        for tag in tags_iter {
            b.tags.push(tag.unwrap());
        }
        books.push(b);
    }
    
    Ok(books)
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
use std::fs;
use std::path::PathBuf;

pub fn delete_book(uuid: String) -> Result<(), String> {
    let mut conn = get_conn()?;
    let tx = conn.transaction().map_err(|e| e.to_string())?;

    // Delete chapters first
    tx.execute(
        "DELETE FROM chapters WHERE book_uuid = ?1",
        params![uuid],
    ).map_err(|e| e.to_string())?;

    // Delete from books
    let deleted = tx.execute(
        "DELETE FROM books WHERE uuid = ?1",
        params![uuid],
    ).map_err(|e| e.to_string())?;

    if deleted == 0 {
        return Err("Book not found".into());
    }

    tx.commit().map_err(|e| e.to_string())?;
    Ok(())
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
