mod cli;
mod hook;
mod icons;
mod render;
mod session;
mod sound;
mod state;
mod tmux;

use clap::Parser;
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;
use std::io;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use cli::Commands;
use state::{AppState, Mode};

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
        Commands::ClearStatus { pane_id } => {
            clear_status(&pane_id)?;
            Ok(())
        }
        Commands::Popup => {
            launch_popup()?;
            Ok(())
        }
        Commands::PopupRun => {
            run_popup_tui()?;
            Ok(())
        }
        Commands::Click { pane_id, y } => {
            handle_click(&pane_id, y)?;
            Ok(())
        }
    }
}

/// RAII guard that restores the terminal on drop (raw mode off, leave alternate screen, show cursor).
struct TerminalGuard;

impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let _ = crossterm::execute!(
            io::stdout(),
            crossterm::cursor::Show,
            crossterm::terminal::LeaveAlternateScreen
        );
        let _ = crossterm::terminal::disable_raw_mode();
    }
}

fn run_tui(width_spec: &str) -> Result<(), Box<dyn std::error::Error>> {
    // Set up terminal — guard ensures cleanup even on early return / panic
    crossterm::terminal::enable_raw_mode()?;
    crossterm::execute!(
        io::stdout(),
        crossterm::terminal::EnterAlternateScreen,
        crossterm::cursor::Hide
    )?;
    let _guard = TerminalGuard;

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
    let mut state = AppState {
        mode: Mode::Sidebar,
        sidebar_width: sidebar_width_pct,
        ..AppState::default()
    };

    // Helper: sync state from tmux and update selected_index
    let sync_state = |state: &mut AppState| {
        state.cards = tmux::query_windows();
        state.active_session = tmux::active_session().unwrap_or_default();
        state.active_window_id = tmux::active_window_id().unwrap_or_default();
        if let Ok(pane_id) = std::env::var("TMUX_PANE") {
            state.sidebar_focused = tmux::is_pane_active(&pane_id);
        }
        // Keep selected_index pointing at the active window if it hasn't been set yet
        // or if the previously selected card is gone
        if state.selected_index >= state.cards.len() {
            state.selected_index = state.cards.iter().position(|c| c.window_active).unwrap_or(0);
        }
        state.needs_redraw = true;
    };

    // Initial data load
    sync_state(&mut state);
    // Set selected_index to the active window on startup
    state.selected_index = state.cards.iter().position(|c| c.window_active).unwrap_or(0);

    // Event loop
    let mut last_poll = std::time::Instant::now();

    loop {
        // Poll tmux for window data every second
        let now = std::time::Instant::now();
        if now.duration_since(last_poll) >= Duration::from_secs(1) {
            sync_state(&mut state);
            last_poll = now;
        }

        // Check SIGUSR1 flag
        if redraw_flag.swap(false, Ordering::Relaxed) {
            sync_state(&mut state);
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
                Event::Key(key) if key.kind == KeyEventKind::Press => match key.code {
                    KeyCode::Char('q') => {
                        state.should_quit = true;
                    }
                    KeyCode::Esc | KeyCode::Tab => {
                        // Move focus back to the content pane (non-sidebar pane)
                        focus_content_from_tui();
                    }
                    KeyCode::Char('j') | KeyCode::Down => {
                        if !state.cards.is_empty() {
                            state.selected_index = (state.selected_index + 1).min(state.cards.len() - 1);
                            state.needs_redraw = true;
                        }
                    }
                    KeyCode::Char('k') | KeyCode::Up => {
                        state.selected_index = state.selected_index.saturating_sub(1);
                        state.needs_redraw = true;
                    }
                    KeyCode::Char('G') | KeyCode::End => {
                        if !state.cards.is_empty() {
                            state.selected_index = state.cards.len() - 1;
                            state.needs_redraw = true;
                        }
                    }
                    KeyCode::Char('g') | KeyCode::Home => {
                        state.selected_index = 0;
                        state.needs_redraw = true;
                    }
                    KeyCode::Enter => {
                        // Switch to the selected window
                        if let Some(card) = state.cards.get(state.selected_index) {
                            let window_id = card.window_id.clone();
                            let _ = tmux::switch_to_window(&window_id);
                        }
                    }
                    _ => {}
                },
                Event::Key(_) => {
                    // Ignore Release and Repeat events (crossterm 0.28 sends these)
                }
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

    // TerminalGuard drop restores terminal (cursor show, leave alternate screen, disable raw mode)

    // Restore tmux status bar
    let _ = std::process::Command::new("tmux")
        .args(["set-option", "-g", "status", "on"])
        .status();

    Ok(())
}

/// Handle mouse clicks on sidebar cards via tmux mouse binding.
/// Receives a pane ID and y-coordinate, determines which card was clicked,
/// and switches to that window.
fn handle_click(pane_id: &str, y: u16) -> Result<(), Box<dyn std::error::Error>> {
    // Verify this pane is actually a sidebar
    let cmd = tmux::tmux_output(&["display-message", "-t", pane_id, "-p", "#{pane_current_command}"])?;
    if !cmd.starts_with("tmux-window-sid") {
        // Not a sidebar pane — select it instead (preserve default click behavior)
        let _ = std::process::Command::new("tmux")
            .args(["select-pane", "-t", pane_id])
            .status();
        return Ok(());
    }

    // Calculate which card was clicked (no scroll offset — auto-scroll keeps selected visible)
    let card_height: u16 = 4;
    let gap: u16 = 1;
    let row_stride = card_height + gap;

    // Adjust for top padding (1 row)
    let adjusted_y = y.saturating_sub(1);

    // Calculate card index
    let card_index = adjusted_y / row_stride;
    let card_local_y = adjusted_y % row_stride;

    // Only count clicks within the card area (not in the gap)
    if card_local_y >= card_height {
        return Ok(());
    }

    // Get the window cards and switch to the clicked one
    let cards = tmux::query_windows();
    if let Some(card) = cards.get(card_index as usize) {
        let _ = tmux::switch_to_window(&card.window_id);
    }

    Ok(())
}

/// Launch the floating window switcher popup.
/// Queries windows, calculates popup dimensions, and creates a tmux popup.
fn launch_popup() -> Result<(), Box<dyn std::error::Error>> {
    let cards = tmux::query_windows();
    let n = cards.len().max(1);

    let term_width = tmux::terminal_width();
    let term_height = tmux::terminal_height();

    let (popup_w, popup_h) = render::popup_dimensions(n, term_width, term_height);

    let bin = std::env::current_exe()?;
    let cmd = format!("{} popup-run", bin.display());

    std::process::Command::new("tmux")
        .args([
            "popup",
            "-C",  // center
            "-w", &popup_w.to_string(),
            "-h", &popup_h.to_string(),
            "-B",  // no border (we draw our own)
            "--", &cmd,
        ])
        .status()?;

    Ok(())
}

/// Run the popup TUI inside a tmux popup.
/// Shows horizontal cards, navigate with arrow keys, select with Enter, dismiss with ESC.
fn run_popup_tui() -> Result<(), Box<dyn std::error::Error>> {
    // Set up terminal — guard ensures cleanup even on early return / panic
    crossterm::terminal::enable_raw_mode()?;
    crossterm::execute!(
        io::stdout(),
        crossterm::terminal::EnterAlternateScreen,
        crossterm::cursor::Hide
    )?;
    let _guard = TerminalGuard;

    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;
    terminal.clear()?;

    // Initial state
    let cards = tmux::query_windows();
    let active_window_id = tmux::active_window_id().unwrap_or_default();

    // Find the index of the currently active window
    let selected_index = cards
        .iter()
        .position(|c| c.window_active)
        .unwrap_or(0);

    let mut state = AppState {
        mode: Mode::Popup,
        cards,
        active_session: tmux::active_session().unwrap_or_default(),
        active_window_id,
        selected_index,
        ..AppState::default()
    };

    // Initial render
    terminal.draw(|f| {
        let area = f.area();
        render::render(f, area, &state);
    })?;

    // Event loop — popup is transient, no periodic polling
    loop {
        if event::poll(Duration::from_millis(200))? {
            match event::read()? {
                Event::Key(key) => match key.code {
                    // Navigate left
                    KeyCode::Left | KeyCode::Char('h') => {
                        if state.selected_index > 0 {
                            state.selected_index -= 1;
                            state.needs_redraw = true;
                        }
                    }
                    // Navigate right
                    KeyCode::Right | KeyCode::Char('l') => {
                        if state.selected_index < state.cards.len().saturating_sub(1) {
                            state.selected_index += 1;
                            state.needs_redraw = true;
                        }
                    }
                    // Tab cycles forward
                    KeyCode::Tab => {
                        if state.selected_index < state.cards.len().saturating_sub(1) {
                            state.selected_index += 1;
                        } else {
                            state.selected_index = 0;
                        }
                        state.needs_redraw = true;
                    }
                    // BackTab cycles backward
                    KeyCode::BackTab => {
                        if state.selected_index > 0 {
                            state.selected_index -= 1;
                        } else {
                            state.selected_index = state.cards.len().saturating_sub(1);
                        }
                        state.needs_redraw = true;
                    }
                    // Select and switch
                    KeyCode::Enter => {
                        if let Some(card) = state.cards.get(state.selected_index) {
                            let window_id = card.window_id.clone();
                            // Switch to the selected window
                            let _ = tmux::switch_to_window(&window_id);
                        }
                        break;
                    }
                    // Dismiss
                    KeyCode::Esc | KeyCode::Char('q') => {
                        break;
                    }
                    // Refresh window list
                    KeyCode::Char('r') => {
                        state.cards = tmux::query_windows();
                        state.active_session = tmux::active_session().unwrap_or_default();
                        state.active_window_id = tmux::active_window_id().unwrap_or_default();
                        // Re-clamp selected_index
                        if state.selected_index >= state.cards.len() {
                            state.selected_index = state.cards.len().saturating_sub(1);
                        }
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

        if state.needs_redraw {
            terminal.draw(|f| {
                let area = f.area();
                render::render(f, area, &state);
            })?;
            state.needs_redraw = false;
        }

        if state.should_quit {
            break;
        }
    }

    // TerminalGuard drop restores terminal

    Ok(())
}

/// Toggle sidebar in all windows.
/// If any window has a sidebar pane, kill ALL sidebar panes.
/// If no window has a sidebar, create one in EVERY window.
/// After creating sidebars, focuses the sidebar pane so the user can navigate immediately.
fn toggle_sidebar(_all: bool) -> Result<(), Box<dyn std::error::Error>> {
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
                    "split-window", "-t", &target_pane, "-h", "-b", "-f",
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

    // Focus the sidebar pane in the current window so the user can navigate immediately
    let panes_output = std::process::Command::new("tmux")
        .args(["list-panes", "-F", "#{pane_id}:#{pane_current_command}"])
        .output();
    if let Ok(output) = panes_output {
        let output_str = String::from_utf8_lossy(&output.stdout);
        for line in output_str.lines() {
            let parts: Vec<&str> = line.splitn(2, ':').collect();
            if parts.len() < 2 {
                continue;
            }
            let pane_id = parts[0];
            let cmd = parts[1];
            if cmd.starts_with("tmux-window-sid") {
                let _ = std::process::Command::new("tmux")
                    .args(["select-pane", "-t", pane_id])
                    .status();
                break;
            }
        }
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

/// Focus the content pane (non-sidebar pane) from within the TUI.
/// Finds the first non-sidebar pane in the current window and selects it,
/// so keyboard focus moves back to the content area while the sidebar stays open.
fn focus_content_from_tui() {
    let output = std::process::Command::new("tmux")
        .args(["list-panes", "-F", "#{pane_id}:#{pane_current_command}"])
        .output();

    if let Ok(output) = output {
        let output_str = String::from_utf8_lossy(&output.stdout);
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
            return;
        }
    }
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

/// Clear agent status styling and attention flags for a pane.
/// Called when switching windows to reset the window name color and
/// clear the attention flag so the sidebar stops highlighting.
fn clear_status(pane_id: &str) -> Result<(), Box<dyn std::error::Error>> {
    // Reset window status style to default (removes agent color)
    let _ = std::process::Command::new("tmux")
        .args(["set-window-option", "-t", pane_id, "-u", "window-status-style"])
        .status();

    // Clear pane attention flag
    let _ = std::process::Command::new("tmux")
        .args(["set-option", "-p", "-t", pane_id, "-u", "@pane_attention"])
        .status();

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