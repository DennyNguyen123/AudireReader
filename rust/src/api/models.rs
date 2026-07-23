use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: Option<i64>,
    pub uuid: String,
    pub title: String,
    pub author: String,
    pub cover_path: Option<String>,
    pub total_chapters: i32,
    pub date_added: i64, // Unix timestamp in milliseconds
    pub status: String,
    pub tags: Vec<String>,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chapter {
    pub id: Option<i64>,
    pub book_uuid: String,
    pub chapter_index: i32,
    pub title: String,
    pub paragraphs: Vec<String>,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bookmark {
    pub id: Option<i64>,
    pub book_uuid: String,
    pub chapter_index: i32,
    pub paragraph_index: i32,
    pub content_snippet: String,
    pub date_added: i64,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Highlight {
    pub id: Option<i64>,
    pub book_uuid: String,
    pub chapter_index: i32,
    pub paragraph_index: i32,
    pub start_offset: Option<i32>,
    pub end_offset: Option<i32>,
    pub text: String,
    pub color_hex: String,
    pub note: Option<String>,
    pub date_added: i64,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReadingProgress {
    pub id: Option<i64>,
    pub book_uuid: String,
    pub current_chapter_index: i32,
    pub current_paragraph_index: i32,
    pub current_character_offset: i32,
    pub last_read: i64,
}

#[frb(dart_metadata = ("freezed"))]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppSettings {
    pub id: i64,
    pub font_size: f64,
    pub speech_rate: f64,
    pub selected_voice_name: Option<String>,
    pub selected_voice_locale: Option<String>,
    pub tts_provider: String,
    pub open_ai_tts_endpoint: String,
    pub open_ai_tts_api_key: String,
    pub open_ai_tts_model: String,
    pub tts_download_concurrency: i32,
    pub font_family: String,
    pub theme_mode: String,
    pub app_locale: String,
    pub line_height: f64,
    pub paragraph_spacing: f64,
    pub text_alignment: String,
    pub side_margin: f64,
    pub custom_background_color: Option<String>,
    pub custom_text_color: Option<String>,
    pub primary_color_hex: Option<String>,
    pub web_dav_enabled: bool,
    pub web_dav_url: String,
    pub web_dav_username: String,
    pub web_dav_last_sync: Option<i64>,
    pub device_id: Option<String>,
    pub device_name: Option<String>,
    pub open_last_read_on_launch: bool,
    pub hotkey_next_paragraph: String,
    pub hotkey_prev_paragraph: String,
    pub hotkey_next_chapter: String,
    pub hotkey_prev_chapter: String,
    pub hotkey_play_pause_tts: String,
    pub hotkey_open_chapter: String,
    pub hotkey_open_setting: String,
    pub hotkey_boss_key: String,
    pub boss_key_action: String,
    pub auto_check_update: bool,
    pub bgm_enabled: bool,
    pub bgm_volume: f64,
    pub current_bgm_track_id: Option<i32>,
    pub current_bgm_track_url: Option<String>,
    pub current_bgm_track_name: Option<String>,
    pub bgm_loop_mode: String,
    pub bgm_provider_id: String,
    pub last_local_track_url: Option<String>,
    pub last_radio_track_url: Option<String>,
    pub last_radio_track_name: Option<String>,
    pub last_lofi_track_url: Option<String>,
    pub last_lofi_track_name: Option<String>,
    pub sort_by: String,
    pub show_assistive_button: bool,
    pub assistive_button_x: f64,
    pub assistive_button_y: f64,
    pub assistive_single_tap_action: String,
    pub assistive_double_tap_action: String,
    pub assistive_long_press_action: String,
    pub developer_mode: bool,
    pub enable_debug_logs: bool,
    pub enable_web_dav_debug: bool,
}
