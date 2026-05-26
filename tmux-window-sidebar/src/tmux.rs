use std::process::Command;

use crate::state::{AgentInfo, AgentType, PaneStatus, WindowCard};

/// Query all tmux sessions
pub fn tmux_output(args: &[&str]) -> Result<String, String> {
    let output = Command::new("tmux")
        .args(args)
        .output()
        .map_err(|e| format!("tmux command failed: {e}"))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        // tmux often returns errors when not in a session; just return empty
        if stderr.contains("no server running") || stderr.contains("no session") {
            return Ok(String::new());
        }
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim_end().to_string())
}

/// Get the list of tmux session names
pub fn list_sessions() -> Vec<String> {
    let output = tmux_output(&["list-sessions", "-F", "#{session_name}"]).unwrap_or_default();
    if output.is_empty() {
        return Vec::new();
    }
    output.lines().map(String::from).collect()
}

/// Get the currently active session name
pub fn active_session() -> Option<String> {
    tmux_output(&["display-message", "-p", "#{session_name}"]).ok()
}

/// Get the currently active window id
pub fn active_window_id() -> Option<String> {
    tmux_output(&["display-message", "-p", "#{window_id}"]).ok()
}

/// Query all windows across all sessions and build WindowCards.
///
/// For each window, we list all panes and find the "content" pane — the one
/// that has `@agent` set, or if none do, the first non-sidebar pane.
/// The sidebar pane (running `tmux-window-sidebar`) is excluded from cards.
pub fn query_windows() -> Vec<WindowCard> {
    let sessions = list_sessions();
    let current_session = active_session();
    let current_window_id = active_window_id();

    let mut cards = Vec::new();

    for session in &sessions {
        // List windows in this session
        let win_fmt = "#{window_id}:#{window_index}:#{window_name}:#{window_zoomed_flag}";
        let win_output = match tmux_output(&[
            "list-windows",
            "-t", session,
            "-F", win_fmt,
        ]) {
            Ok(o) if !o.is_empty() => o,
            _ => continue,
        };

        for win_line in win_output.lines() {
            let win_parts: Vec<&str> = win_line.splitn(4, ':').collect();
            if win_parts.len() < 4 {
                continue;
            }

            let window_id = win_parts[0].to_string();
            let window_index: usize = win_parts[1].parse().unwrap_or(0);
            let raw_window_name = win_parts[2].to_string();
            let window_name = strip_icon_prefix(&raw_window_name);
            let zoomed = win_parts[3].trim() == "1";

            let is_active = current_session.as_deref() == Some(session.as_str())
                && current_window_id.as_deref() == Some(window_id.as_str());

            // List all panes in this window to find the content pane
            let pane_fmt = "#{pane_id}:#{pane_current_command}:#{pane_current_path}";
            let pane_output = match tmux_output(&[
                "list-panes",
                "-t", &window_id,
                "-F", pane_fmt,
            ]) {
                Ok(o) if !o.is_empty() => o,
                _ => continue,
            };

            // Find the best pane: prefer one with @agent set, skip sidebar panes
            let mut best_pane_id = String::new();
            let mut best_pane_path = String::new();
            let mut best_has_agent = false;

            for pane_line in pane_output.lines() {
                let pane_parts: Vec<&str> = pane_line.splitn(3, ':').collect();
                if pane_parts.len() < 3 {
                    continue;
                }

                let pane_id = pane_parts[0].to_string();
                let pane_cmd = pane_parts[1].to_string();
                let pane_path = pane_parts[2].to_string();

                // Skip sidebar panes (our own process)
                // pane_current_command is truncated to 15 chars by tmux, so match prefix
                if pane_cmd.starts_with("tmux-window-sid") {
                    continue;
                }

                let has_agent = !get_pane_option(&pane_id, "@agent").is_empty();

                // Prefer panes with @agent set; otherwise take the first non-sidebar pane
                if has_agent && !best_has_agent {
                    best_pane_id = pane_id;
                    best_pane_path = pane_path;
                    best_has_agent = true;
                } else if best_pane_id.is_empty() {
                    best_pane_id = pane_id;
                    best_pane_path = pane_path;
                }
            }

            if best_pane_id.is_empty() {
                // No content pane found (shouldn't happen normally)
                continue;
            }

            let folder = std::path::Path::new(&best_pane_path)
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_default();

            // Query pane user options for agent info
            let agent = query_agent_info(&best_pane_id);

            // Query git branch
            let git_branch = query_git_branch(&best_pane_path);

            cards.push(WindowCard {
                window_id,
                window_index,
                window_name,
                window_active: is_active,
                zoomed,
                session_name: session.clone(),
                folder,
                git_branch,
                agent,
            });
        }
    }

    cards
}

