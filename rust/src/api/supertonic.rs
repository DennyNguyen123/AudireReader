use std::collections::HashMap;
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use ndarray::{Array1, Array2, Array3};
use once_cell::sync::Lazy;
use ort::session::builder::SessionBuilder;
use ort::session::Session;
use ort::value::Value;
use parking_lot::Mutex;
use rand::Rng;
use serde_json::Value as JsonValue;
use unicode_normalization::UnicodeNormalization;

struct SupertonicState {
    dp_session: Session,
    text_enc_session: Session,
    vector_est_session: Session,
    vocoder_session: Session,
    indexer: HashMap<u32, i64>,
    style_ttl: Array3<f32>,
    style_dp: Array3<f32>,
    _current_style_name: String,
    sample_rate: u32,
    base_chunk_size: usize,
    chunk_compress_factor: usize,
    latent_dim: usize,
}

static SUPERTONIC_ENGINE: Lazy<Mutex<Option<SupertonicState>>> = Lazy::new(|| Mutex::new(None));

pub const AVAILABLE_LANGS: &[&str] = &[
    "en", "ko", "ja", "ar", "bg", "cs", "da", "de", "el", "es", "et", "fi", "fr", "hi", "hr", "hu",
    "id", "it", "lt", "lv", "nl", "pl", "pt", "ro", "ru", "sk", "sl", "sv", "tr", "uk", "vi", "na",
];

pub fn is_valid_lang(lang: &str) -> bool {
    AVAILABLE_LANGS.contains(&lang)
}

pub fn detect_language(text: &str) -> String {
    let clean_text = text.trim();
    if clean_text.is_empty() {
        return "en".to_string();
    }

    for c in clean_text.chars() {
        let code = c as u32;
        if (0x1100..=0x11FF).contains(&code)
            || (0x3130..=0x318F).contains(&code)
            || (0xA960..=0xA97F).contains(&code)
            || (0xAC00..=0xD7AF).contains(&code)
            || (0xD7B0..=0xD7FF).contains(&code)
        {
            return "ko".to_string();
        }
    }

    for c in clean_text.chars() {
        let code = c as u32;
        if (0x3040..=0x309F).contains(&code) || (0x30A0..=0x30FF).contains(&code) {
            return "ja".to_string();
        }
    }

    let vietnamese_chars = "àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđĐ";
    if clean_text.chars().any(|c| vietnamese_chars.contains(c)) {
        return "vi".to_string();
    }

    "en".to_string()
}

pub fn preprocess_text(text: &str, lang: &str) -> Result<String, String> {
    if !is_valid_lang(lang) {
        return Err(format!("Invalid language: {}", lang));
    }

    let mut normalized: String = text.nfkd().collect();

    normalized = normalized
        .chars()
        .filter(|&c| {
            let code = c as u32;
            !((0x1F600..=0x1F64F).contains(&code)
                || (0x1F300..=0x1F5FF).contains(&code)
                || (0x1F680..=0x1F6FF).contains(&code)
                || (0x1F700..=0x1F77F).contains(&code)
                || (0x1F780..=0x1F7FF).contains(&code)
                || (0x1F800..=0x1F8FF).contains(&code)
                || (0x1F900..=0x1F9FF).contains(&code)
                || (0x1FA00..=0x1FA6F).contains(&code)
                || (0x1FA70..=0x1FAFF).contains(&code)
                || (0x2600..=0x26FF).contains(&code)
                || (0x2700..=0x27BF).contains(&code)
                || (0x1F1E6..=0x1F1FF).contains(&code))
        })
        .collect();

    let replacements = [
        ('–', "-"), ('‑', "-"), ('—', "-"), ('_', " "),
        ('\u{201C}', "\""), ('\u{201D}', "\""), ('\u{2018}', "'"), ('\u{2019}', "'"),
        ('´', "'"), ('`', "'"), ('[', " "), (']', " "), ('|', " "), ('/', " "),
        ('#', " "), ('→', " "), ('←', " "),
    ];

    for (from, to) in replacements {
        normalized = normalized.replace(from, to);
    }

    let invalid_symbols = ['♥', '☆', '♡', '©', '\\'];
    normalized = normalized.chars().filter(|c| !invalid_symbols.contains(c)).collect();

    normalized = normalized.replace('@', " at ");
    normalized = normalized.replace("e.g.,", "for example, ");
    normalized = normalized.replace("i.e.,", "that is, ");

    for p in [",", ".", "!", "?", ";", ":", "'"] {
        let pattern = format!(" {}", p);
        normalized = normalized.replace(&pattern, p);
    }

    while normalized.contains("\"\"") {
        normalized = normalized.replace("\"\"", "\"");
    }
    while normalized.contains("''") {
        normalized = normalized.replace("''", "'");
    }

    let words: Vec<&str> = normalized.split_whitespace().collect();
    normalized = words.join(" ");

    if !normalized.is_empty() {
        let last_char = normalized.chars().last().unwrap();
        let punctuation = ".!?;:,'\"')]}…。」』】〉》›»";
        if !punctuation.contains(last_char) {
            normalized.push('.');
        }
    }

    Ok(format!("<{}>{}</{}>", lang, normalized, lang))
}

