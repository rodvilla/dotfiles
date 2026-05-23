// Agent and status icon constants
// Uses Nerd Font codepoints where available, with Unicode fallbacks.
// Ghostty with a Nerd Font should render these correctly.

// Status icons (Unicode — widely supported)
pub const ICON_RUNNING: &str = "⚡";
pub const ICON_BACKGROUND: &str = "◎";
pub const ICON_WAITING: &str = "◐";
pub const ICON_IDLE: &str = "○";
pub const ICON_ERROR: &str = "✕";
pub const ICON_UNKNOWN: &str = "·";

// Agent type icons (Nerd Fonts private use area)
// These require a Nerd Font (e.g., JetBrains Mono Nerd Font, FiraCode Nerd Font)
pub const ICON_CLAUDE: &str = "\u{f4b8}";   // 󤒸 nf-dev-robot
pub const ICON_CODEX: &str = "\u{f4b8}";   // 󤒸 nf-dev-robot (same, codex variant)
pub const ICON_OPENCODE: &str = "\u{e70e}"; // 󜜎 nf-dev-code_badge

// Folder icon (Nerd Font)
pub const ICON_FOLDER: &str = "\u{f07b}"; // 󰁻 nf-fa-folder

// Git branch icon (Nerd Font)
pub const ICON_GIT_BRANCH: &str = "\u{f126}"; // 󰄦 nf-fa-code_branch

// Session/window icon (Nerd Font)
pub const ICON_SESSION: &str = "\u{f2d0}"; //  nf-fa-window_maximize

// Zoom icon (Nerd Font) — matches old status bar 󰊓
pub const ICON_ZOOMED: &str = "\u{f00d3}"; // 󰊓 nf-md-arrow_expand_all

// Status icon for a given PaneStatus
pub fn status_icon(status: &crate::state::PaneStatus) -> &'static str {
    match status {
        crate::state::PaneStatus::Running => ICON_RUNNING,
        crate::state::PaneStatus::Background => ICON_BACKGROUND,
        crate::state::PaneStatus::Waiting => ICON_WAITING,
        crate::state::PaneStatus::Idle => ICON_IDLE,
        crate::state::PaneStatus::Error => ICON_ERROR,
        crate::state::PaneStatus::Unknown => ICON_UNKNOWN,
    }
}

// Agent type icon
pub fn agent_icon(agent_type: &crate::state::AgentType) -> &'static str {
    match agent_type {
        crate::state::AgentType::Claude => ICON_CLAUDE,
        crate::state::AgentType::Codex => ICON_CODEX,
        crate::state::AgentType::OpenCode => ICON_OPENCODE,
        crate::state::AgentType::Unknown => ICON_UNKNOWN,
    }
}