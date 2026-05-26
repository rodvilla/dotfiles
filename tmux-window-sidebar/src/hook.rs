use std::io::{self, Read};
use std::process::Command;

use crate::state::{AgentType, HookData, HookEvent};
use crate::tmux;

/// Handle the `hook` subcommand: set tmux pane options based on agent event
pub fn handle_hook(agent: &str, event: &str) -> Result<(), String> {
    // "internal refresh" is sent by tmux hooks to trigger a TUI redraw
    if agent == "internal" && event == "refresh" {
        return send_refresh_signal();
    }

    let agent_type = AgentType::from(agent);
    let hook_event = HookEvent::from(event);

    // Read JSON from stdin
    let mut json_str = String::new();
    io::stdin()
        .read_to_string(&mut json_str)
        .map_err(|e| format!("Failed to read stdin: {e}"))?;

    let data: HookData = if json_str.trim().is_empty() {
        HookData::default()
    } else {
        serde_json::from_str(&json_str).unwrap_or_default()
    };

    // Get the current pane ID from TMUX_PANE env
    let pane_id = match std::env::var("TMUX_PANE") {
        Ok(p) => p,
        Err(_) => return Err("TMUX_PANE not set".to_string()),
    };

    // Check if window is active (focused) — used for sound suppression
    let window_active = tmux::is_window_active(&pane_id);

    // Defensive: set @agent on every event if not already set.
    // This handles the case where session-start was missed (e.g., plugin PATH issue).
    let current_agent = tmux::get_pane_option(&pane_id, "@agent");
    if current_agent.is_empty() {
        let _ = tmux::set_pane_option(&pane_id, "@agent", &agent_type.to_string());
    }

    match hook_event {
        HookEvent::SessionStart => {
            tmux::set_pane_option(&pane_id, "@agent", &agent_type.to_string())?;
            tmux::set_pane_option(&pane_id, "@pane_status", "running")?;

            if let Some(ref cwd) = data.cwd {
                tmux::set_pane_option(&pane_id, "@pane_cwd", cwd)?;
            }
            if let Some(ref session_id) = data.session_id {
                tmux::set_pane_option(&pane_id, "@pane_session_id", session_id)?;
            }
            if let Some(ref perm) = data.permission_mode {
                tmux::set_pane_option(&pane_id, "@pane_permission_mode", perm)?;
            }

            // Trigger session name resolution in background
            if let Some(ref session_id) = data.session_id {
                resolve_session_name_async(&pane_id, &agent_type, session_id);
            }
        }

        HookEvent::SessionEnd => {
            // Clear all pane metadata
            clear_pane_meta(&pane_id)?;
        }

        HookEvent::UserPromptSubmit => {
            tmux::set_pane_option(&pane_id, "@pane_status", "running")?;
            tmux::set_pane_option(&pane_id, "@pane_attention", "")?;

            if let Some(ref prompt) = data.prompt {
                let truncated = truncate_str(prompt, 80);
                tmux::set_pane_option(&pane_id, "@pane_prompt", &truncated)?;
            }
            tmux::set_pane_option(&pane_id, "@pane_prompt_source", "user")?;
            tmux::set_pane_option(
                &pane_id,
                "@pane_started_at",
                &std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs()
                    .to_string(),
            )?;

            // Colorize window name green for running (only if not focused)
            if !window_active {
                update_window_status(&pane_id, Some("#9ece6a"));
            } else {
                update_window_status(&pane_id, None);
            }
        }

        HookEvent::Notification => {
            tmux::set_pane_option(&pane_id, "@pane_status", "waiting")?;
            tmux::set_pane_option(&pane_id, "@pane_attention", "1")?;

            if let Some(ref reason) = data.wait_reason {
                tmux::set_pane_option(&pane_id, "@pane_wait_reason", reason)?;
            }

            // Colorize window name amber for waiting (only if not focused)
            if !window_active {
                update_window_status(&pane_id, Some("#e0af68"));

                // Play ask sound only when window is not focused
                crate::sound::play_ask_sound();
            }
        }

        HookEvent::Stop => {
            tmux::set_pane_option(&pane_id, "@pane_status", "idle")?;
            tmux::set_pane_option(&pane_id, "@pane_attention", "")?;
            tmux::set_pane_option(&pane_id, "@pane_prompt", "")?;
            tmux::set_pane_option(&pane_id, "@pane_wait_reason", "")?;

            // Reset window status style (idle = default colors)
            update_window_status(&pane_id, None);

            // No sound on idle — sounds only play when agent needs attention (ask/permission)
        }

        HookEvent::StopFailure => {
            tmux::set_pane_option(&pane_id, "@pane_status", "error")?;
            tmux::set_pane_option(&pane_id, "@pane_attention", "1")?;

            // Colorize window name red for error (only if not focused)
            if !window_active {
                update_window_status(&pane_id, Some("#f7768e"));

                // Play ask sound for errors that need attention
                crate::sound::play_ask_sound();
            } else {
                update_window_status(&pane_id, None);
            }
        }

        HookEvent::PermissionDenied => {
            tmux::set_pane_option(&pane_id, "@pane_attention", "1")?;
        }

        HookEvent::CwdChanged => {
            if let Some(ref cwd) = data.cwd {
                tmux::set_pane_option(&pane_id, "@pane_cwd", cwd)?;
            }
        }

        HookEvent::SubagentStart => {
            // Append to subagent list
            let current = tmux::get_pane_option(&pane_id, "@pane_subagents");
            let subagent_id = data.session_id.as_deref().unwrap_or("unknown");
            let new_list = if current.is_empty() {
                subagent_id.to_string()
            } else {
                format!("{current},{subagent_id}")
            };
            tmux::set_pane_option(&pane_id, "@pane_subagents", &new_list)?;
        }

        HookEvent::SubagentStop => {
            // Remove from subagent list
            let current = tmux::get_pane_option(&pane_id, "@pane_subagents");
            let subagent_id = data.session_id.as_deref().unwrap_or("unknown");
            let new_list = current
                .split(',')
                .map(|s| s.trim())
                .filter(|s| *s != subagent_id && !s.is_empty())
                .collect::<Vec<_>>()
                .join(",");
            tmux::set_pane_option(&pane_id, "@pane_subagents", &new_list)?;
        }

        HookEvent::ActivityLog => {
            // Future: write activity log
        }

        HookEvent::TaskCreated | HookEvent::TaskCompleted => {
            // Future: progress bar / notification
        }

        HookEvent::TeammateIdle => {
            // Future: notification
        }

        HookEvent::WorktreeCreate | HookEvent::WorktreeRemove => {
            // Future: worktree lifecycle
        }
    }

    Ok(())
}