/// Query agent info from tmux pane user options
fn query_agent_info(pane_id: &str) -> Option<AgentInfo> {
    let agent_type_str = get_pane_option(pane_id, "@agent");
    if agent_type_str.is_empty() {
        return None;
    }

    let status_str = get_pane_option(pane_id, "@pane_status");
    let prompt = get_pane_option(pane_id, "@pane_prompt");
    let permission_mode = get_pane_option(pane_id, "@pane_permission_mode");
    let session_id = {
        let s = get_pane_option(pane_id, "@pane_session_id");
        if s.is_empty() { None } else { Some(s) }
    };
    let session_name = {
        let s = get_pane_option(pane_id, "@pane_name");
        if s.is_empty() { None } else { Some(s) }
    };
    let wait_reason = get_pane_option(pane_id, "@pane_wait_reason");
    let started_at = {
        let s = get_pane_option(pane_id, "@pane_started_at");
        s.parse::<u64>().ok()
    };
    let subagents_str = get_pane_option(pane_id, "@pane_subagents");
    let subagents: Vec<String> = if subagents_str.is_empty() {
        Vec::new()
    } else {
        subagents_str.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect()
    };

    Some(AgentInfo {
        agent_type: AgentType::from(agent_type_str.as_str()),
        status: PaneStatus::from(status_str.as_str()),
        prompt,
        permission_mode,
        session_id,
        session_name,
        wait_reason,
        subagents,
        started_at,
    })
}

/// Get a tmux pane user option value.
/// tmux show-option returns "<option> <value>", so we parse out just the value.
pub fn get_pane_option(pane_id: &str, option: &str) -> String {
    let raw = tmux_output(&["show-option", "-p", "-t", pane_id, "-q", option]).unwrap_or_default();
    // Output format: "@agent claude" — split on first space to get the value
    raw.splitn(2, ' ').nth(1).unwrap_or("").trim().to_string()
}

/// Set a tmux pane user option
pub fn set_pane_option(pane_id: &str, option: &str, value: &str) -> Result<(), String> {
    let status = Command::new("tmux")
        .args(["set-option", "-p", "-t", pane_id, option, value])
        .status()
        .map_err(|e| format!("tmux set-option failed: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("tmux set-option {option}={value} failed"))
    }
}

/// Unset a tmux pane user option
pub fn unset_pane_option(pane_id: &str, option: &str) -> Result<(), String> {
    let status = Command::new("tmux")
        .args(["set-option", "-p", "-t", pane_id, "-u", option])
        .status()
        .map_err(|e| format!("tmux set-option -u failed: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("tmux unset-option {option} failed"))
    }
}

/// Set a tmux window option
pub fn set_window_option(pane_id: &str, option: &str, value: &str) -> Result<(), String> {
    let status = Command::new("tmux")
        .args(["set-window-option", "-t", pane_id, option, value])
        .status()
        .map_err(|e| format!("tmux set-window-option failed: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("tmux set-window-option {option}={value} failed"))
    }
}

/// Unset a tmux window option
pub fn unset_window_option(pane_id: &str, option: &str) -> Result<(), String> {
    let status = Command::new("tmux")
        .args(["set-window-option", "-t", pane_id, "-u", option])
        .status()
        .map_err(|e| format!("tmux set-window-option -u failed: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("tmux unset-window-option {option} failed"))
    }
}

/// Query git branch for a directory
fn query_git_branch(path: &str) -> Option<String> {
    let output = Command::new("git")
        .args(["-C", path, "branch", "--show-current"])
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let branch = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if branch.is_empty() {
        None
    } else {
        Some(branch)
    }
}

/// Get a tmux global user option
pub fn get_global_option(option: &str) -> String {
    tmux_output(&["show-option", "-g", "-q", option]).unwrap_or_default()
}

/// Strip leading icon prefix (⚡, ✓, ❓, ✕) from a window name.
/// These are legacy prefixes from the old tmux-agent-icon system.
fn strip_icon_prefix(name: &str) -> String {
    let trimmed = name.trim();
    for prefix in &["⚡ ", "✓ ", "❓ ", "✕ "] {
        if trimmed.starts_with(prefix) {
            return trimmed[prefix.len()..].to_string();
        }
    }
    trimmed.to_string()
}

/// Rename a tmux window
pub fn rename_window(pane_id: &str, name: &str) -> Result<(), String> {
    let status = Command::new("tmux")
        .args(["rename-window", "-t", pane_id, name])
        .status()
        .map_err(|e| format!("tmux rename-window failed: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("tmux rename-window to '{name}' failed"))
    }
}

/// Check if a window is currently focused
pub fn is_window_active(pane_id: &str) -> bool {
    tmux_output(&["display-message", "-t", pane_id, "-p", "#{window_active}"])
        .map(|s| s.trim() == "1")
        .unwrap_or(false)
}

/// Get TMUX_PANE environment variable
pub fn current_pane_id() -> Option<String> {
    std::env::var("TMUX_PANE").ok()
}

/// Switch to a tmux window by window id
pub fn switch_to_window(window_id: &str) -> Result<(), String> {
    let status = Command::new("tmux")
        .args(["select-window", "-t", window_id])
        .status()
        .map_err(|e| format!("tmux select-window failed: {e}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("tmux select-window to '{window_id}' failed"))
    }
}

/// Get the terminal width from tmux
pub fn terminal_width() -> u16 {
    tmux_output(&["display-message", "-p", "#{window_width}"])
        .ok()
        .and_then(|s| s.trim().parse::<u16>().ok())
        .unwrap_or(120)
}

/// Get the terminal height from tmux
pub fn terminal_height() -> u16 {
    tmux_output(&["display-message", "-p", "#{window_height}"])
        .ok()
        .and_then(|s| s.trim().parse::<u16>().ok())
        .unwrap_or(40)
}