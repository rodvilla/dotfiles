use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "tmux-window-sidebar")]
#[command(about = "Tmux window switcher — floating popup and sidebar TUI")]
#[command(version)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Launch the sidebar TUI (persistent pane)
    Run {
        /// Sidebar width as percentage (e.g. "25%") or absolute columns
        #[arg(long, default_value = "28")]
        width: String,
    },
    /// Handle an agent hook event (called by shell hooks and plugins)
    Hook {
        /// Agent type: claude, codex, opencode
        agent: String,
        /// Event name (e.g. session-start, stop, notification)
        event: String,
    },
    /// Toggle sidebar in all windows
    Toggle,
    /// Toggle sidebar in all windows
    ToggleAll,
    /// Focus the content pane (non-sidebar pane) in the current window
    FocusContent,
    /// Sync status bar visibility with zoom and sidebar state
    SyncStatus,
    /// Clear agent status styling and attention flags for a pane
    ClearStatus {
        /// Pane ID to clear status for
        pane_id: String,
    },
    /// Show the floating window switcher popup
    Popup,
    /// Run the popup TUI (internal — launched inside tmux popup)
    PopupRun,
    /// Handle a mouse click on a sidebar card (called by tmux mouse binding)
    Click {
        /// Pane ID where the click occurred
        pane_id: String,
        /// Y coordinate of the click (pane-relative, 0-based)
        y: u16,
    },
}