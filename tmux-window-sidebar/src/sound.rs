use std::path::PathBuf;
use std::process::Command;
use std::sync::atomic::{AtomicI64, Ordering};

/// Timestamp of the last "done" sound played (for debounce)
static LAST_DONE_SOUND: AtomicI64 = AtomicI64::new(0);

/// Debounce interval in milliseconds
const DONE_DEBOUNCE_MS: u64 = 3000;

/// Play the "done" sound (agent finished working)
pub fn play_done_sound() {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64;

    let last = LAST_DONE_SOUND.load(Ordering::Relaxed);
    if now - last < DONE_DEBOUNCE_MS as i64 {
        // Debounced
        return;
    }
    LAST_DONE_SOUND.store(now, Ordering::Relaxed);

    let sound_list = get_tmux_option("@agent-sound", "Blow");
    play_random_sound(&sound_list);
}

/// Play the "ask" sound (agent needs user input)
pub fn play_ask_sound() {
    let sound_list = get_tmux_option("@agent-ask-sound", "NaviHey,NaviListen,NaviHello,NaviFairy,NaviWatchOut,NaviLook");
    play_random_sound(&sound_list);
}

/// Get a tmux global option value
fn get_tmux_option(option: &str, default: &str) -> String {
    let output = Command::new("tmux")
        .args(["show-option", "-g", "-q", option])
        .output();

    match output {
        Ok(o) => {
            let val = String::from_utf8_lossy(&o.stdout).trim().to_string();
            if val.is_empty() { default.to_string() } else { val }
        }
        Err(_) => default.to_string(),
    }
}

/// Pick a random sound from a comma-separated list and play it
fn play_random_sound(sound_list: &str) {
    let sounds: Vec<&str> = sound_list.split(',').map(|s| s.trim()).collect();
    if sounds.is_empty() {
        return;
    }

    let idx = rand_index(sounds.len());
    let picked = sounds[idx];

    if picked == "none" {
        return;
    }

    let path = resolve_sound_path(picked);
    if let Some(path) = path {
        let _ = Command::new("afplay").arg(&path).spawn();
    }
}

/// Resolve a sound name to a file path:
/// 1. ~/.dotfiles/sounds/<name>.{mp3,aiff,wav,m4a}
/// 2. /System/Library/Sounds/<name>.aiff
/// 3. Absolute path
fn resolve_sound_path(name: &str) -> Option<String> {
    let home = dirs::home_dir()?;
    let custom_dir = PathBuf::from(&home).join(".dotfiles").join("sounds");

    // Check custom sounds directory
    for ext in &["mp3", "aiff", "wav", "m4a"] {
        let path = custom_dir.join(format!("{name}.{ext}"));
        if path.exists() {
            return path.to_str().map(|s| s.to_string());
        }
    }

    // Check system sounds
    let system_path = PathBuf::from("/System/Library/Sounds").join(format!("{name}.aiff"));
    if system_path.exists() {
        return system_path.to_str().map(|s| s.to_string());
    }

    // Check if it's an absolute path
    let abs_path = PathBuf::from(name);
    if abs_path.exists() {
        return abs_path.to_str().map(|s| s.to_string());
    }

    None
}

/// Simple random index (no external rand dependency)
fn rand_index(max: usize) -> usize {
    use std::time::SystemTime;
    let nanos = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap_or_default()
        .subsec_nanos() as usize;
    nanos % max
}