/// Clear all pane metadata (on session end)
fn clear_pane_meta(pane_id: &str) -> Result<(), String> {
    let options = [
        "@agent",
        "@pane_status",
        "@pane_prompt",
        "@pane_prompt_source",
        "@pane_cwd",
        "@pane_permission_mode",
        "@pane_session_id",
        "@pane_started_at",
        "@pane_wait_reason",
        "@pane_attention",
        "@pane_worktree_name",
        "@pane_worktree_branch",
        "@pane_subagents",
        "@pane_bg_cmd",
        "@pane_name",
    ];

    for opt in &options {
        let _ = tmux::unset_pane_option(pane_id, opt);
    }

    Ok(())
}

/// Update window name (strip any legacy icon prefix) and set status color.
/// Instead of prepending icons to window names (which duplicates the sidebar's
/// row-4 status icon), we colorize the window name via `window-status-style`.
/// Active (focused) windows get their style reset to default since the user
/// can see the agent directly.
fn update_window_status(pane_id: &str, color: Option<&str>) {
    // Strip any legacy icon prefix (⚡, ✓, ❓, ✕) from the window name
    let current = tmux::tmux_output(&["display-message", "-t", pane_id, "-p", "#{window_name}"])
        .unwrap_or_default();
    let clean = strip_icon_prefix(&current);

    // Rename to clean name (no icon prefix)
    if clean != current.trim() {
        let _ = tmux::rename_window(pane_id, &clean);
    }

    // Set or reset window status color
    if let Some(fg) = color {
        let _ = tmux::set_window_option(pane_id, "window-status-style", &format!("fg={fg},bg=colour235"));
    } else {
        let _ = tmux::unset_window_option(pane_id, "window-status-style");
    }
}

/// Strip leading icon prefix (⚡, ✓, ❓, ✕) from a window name.
fn strip_icon_prefix(name: &str) -> String {
    let trimmed = name.trim();
    for prefix in &["⚡ ", "✓ ", "❓ ", "✕ "] {
        if trimmed.starts_with(prefix) {
            return trimmed[prefix.len()..].to_string();
        }
    }
    trimmed.to_string()
}

/// Spawn a background task to resolve session name
fn resolve_session_name_async(pane_id: &str, agent_type: &AgentType, session_id: &str) {
    let pane_id = pane_id.to_string();
    let agent_type = agent_type.clone();
    let session_id = session_id.to_string();

    std::thread::spawn(move || {
        let name = crate::session::resolve_session_name(&agent_type, &session_id);
        if let Some(name) = name {
            let _ = tmux::set_pane_option(&pane_id, "@pane_name", &name);
            let _ = tmux::rename_window(&pane_id, &name);
        }
    });
}

fn truncate_str(s: &str, max_len: usize) -> String {
    if s.len() <= max_len {
        s.to_string()
    } else {
        format!("{}…", &s[..max_len.saturating_sub(1)])
    }
}

/// Send SIGUSR1 to the running tmux-window-sidebar TUI process to trigger a refresh.
/// Uses pgrep -f to match only the TUI process (running "tmux-window-sidebar run"),
/// not other invocations like "hook" or "focus-content".
fn send_refresh_signal() -> Result<(), String> {
    // Find the TUI process specifically (it runs with "run" subcommand)
    let output = Command::new("pgrep")
        .args(["-f", "tmux-window-sidebar run"])
        .output()
        .map_err(|e| format!("pgrep failed: {e}"))?;

    let pids = String::from_utf8_lossy(&output.stdout);
    for pid in pids.lines() {
        let pid = pid.trim();
        if pid.is_empty() {
            continue;
        }
        let _ = Command::new("kill")
            .args(["-USR1", pid])
            .status();
    }

    Ok(())
}