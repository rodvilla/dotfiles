mod app;
mod cli;
mod hook;
mod icons;
mod render;
mod session;
mod sound;
mod state;
mod tmux;

use clap::Parser;
use crossterm::event::{self, Event, KeyCode};
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;
use std::io;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use cli::Commands;
use state::AppState;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = cli::Cli::parse();

    match cli.command {
        Commands::Run { width } => run_tui(&width),
        Commands::Hook { agent, event } => {
            hook::handle_hook(&agent, &event)?;
            Ok(())
        }
        Commands::Toggle => {
            toggle_sidebar(false)?;
            Ok(())
        }
        Commands::ToggleAll => {
            toggle_sidebar(true)?;
            Ok(())
        }
        Commands::FocusContent => {
            focus_content()?;
            Ok(())
        }
        Commands::SyncStatus => {
            sync_status()?;
            Ok(())
        }
    }
}

fn run_tui(width_spec: &str) -> Result<(), Box<dyn std::error::Error>> {
    // Set up terminal
    crossterm::execute!(io::stdout(), crossterm::terminal::EnterAlternateScreen)?;

    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    terminal.clear()?;

    // Set up SIGUSR1 handler for instant refresh
    let redraw_flag = Arc::new(AtomicBool::new(false));
    let flag_clone = redraw_flag.clone();
    let sig_id = signal_hook::consts::SIGUSR1;
    unsafe {
        signal_hook::low_level::register(sig_id, move || {
            flag_clone.store(true, Ordering::Relaxed);
        })?;
    }

    // Parse width
    let sidebar_width_pct = parse_width_pct(width_spec);

    // Hide tmux status bar
    let _ = std::process::Command::new("tmux")
        .args(["set-option", "-g", "status", "off"])
        .status();

    // Initial state
    let mut state = AppState::new();

    // Event loop
    let mut last_poll = std::time::Instant::now();

    loop {
        // Poll tmux for window data every second
        let now = std::time::Instant::now();
        if now.duration_since(last_poll) >= Duration::from_secs(1) {
            state.cards = tmux::query_windows();
            state.active_session = tmux::active_session().unwrap_or_default();
            state.active_window_id = tmux::active_window_id().unwrap_or_default();
            state.needs_redraw = true;
            last_poll = now;
        }

        // Check SIGUSR1 flag
        if redraw_flag.swap(false, Ordering::Relaxed) {
            state.cards = tmux::query_windows();
            state.active_session = tmux::active_session().unwrap_or_default();
            state.active_window_id = tmux::active_window_id().unwrap_or_default();
            state.needs_redraw = true;
        }

        // Render if needed
        if state.needs_redraw {
            terminal.draw(|f| {
                let area = f.area();
                // The TUI runs inside a tmux pane already sized to the sidebar width,
                // so just fill the entire area — no need to calculate a subset.
                render::render(f, area, &state);
            })?;
            state.needs_redraw = false;
        }

        // Handle input events (non-blocking)
        if event::poll(Duration::from_millis(100))? {
            match event::read()? {
                Event::Key(key) => match key.code {
                    KeyCode::Char('q') | KeyCode::Esc => {
                        state.should_quit = true;
                    }
                    KeyCode::Char('j') | KeyCode::Down => {
                        state.scroll_offset = state.scroll_offset.saturating_add(1);
                        state.needs_redraw = true;
                    }
                    KeyCode::Char('k') | KeyCode::Up => {
                        state.scroll_offset = state.scroll_offset.saturating_sub(1);
                        state.needs_redraw = true;
                    }
                    KeyCode::Char('G') | KeyCode::End => {
                        let visible = terminal.size().map(|s| s.height).unwrap_or(50);
                        let max = app::max_scroll(&state, visible);
                        state.scroll_offset = max;
                        state.needs_redraw = true;
                    }
                    KeyCode::Char('g') | KeyCode::Home => {
                        state.scroll_offset = 0;
                        state.needs_redraw = true;
                    }
                    _ => {}
                },
                Event::Resize(_, _) => {
                    state.needs_redraw = true;
                }
                _ => {}
            }
        }

        if state.should_quit {
            break;
        }
    }

    // Restore terminal
    crossterm::execute!(io::stdout(), crossterm::terminal::LeaveAlternateScreen)?;

    // Restore tmux status bar
    let _ = std::process::Command::new("tmux")
        .args(["set-option", "-g", "status", "on"])
        .status();

    Ok(())
}