pub fn chunk_text(text: &str, max_len: usize) -> Vec<String> {
    let paragraphs: Vec<&str> = text
        .trim()
        .split('\n')
        .map(|p| p.trim())
        .filter(|p| !p.is_empty())
        .collect();

    let mut chunks = Vec::new();
    for paragraph in paragraphs {
        let sentences: Vec<&str> = paragraph
            .split_inclusive(|c| c == '.' || c == '!' || c == '?')
            .collect();

        let mut current_chunk = String::new();
        for sentence in sentences {
            let sentence_trim = sentence.trim();
            if sentence_trim.is_empty() {
                continue;
            }

            if current_chunk.len() + sentence_trim.len() + 1 <= max_len {
                if !current_chunk.is_empty() {
                    current_chunk.push(' ');
                }
                current_chunk.push_str(sentence_trim);
            } else {
                if !current_chunk.is_empty() {
                    chunks.push(current_chunk.trim().to_string());
                }
                current_chunk = sentence_trim.to_string();
            }
        }
        if !current_chunk.is_empty() {
            chunks.push(current_chunk.trim().to_string());
        }
    }

    chunks
}

pub fn encode_wav(audio_data: &[f32], sample_rate: u32) -> Vec<u8> {
    let num_channels: u16 = 1;
    let bits_per_sample: u16 = 16;
    let data_size = (audio_data.len() * 2) as u32;
    let file_size: u32 = 36 + data_size;

    let mut buffer = Vec::with_capacity(44 + data_size as usize);

    buffer.extend_from_slice(b"RIFF");
    buffer.extend_from_slice(&file_size.to_le_bytes());
    buffer.extend_from_slice(b"WAVE");

    buffer.extend_from_slice(b"fmt ");
    buffer.extend_from_slice(&16u32.to_le_bytes());
    buffer.extend_from_slice(&1u16.to_le_bytes());
    buffer.extend_from_slice(&num_channels.to_le_bytes());
    buffer.extend_from_slice(&sample_rate.to_le_bytes());
    let byte_rate = sample_rate * num_channels as u32 * (bits_per_sample as u32 / 8);
    buffer.extend_from_slice(&byte_rate.to_le_bytes());
    let block_align = num_channels * (bits_per_sample / 8);
    buffer.extend_from_slice(&block_align.to_le_bytes());
    buffer.extend_from_slice(&bits_per_sample.to_le_bytes());

    buffer.extend_from_slice(b"data");
    buffer.extend_from_slice(&data_size.to_le_bytes());

    for &sample in audio_data {
        let clamped = sample.max(-1.0).min(1.0);
        let pcm_val = (clamped * 32767.0).round() as i16;
        buffer.extend_from_slice(&pcm_val.to_le_bytes());
    }

    buffer
}

fn process_unicode_indexer(
    text_list: &[String],
    lang_list: &[String],
    indexer: &HashMap<u32, i64>,
) -> Result<(Array2<i64>, Array3<f32>), String> {
    let mut processed_texts = Vec::new();
    for (t, l) in text_list.iter().zip(lang_list.iter()) {
        processed_texts.push(preprocess_text(t, l)?);
    }

    let lengths: Vec<usize> = processed_texts.iter().map(|t| t.chars().count()).collect();
    let max_len = *lengths.iter().max().unwrap_or(&0);

    let bsz = processed_texts.len();
    let mut text_ids = Array2::<i64>::zeros((bsz, max_len));
    for (b, text) in processed_texts.iter().enumerate() {
        for (i, c) in text.chars().enumerate() {
            let rune = c as u32;
            let val = indexer.get(&rune).cloned().unwrap_or(0);
            text_ids[[b, i]] = val;
        }
    }

    let mut text_mask = Array3::<f32>::zeros((bsz, 1, max_len));
    for (b, &len) in lengths.iter().enumerate() {
        for i in 0..len {
            text_mask[[b, 0, i]] = 1.0;
        }
    }

    Ok((text_ids, text_mask))
}

