use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "tmux-window-sidebar")]
#[command(about = "Tmux sidebar TUI showing per-window agent cards")]
#[command(version)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Launch the TUI sidebar
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
    /// Sync status bar visibility with zoom state (show when zoomed, hide when sidebar is open)
    SyncStatus,
}