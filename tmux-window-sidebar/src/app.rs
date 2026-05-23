// App event loop module — currently the main loop lives in main.rs
// This module is reserved for future refactoring of the event loop logic

use crate::state::AppState;

/// Calculate the actual sidebar width from a percentage and terminal width
pub fn calculate_sidebar_width(percent: u16, terminal_width: u16) -> u16 {
    let pct = percent.min(100);
    (terminal_width as u32 * pct as u32 / 100) as u16
}

/// Calculate scroll boundaries
pub fn max_scroll(state: &AppState, visible_height: u16) -> u16 {
    let content_height = state.total_content_height();
    content_height.saturating_sub(visible_height)
}