fn sample_noisy_latent(
    duration: &[f32],
    sample_rate: u32,
    base_chunk_size: usize,
    chunk_compress_factor: usize,
    ldim: usize,
) -> (Array3<f32>, Array3<f32>) {
    let wav_len_max = duration.iter().cloned().fold(0.0f32, f32::max) * sample_rate as f32;
    let chunk_size = base_chunk_size * chunk_compress_factor;
    let latent_len = ((wav_len_max + chunk_size as f32 - 1.0) / chunk_size as f32).floor() as usize;
    let latent_dim = ldim * chunk_compress_factor;

    let bsz = duration.len();
    let latent_size = base_chunk_size * chunk_compress_factor;
    let latent_lengths: Vec<usize> = duration
        .iter()
        .map(|&d| (((d * sample_rate as f32) + latent_size as f32 - 1.0) / latent_size as f32).floor() as usize)
        .collect();
    let max_latent_len = *latent_lengths.iter().max().unwrap_or(&0);

    let mut latent_mask = Array3::<f32>::zeros((bsz, 1, max_latent_len));
    for (b, &len) in latent_lengths.iter().enumerate() {
        for i in 0..len {
            latent_mask[[b, 0, i]] = 1.0;
        }
    }

    let mut rng = rand::thread_rng();
    let mut noisy_latent = Array3::<f32>::zeros((bsz, latent_dim, latent_len));

    for b in 0..bsz {
        for d in 0..latent_dim {
            for t in 0..latent_len {
                let u1: f64 = rng.gen_range(1e-10..1.0);
                let u2: f64 = rng.gen_range(0.0..1.0);
                let noise = ((-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()) as f32;

                let mask = if t < max_latent_len { latent_mask[[b, 0, t]] } else { 0.0 };
                noisy_latent[[b, d, t]] = noise * mask;
            }
        }
    }

    (noisy_latent, latent_mask)
}

pub fn check_supertonic_model_exists(base_dir: String) -> bool {
    let assets_dir = Path::new(&base_dir).join("supertonic_assets");
    let required_files = [
        "duration_predictor.onnx",
        "text_encoder.onnx",
        "vector_estimator.onnx",
        "vocoder.onnx",
        "tts.json",
        "unicode_indexer.json",
        "M1.json", "M2.json", "M3.json", "M4.json", "M5.json",
        "F1.json", "F2.json", "F3.json", "F4.json", "F5.json",
    ];

    for file in &required_files {
        let p = assets_dir.join(file);
        if !p.exists() || fs::metadata(&p).map(|m| m.len()).unwrap_or(0) == 0 {
            return false;
        }
    }
    true
}

pub fn delete_supertonic_models(base_dir: String) -> Result<(), String> {
    let assets_dir = Path::new(&base_dir).join("supertonic_assets");
    if assets_dir.exists() {
        fs::remove_dir_all(&assets_dir).map_err(|e| e.to_string())?;
    }
    Ok(())
}

pub async fn download_supertonic_models(base_dir: String) -> Result<(), String> {
    let assets_dir = Path::new(&base_dir).join("supertonic_assets");
    if !assets_dir.exists() {
        fs::create_dir_all(&assets_dir).map_err(|e| e.to_string())?;
    }

    let base_url = "https://huggingface.co/Supertone/supertonic-3/resolve/main";
    let files_to_download = [
        ("tts.json", format!("{}/onnx/tts.json", base_url)),
        ("unicode_indexer.json", format!("{}/onnx/unicode_indexer.json", base_url)),
        ("M1.json", format!("{}/voice_styles/M1.json", base_url)),
        ("M2.json", format!("{}/voice_styles/M2.json", base_url)),
        ("M3.json", format!("{}/voice_styles/M3.json", base_url)),
        ("M4.json", format!("{}/voice_styles/M4.json", base_url)),
        ("M5.json", format!("{}/voice_styles/M5.json", base_url)),
        ("F1.json", format!("{}/voice_styles/F1.json", base_url)),
        ("F2.json", format!("{}/voice_styles/F2.json", base_url)),
        ("F3.json", format!("{}/voice_styles/F3.json", base_url)),
        ("F4.json", format!("{}/voice_styles/F4.json", base_url)),
        ("F5.json", format!("{}/voice_styles/F5.json", base_url)),
        ("duration_predictor.onnx", format!("{}/onnx/duration_predictor.onnx", base_url)),
        ("text_encoder.onnx", format!("{}/onnx/text_encoder.onnx", base_url)),
        ("vector_estimator.onnx", format!("{}/onnx/vector_estimator.onnx", base_url)),
        ("vocoder.onnx", format!("{}/onnx/vocoder.onnx", base_url)),
    ];

    let client = reqwest::Client::new();
    for (filename, url) in files_to_download {
        let dest = assets_dir.join(filename);
        if dest.exists() && fs::metadata(&dest).map(|m| m.len()).unwrap_or(0) > 0 {
            continue;
        }

        let res = client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to download {}: {}", filename, e))?;

        if !res.status().is_success() {
            return Err(format!("Download {} failed with status {}", filename, res.status()));
        }

        let bytes = res
            .bytes()
            .await
            .map_err(|e| format!("Failed to read bytes for {}: {}", filename, e))?;

        let mut file = File::create(&dest).map_err(|e| e.to_string())?;
        file.write_all(&bytes).map_err(|e| e.to_string())?;
    }

    Ok(())
}

fn array2_i64_to_value(arr: Array2<i64>) -> Result<Value, String> {
    let shape: Vec<i64> = arr.shape().iter().map(|&s| s as i64).collect();
    let (data, _) = arr.into_raw_vec_and_offset();
    let tensor = Value::from_array((shape, data)).map_err(|e| e.to_string())?;
    Ok(tensor.into_dyn())
}

fn array1_f32_to_value(arr: Array1<f32>) -> Result<Value, String> {
    let shape: Vec<i64> = arr.shape().iter().map(|&s| s as i64).collect();
    let (data, _) = arr.into_raw_vec_and_offset();
    let tensor = Value::from_array((shape, data)).map_err(|e| e.to_string())?;
    Ok(tensor.into_dyn())
}

fn array2_f32_to_value(arr: Array2<f32>) -> Result<Value, String> {
    let shape: Vec<i64> = arr.shape().iter().map(|&s| s as i64).collect();
    let (data, _) = arr.into_raw_vec_and_offset();
    let tensor = Value::from_array((shape, data)).map_err(|e| e.to_string())?;
    Ok(tensor.into_dyn())
}

fn array3_f32_to_value(arr: Array3<f32>) -> Result<Value, String> {
    let shape: Vec<i64> = arr.shape().iter().map(|&s| s as i64).collect();
    let (data, _) = arr.into_raw_vec_and_offset();
    let tensor = Value::from_array((shape, data)).map_err(|e| e.to_string())?;
    Ok(tensor.into_dyn())
}

pub async fn init_supertonic_engine(base_dir: String, voice_style: String) -> Result<bool, String> {
    let assets_dir = Path::new(&base_dir).join("supertonic_assets");
    if !check_supertonic_model_exists(base_dir.clone()) {
        return Err("Model files are missing. Please download first.".to_string());
    }

    let tts_json_path = assets_dir.join("tts.json");
    let tts_str = fs::read_to_string(&tts_json_path).map_err(|e| e.to_string())?;
    let cfgs: JsonValue = serde_json::from_str(&tts_str).map_err(|e| e.to_string())?;

    let sample_rate = cfgs["ae"]["sample_rate"].as_u64().unwrap_or(22050) as u32;
    let base_chunk_size = cfgs["ae"]["base_chunk_size"].as_u64().unwrap_or(240) as usize;
    let chunk_compress_factor = cfgs["ttl"]["chunk_compress_factor"].as_u64().unwrap_or(4) as usize;
    let latent_dim = cfgs["ttl"]["latent_dim"].as_u64().unwrap_or(64) as usize;

    let indexer_path = assets_dir.join("unicode_indexer.json");
    let indexer_str = fs::read_to_string(&indexer_path).map_err(|e| e.to_string())?;
    let indexer_raw: JsonValue = serde_json::from_str(&indexer_str).map_err(|e| e.to_string())?;

    let mut indexer = HashMap::new();
    if let Some(arr) = indexer_raw.as_array() {
        for (i, val) in arr.iter().enumerate() {
            if let Some(v) = val.as_i64() {
                indexer.insert(i as u32, v);
            }
        }
    } else if let Some(obj) = indexer_raw.as_object() {
        for (k, v) in obj {
            if let (Ok(code), Some(val)) = (k.parse::<u32>(), v.as_i64()) {
                indexer.insert(code, val);
            }
        }
    }

    let style_path = assets_dir.join(format!("{}.json", voice_style));
    if !style_path.exists() {
        return Err(format!("Voice style file {}.json not found", voice_style));
    }
    let style_str = fs::read_to_string(&style_path).map_err(|e| e.to_string())?;
    let style_json: JsonValue = serde_json::from_str(&style_str).map_err(|e| e.to_string())?;

    let parse_dims = |val: &JsonValue| -> Result<Vec<usize>, String> {
        val["dims"]
            .as_array()
            .ok_or_else(|| "Invalid dims format".to_string())?
            .iter()
            .map(|v| v.as_u64().map(|n| n as usize).ok_or_else(|| "Invalid dim item".to_string()))
            .collect()
    };

    fn extract_f32_data(val: &JsonValue) -> Vec<f32> {
        let mut result = Vec::new();
        if let Some(arr) = val.as_array() {
            for item in arr {
                if let Some(n) = item.as_f64() {
                    result.push(n as f32);
                } else if item.is_array() {
                    result.extend(extract_f32_data(item));
                }
            }
        }
        result
    }

    let ttl_dims = parse_dims(&style_json["style_ttl"])?;
    let dp_dims = parse_dims(&style_json["style_dp"])?;

    let ttl_data = extract_f32_data(&style_json["style_ttl"]["data"]);
    let dp_data = extract_f32_data(&style_json["style_dp"]["data"]);

    let style_ttl = Array3::from_shape_vec((1, ttl_dims[1], ttl_dims[2]), ttl_data)
        .map_err(|e| format!("Invalid ttl shape: {}", e))?;
    let style_dp = Array3::from_shape_vec((1, dp_dims[1], dp_dims[2]), dp_data)
        .map_err(|e| format!("Invalid dp shape: {}", e))?;

    let create_session = |model_name: &str| -> Result<Session, String> {
        let path = assets_dir.join(format!("{}.onnx", model_name));
        SessionBuilder::new()
            .map_err(|e| e.to_string())?
            .commit_from_file(&path)
            .map_err(|e| format!("Failed to load ONNX model {}: {}", model_name, e))
    };

    let dp_session = create_session("duration_predictor")?;
    let text_enc_session = create_session("text_encoder")?;
    let vector_est_session = create_session("vector_estimator")?;
    let vocoder_session = create_session("vocoder")?;

    let state = SupertonicState {
        dp_session,
        text_enc_session,
        vector_est_session,
        vocoder_session,
        indexer,
        style_ttl,
        style_dp,
        _current_style_name: voice_style,
        sample_rate,
        base_chunk_size,
        chunk_compress_factor,
        latent_dim,
    };

    let mut lock = SUPERTONIC_ENGINE.lock();
    *lock = Some(state);

    Ok(true)
}

pub async fn release_supertonic_engine() -> Result<(), String> {
    let mut lock = SUPERTONIC_ENGINE.lock();
    *lock = None;
    Ok(())
}

pub async fn synthesize_supertonic(
    text: String,
    lang: String,
    speed: f64,
    denoise_steps: i32,
) -> Result<Vec<u8>, String> {
    let mut lock = SUPERTONIC_ENGINE.lock();
    let state = lock
        .as_mut()
        .ok_or_else(|| "Supertonic engine is not initialized".to_string())?;

    let clean_text = text.trim();
    if clean_text.is_empty() {
        return Err("Text is empty".to_string());
    }

    let target_lang = if is_valid_lang(&lang) { lang } else { "vi".to_string() };
    let max_len = if target_lang == "ko" || target_lang == "ja" { 120 } else { 300 };

    let chunks = chunk_text(clean_text, max_len);
    let mut all_wav_samples: Vec<f32> = Vec::new();

    let silence_padding_size = (0.3 * state.sample_rate as f64).floor() as usize;
    let silence_padding = vec![0.0f32; silence_padding_size];

    for (i, chunk) in chunks.iter().enumerate() {
        let (text_ids, text_mask) = process_unicode_indexer(&[chunk.clone()], &[target_lang.clone()], &state.indexer)?;

        let text_ids_val = array2_i64_to_value(text_ids.clone())?;
        let style_dp_val = array3_f32_to_value(state.style_dp.clone())?;
        let text_mask_val = array3_f32_to_value(text_mask.clone())?;

        let dp_outputs = state
            .dp_session
            .run(ort::inputs![
                "text_ids" => text_ids_val,
                "style_dp" => style_dp_val,
                "text_mask" => text_mask_val
            ])
            .map_err(|e| format!("Duration predictor failed: {}", e))?;

        let (dur_shape, dur_slice) = dp_outputs[0].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
        let scaled_dur: Vec<f32> = dur_slice.iter().map(|&d| d / speed as f32).collect();

        let text_ids_val2 = array2_i64_to_value(text_ids)?;
        let style_ttl_val = array3_f32_to_value(state.style_ttl.clone())?;
        let text_mask_val2 = array3_f32_to_value(text_mask.clone())?;

        let text_enc_outputs = state
            .text_enc_session
            .run(ort::inputs![
                "text_ids" => text_ids_val2,
                "style_ttl" => style_ttl_val,
                "text_mask" => text_mask_val2
            ])
            .map_err(|e| format!("Text encoder failed: {}", e))?;

        let (mut noisy_latent, latent_mask) = sample_noisy_latent(
            &scaled_dur,
            state.sample_rate,
            state.base_chunk_size,
            state.chunk_compress_factor,
            state.latent_dim,
        );

        let steps = if denoise_steps <= 0 { 16 } else { denoise_steps as usize };
        let total_step_arr = Array1::from_elem(1, steps as f32);

        for step in 0..steps {
            let current_step_arr = Array1::from_elem(1, step as f32);
            let current_step_val = array1_f32_to_value(current_step_arr)?;
            let total_step_val_loop = array1_f32_to_value(total_step_arr.clone())?;
            let latent_mask_val_loop = array3_f32_to_value(latent_mask.clone())?;
            let noisy_latent_val = array3_f32_to_value(noisy_latent.clone())?;
            let style_ttl_val_loop = array3_f32_to_value(state.style_ttl.clone())?;
            let text_mask_val_loop = array3_f32_to_value(text_mask.clone())?;

            let (text_emb_shape, text_emb_slice) = text_enc_outputs[0].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
            let text_emb_arr = Array3::from_shape_vec(
                (text_emb_shape[0] as usize, text_emb_shape[1] as usize, text_emb_shape[2] as usize),
                text_emb_slice.to_vec()
            ).map_err(|e| e.to_string())?;
            let text_emb_val_loop = array3_f32_to_value(text_emb_arr)?;

            let vector_outputs = state
                .vector_est_session
                .run(ort::inputs![
                    "noisy_latent" => noisy_latent_val,
                    "text_emb" => text_emb_val_loop,
                    "style_ttl" => style_ttl_val_loop,
                    "text_mask" => text_mask_val_loop,
                    "latent_mask" => latent_mask_val_loop,
                    "total_step" => total_step_val_loop,
                    "current_step" => current_step_val
                ])
                .map_err(|e| format!("Vector estimator step {} failed: {}", step, e))?;

            let (shape, denoised_slice) = vector_outputs[0].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;

            let mut idx = 0;
            for d in 0..shape[1] as usize {
                for t in 0..shape[2] as usize {
                    noisy_latent[[0, d, t]] = denoised_slice[idx];
                    idx += 1;
                }
            }
        }

        let final_latent_val = array3_f32_to_value(noisy_latent)?;
        let vocoder_outputs = state
            .vocoder_session
            .run(ort::inputs!["latent" => final_latent_val])
            .map_err(|e| format!("Vocoder failed: {}", e))?;

        let (_wav_shape, wav_slice) = vocoder_outputs[0].try_extract_tensor::<f32>().map_err(|e| e.to_string())?;
        let chunk_samples: Vec<f32> = wav_slice.to_vec();

        if i > 0 {
            all_wav_samples.extend_from_slice(&silence_padding);
        }
        all_wav_samples.extend_from_slice(&chunk_samples);
    }

    let wav_bytes = encode_wav(&all_wav_samples, state.sample_rate);
    Ok(wav_bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_preprocess_text_vietnamese() {
        let result = preprocess_text("Xin chào thế giới", "vi").unwrap();
        let expected = format!("<vi>{}</vi>", "Xin chào thế giới.".nfkd().collect::<String>());
        assert_eq!(result, expected);
    }

    #[test]
    fn test_preprocess_text_cleans_emoji() {
        let result = preprocess_text("Hello 😊 world!", "en").unwrap();
        assert!(result.contains("Hello"));
        assert!(!result.contains("😊"));
    }

    #[test]
    fn test_preprocess_text_adds_period() {
        let result = preprocess_text("No ending punctuation", "en").unwrap();
        assert!(result.ends_with(".</en>"));
    }

    #[test]
    fn test_detect_language_vietnamese() {
        assert_eq!(detect_language("Xin chào các bạn"), "vi");
    }

    #[test]
    fn test_detect_language_korean() {
        assert_eq!(detect_language("안녕하세요"), "ko");
    }

    #[test]
    fn test_detect_language_japanese() {
        assert_eq!(detect_language("こんにちは"), "ja");
    }

    #[test]
    fn test_detect_language_default_english() {
        assert_eq!(detect_language("Hello World"), "en");
    }

    #[test]
    fn test_wav_encoder_header() {
        let samples = vec![0.0f32; 100];
        let wav = encode_wav(&samples, 22050);
        assert_eq!(&wav[0..4], b"RIFF");
        assert_eq!(&wav[8..12], b"WAVE");
        assert_eq!(&wav[36..40], b"data");
    }

    #[test]
    fn test_wav_encoder_correct_size() {
        let samples = vec![0.5f32; 1000];
        let wav = encode_wav(&samples, 22050);
        assert_eq!(wav.len(), 2044);
    }

    #[test]
    fn test_sample_noisy_latent_dimensions() {
        let duration = vec![1.0f32];
        let (noisy_latent, latent_mask) = sample_noisy_latent(&duration, 22050, 240, 4, 64);
        assert_eq!(noisy_latent.shape()[0], 1);
        assert_eq!(latent_mask.shape()[0], 1);
    }

    #[test]
    fn test_chunk_text_long_text() {
        let sentence = "Đây là một câu văn dài có dấu chấm ở cuối để kiểm tra việc phân đoạn văn bản. ";
        let text = sentence.repeat(15);
        let chunks = chunk_text(&text, 300);
        assert!(chunks.len() > 1);
        for chunk in &chunks {
            assert!(chunk.len() <= 300);
        }
    }

    #[tokio::test]
    async fn test_full_synthesis_with_auto_download() {
        println!("Starting full Supertonic integration test...");
        let temp_dir = std::env::temp_dir().join("supertonic_test_fixtures");
        let base_dir_str = temp_dir.to_str().unwrap().to_string();

        println!("Downloading model files if needed to {}...", base_dir_str);
        let download_result = download_supertonic_models(base_dir_str.clone()).await;
        assert!(download_result.is_ok(), "Failed to download model files: {:?}", download_result.err());
        assert!(check_supertonic_model_exists(base_dir_str.clone()), "Model files should exist");

        println!("Initializing Supertonic engine with voice style M1...");
        let init_result = init_supertonic_engine(base_dir_str.clone(), "M1".to_string()).await;
        assert!(init_result.is_ok(), "Failed to init engine: {:?}", init_result.err());
        assert!(init_result.unwrap(), "Engine init should return true");

        println!("Synthesizing Vietnamese text...");
        let text = "Xin chào! Đây là bài kiểm tra tổng hợp giọng nói tự động từ Rust Supertonic ONNX Engine.";
        let wav_result = synthesize_supertonic(text.to_string(), "vi".to_string(), 1.05, 16).await;
        assert!(wav_result.is_ok(), "Failed to synthesize text: {:?}", wav_result.err());

        let wav_bytes = wav_result.unwrap();
        println!("Synthesis complete! Generated WAV size: {} bytes", wav_bytes.len());
        assert!(wav_bytes.len() > 44, "WAV size should be greater than header size (44 bytes)");
        assert_eq!(&wav_bytes[0..4], b"RIFF");
        assert_eq!(&wav_bytes[8..12], b"WAVE");

        let release_result = release_supertonic_engine().await;
        assert!(release_result.is_ok());
    }
}
