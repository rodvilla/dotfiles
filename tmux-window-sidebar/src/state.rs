use serde::Deserialize;
use std::fmt;

// --- PaneStatus ---

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub enum PaneStatus {
    Running,
    Background,
    Waiting,
    #[default]
    Idle,
    Error,
    Unknown,
}

impl fmt::Display for PaneStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PaneStatus::Running => write!(f, "running"),
            PaneStatus::Background => write!(f, "background"),
            PaneStatus::Waiting => write!(f, "waiting"),
            PaneStatus::Idle => write!(f, "idle"),
            PaneStatus::Error => write!(f, "error"),
            PaneStatus::Unknown => write!(f, "unknown"),
        }
    }
}

impl From<&str> for PaneStatus {
    fn from(s: &str) -> Self {
        match s {
            "running" => PaneStatus::Running,
            "background" => PaneStatus::Background,
            "waiting" => PaneStatus::Waiting,
            "idle" => PaneStatus::Idle,
            "error" => PaneStatus::Error,
            _ => PaneStatus::Unknown,
        }
    }
}

// --- AgentType ---

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub enum AgentType {
    Claude,
    Codex,
    #[default]
    OpenCode,
    Unknown,
}

impl fmt::Display for AgentType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AgentType::Claude => write!(f, "claude"),
            AgentType::Codex => write!(f, "codex"),
            AgentType::OpenCode => write!(f, "opencode"),
            AgentType::Unknown => write!(f, "unknown"),
        }
    }
}

impl From<&str> for AgentType {
    fn from(s: &str) -> Self {
        match s {
            "claude" => AgentType::Claude,
            "codex" => AgentType::Codex,
            "opencode" => AgentType::OpenCode,
            _ => AgentType::Unknown,
        }
    }
}

// --- AgentInfo ---

#[derive(Debug, Clone, Default)]
#[allow(dead_code)]
pub struct AgentInfo {
    pub agent_type: AgentType,
    pub status: PaneStatus,
    pub prompt: String,
    pub permission_mode: String,
    pub session_id: Option<String>,
    pub session_name: Option<String>,
    pub wait_reason: String,
    pub subagents: Vec<String>,
    pub started_at: Option<u64>,
}

// --- WindowCard ---

#[derive(Debug, Clone, Default)]
#[allow(dead_code)]
pub struct WindowCard {
    pub window_id: String,
    pub window_index: usize,
    pub window_name: String,
    pub window_active: bool,
    pub zoomed: bool,
    pub session_name: String,
    pub folder: String,
    pub git_branch: Option<String>,
    pub agent: Option<AgentInfo>,
}

// --- Display Mode ---

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Mode {
    #[default]
    Popup,
    Sidebar,
}

// --- AppState ---

#[derive(Debug, Clone, Default)]
pub struct AppState {
    pub cards: Vec<WindowCard>,
    pub active_session: String,
    pub active_window_id: String,
    pub scroll_offset: u16,
    pub sidebar_width: u16,
    pub selected_index: usize,
    pub mode: Mode,
    pub should_quit: bool,
    pub needs_redraw: bool,
}

impl AppState {
    pub fn new() -> Self {
        Self::default()
    }

    /// Total height needed to render all cards
    pub fn total_content_height(&self) -> u16 {
        // Each card: 1 top border + 4 rows + 1 bottom border = 6 lines
        // Plus 1 blank line between cards
        let cards = self.cards.len() as u16;
        if cards == 0 {
            return 0;
        }
        cards * 6 + cards.saturating_sub(1)
    }

    /// Get the active card (the one for the currently focused tmux window)
    pub fn active_card(&self) -> Option<&WindowCard> {
        self.cards.iter().find(|c| c.window_active)
    }
}

// --- Hook Event Data ---

#[derive(Debug, Deserialize, Default)]
pub struct HookData {
    // Common fields from stdin JSON
    pub cwd: Option<String>,
    pub session_id: Option<String>,
    pub prompt: Option<String>,
    pub tool_name: Option<String>,
    pub tool_input: Option<serde_json::Value>,
    pub tool_response: Option<serde_json::Value>,
    pub error: Option<String>,
    pub wait_reason: Option<String>,
    pub permission_mode: Option<String>,
    pub source: Option<String>,
    pub last_message: Option<String>,
    pub parent_id: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HookEvent {
    SessionStart,
    SessionEnd,
    UserPromptSubmit,
    Notification,
    Stop,
    StopFailure,
    PermissionDenied,
    CwdChanged,
    SubagentStart,
    SubagentStop,
    ActivityLog,
    TaskCreated,
    TaskCompleted,
    TeammateIdle,
    WorktreeCreate,
    WorktreeRemove,
}

impl fmt::Display for HookEvent {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            HookEvent::SessionStart => write!(f, "session-start"),
            HookEvent::SessionEnd => write!(f, "session-end"),
            HookEvent::UserPromptSubmit => write!(f, "user-prompt-submit"),
            HookEvent::Notification => write!(f, "notification"),
            HookEvent::Stop => write!(f, "stop"),
            HookEvent::StopFailure => write!(f, "stop-failure"),
            HookEvent::PermissionDenied => write!(f, "permission-denied"),
            HookEvent::CwdChanged => write!(f, "cwd-changed"),
            HookEvent::SubagentStart => write!(f, "subagent-start"),
            HookEvent::SubagentStop => write!(f, "subagent-stop"),
            HookEvent::ActivityLog => write!(f, "activity-log"),
            HookEvent::TaskCreated => write!(f, "task-created"),
            HookEvent::TaskCompleted => write!(f, "task-completed"),
            HookEvent::TeammateIdle => write!(f, "teammate-idle"),
            HookEvent::WorktreeCreate => write!(f, "worktree-create"),
            HookEvent::WorktreeRemove => write!(f, "worktree-remove"),
        }
    }
}

impl From<&str> for HookEvent {
    fn from(s: &str) -> Self {
        match s {
            "session-start" => HookEvent::SessionStart,
            "session-end" => HookEvent::SessionEnd,
            "user-prompt-submit" => HookEvent::UserPromptSubmit,
            "notification" => HookEvent::Notification,
            "stop" => HookEvent::Stop,
            "stop-failure" => HookEvent::StopFailure,
            "permission-denied" => HookEvent::PermissionDenied,
            "cwd-changed" => HookEvent::CwdChanged,
            "subagent-start" => HookEvent::SubagentStart,
            "subagent-stop" => HookEvent::SubagentStop,
            "activity-log" => HookEvent::ActivityLog,
            "task-created" => HookEvent::TaskCreated,
            "task-completed" => HookEvent::TaskCompleted,
            "teammate-idle" => HookEvent::TeammateIdle,
            "worktree-create" => HookEvent::WorktreeCreate,
            "worktree-remove" => HookEvent::WorktreeRemove,
            _ => HookEvent::SessionStart, // fallback
        }
    }
}