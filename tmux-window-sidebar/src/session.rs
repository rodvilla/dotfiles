use std::path::PathBuf;

use crate::state::AgentType;

/// Resolve a session name from the agent's session storage
pub fn resolve_session_name(agent_type: &AgentType, session_id: &str) -> Option<String> {
    match agent_type {
        AgentType::Claude => resolve_claude_session_name(session_id),
        AgentType::OpenCode => resolve_opencode_session_name(session_id),
        AgentType::Codex => resolve_codex_session_name(session_id),
        AgentType::Unknown => None,
    }
}

/// Claude: scan ~/.claude/sessions/<sessionID>.json for the name field
fn resolve_claude_session_name(session_id: &str) -> Option<String> {
    let home = dirs::home_dir()?;
    let path = PathBuf::from(home)
        .join(".claude")
        .join("sessions")
        .join(format!("{session_id}.json"));

    if !path.exists() {
        return None;
    }

    let content = std::fs::read_to_string(&path).ok()?;
    let json: serde_json::Value = serde_json::from_str(&content).ok()?;
    json.get("name")?.as_str().map(|s| s.to_string())
}

/// OpenCode: session name resolution would need the OpenCode API
/// For now, return None — the OpenCode plugin handles this directly
fn resolve_opencode_session_name(_session_id: &str) -> Option<String> {
    None
}

/// Codex: no known session storage
fn resolve_codex_session_name(_session_id: &str) -> Option<String> {
    None
}