/// Toggle sidebar in all windows.
/// If any window has a sidebar pane, kill ALL sidebar panes.
/// If no window has a sidebar, create one in EVERY window.
/// Restores focus to the original pane after creating sidebars.
fn toggle_sidebar(_all: bool) -> Result<(), Box<dyn std::error::Error>> {
    // Save the currently active pane so we can restore focus later
    let active_pane = std::process::Command::new("tmux")
        .args(["display-message", "-p", "#{pane_id}"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default();

    // Find ALL sidebar panes across all windows
    let output = std::process::Command::new("tmux")
        .args(["list-panes", "-a", "-F", "#{pane_id}:#{pane_current_command}"])
        .output()?;

    let output_str = String::from_utf8_lossy(&output.stdout);
    let sidebar_panes: Vec<&str> = output_str
        .lines()
        .filter(|l| l.split(':').nth(1).map_or(false, |cmd| cmd.starts_with("tmux-window-sid")))
        .collect();

    if !sidebar_panes.is_empty() {
        // Kill ALL sidebar panes
        for pane_line in &sidebar_panes {
            let pane_id = pane_line.split(':').next().unwrap_or("");
            let _ = std::process::Command::new("tmux")
                .args(["kill-pane", "-t", pane_id])
                .status();
        }
        // Restore status bar
        let _ = std::process::Command::new("tmux")
            .args(["set-option", "-g", "status", "on"])
            .status();
    } else {
        // Get configured width
        let width_spec = std::process::Command::new("tmux")
            .args(["show-option", "-g", "-q", "@ws_width"])
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_else(|_| "28".to_string());

        let cols = if width_spec.ends_with('%') {
            let pct: u16 = width_spec.trim_end_matches('%').parse().unwrap_or(25);
            let term_width = std::process::Command::new("tmux")
                .args(["display-message", "-p", "#{window_width}"])
                .output()
                .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
                .ok()
                .and_then(|s| s.parse::<u16>().ok())
                .unwrap_or(80);
            std::cmp::max(term_width * pct / 100, 10)
        } else {
            let abs: u16 = width_spec.parse().unwrap_or(28);
            std::cmp::max(abs, 10)
        };

        // List all windows and create a sidebar in each one
        let windows = std::process::Command::new("tmux")
            .args(["list-windows", "-a", "-F", "#{window_id}"])
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default();

        for window_id in windows.lines() {
            let window_id = window_id.trim();
            if window_id.is_empty() {
                continue;
            }
            // Find the first (leftmost) pane in this window by pane index
            let first_pane = std::process::Command::new("tmux")
                .args(["list-panes", "-t", window_id, "-F", "#{pane_id}:#{pane_index}"])
                .output()
                .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
                .unwrap_or_default();

            // Find the pane with the lowest index
            let mut target_pane = String::new();
            let mut min_index = usize::MAX;
            for line in first_pane.lines() {
                let parts: Vec<&str> = line.splitn(2, ':').collect();
                if parts.len() >= 2 {
                    if let Ok(idx) = parts[1].parse::<usize>() {
                        if idx < min_index {
                            min_index = idx;
                            target_pane = parts[0].to_string();
                        }
                    }
                }
            }

            if target_pane.is_empty() {
                target_pane = window_id.to_string();
            }

            let cmd = format!("tmux-window-sidebar run --width {}cols", cols);
            let _ = std::process::Command::new("tmux")
                .args([
                    "split-window", "-t", &target_pane, "-h", "-b",
                    "-l", &cols.to_string(),
                    &cmd,
                ])
                .status();
        }

        // Hide status bar
        let _ = std::process::Command::new("tmux")
            .args(["set-option", "-g", "status", "off"])
            .status();
    }

    // Restore focus to the original pane
    if !active_pane.is_empty() {
        let _ = std::process::Command::new("tmux")
            .args(["select-pane", "-t", &active_pane])
            .status();
    }

    Ok(())
}

/// Parse width spec as percentage (returns 0-100) or absolute columns
fn parse_width_pct(spec: &str) -> u16 {
    // Handle "25pct", "25%", "28cols", or plain "28"
    let cleaned = spec
        .trim_end_matches("pct")
        .trim_end_matches('%')
        .trim_end_matches("cols");
    cleaned.parse().unwrap_or(25)
}

/// Focus the content pane (non-sidebar pane) in the current window.
/// Used by the after-select-pane hook to prevent the sidebar from stealing focus.
fn focus_content() -> Result<(), Box<dyn std::error::Error>> {
    // List panes in the current window
    let output = std::process::Command::new("tmux")
        .args(["list-panes", "-F", "#{pane_id}:#{pane_current_command}"])
        .output()?;

    let output_str = String::from_utf8_lossy(&output.stdout);

    // Find the first non-sidebar pane
    for line in output_str.lines() {
        let parts: Vec<&str> = line.splitn(2, ':').collect();
        if parts.len() < 2 {
            continue;
        }
        let pane_id = parts[0];
        let cmd = parts[1];

        // Skip sidebar panes (truncated to 15 chars: tmux-window-sid)
        if cmd.starts_with("tmux-window-sid") {
            continue;
        }

        // Focus this content pane
        let _ = std::process::Command::new("tmux")
            .args(["select-pane", "-t", pane_id])
            .status();
        return Ok(());
    }

    Ok(())
}

/// Sync status bar visibility with zoom and sidebar state.
/// - If a pane is zoomed and sidebar is open: show status bar (sidebar is hidden during zoom)
/// - If a pane is not zoomed and sidebar is open: hide status bar
/// - If sidebar is closed: always show status bar
fn sync_status() -> Result<(), Box<dyn std::error::Error>> {
    // Check if any sidebar pane exists
    let panes = std::process::Command::new("tmux")
        .args(["list-panes", "-a", "-F", "#{pane_current_command}"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default();

    let sidebar_open = panes.lines().any(|cmd| cmd.starts_with("tmux-window-sid"));

    if !sidebar_open {
        // No sidebar — status bar should be on
        let _ = std::process::Command::new("tmux")
            .args(["set-option", "-g", "status", "on"])
            .status();
        return Ok(());
    }

    // Sidebar is open — check if current window is zoomed
    let zoomed = std::process::Command::new("tmux")
        .args(["display-message", "-p", "#{window_zoomed_flag}"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default();

    if zoomed == "1" {
        // Zoomed: show status bar (sidebar is hidden)
        let _ = std::process::Command::new("tmux")
            .args(["set-option", "-g", "status", "on"])
            .status();
    } else {
        // Not zoomed: hide status bar (sidebar is visible)
        let _ = std::process::Command::new("tmux")
            .args(["set-option", "-g", "status", "off"])
            .status();
    }

    Ok(())
}