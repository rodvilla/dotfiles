use ratatui::{
    Frame,
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
};

use crate::state::{AppState, Mode, WindowCard};
use crate::icons;

// --- Color constants (matching Ghostty theme) ---

const COLOR_BG: Color = Color::Rgb(2, 1, 17);       // #020111
const COLOR_TEXT: Color = Color::Rgb(255, 255, 255);   // #ffffff
const COLOR_DIM: Color = Color::Rgb(108, 112, 134);    // #6c7086
const COLOR_RUNNING: Color = Color::Rgb(158, 206, 106); // #9ece6a
const COLOR_WAITING: Color = Color::Rgb(224, 175, 104); // #e0af68
const COLOR_IDLE: Color = Color::Rgb(122, 162, 247);    // #7aa2f7
const COLOR_ERROR: Color = Color::Rgb(247, 118, 142);   // #f7768e
const COLOR_FOCUS_BG: Color = Color::Rgb(15, 14, 30);   // subtle focus tint (~5% lighter than base)

// Powerline rounded pill characters
const PILL_LEFT: &str = "\u{e0b6}";   //  (right semicircle)
const PILL_RIGHT: &str = "\u{e0b4}";  //  (left semicircle)

// Card dimensions for popup mode
const CARD_WIDTH: u16 = 28;
const CARD_HEIGHT: u16 = 4;
const CARD_GAP: u16 = 2;

fn status_color(status: &crate::state::PaneStatus) -> Color {
    match status {
        crate::state::PaneStatus::Running => COLOR_RUNNING,
        crate::state::PaneStatus::Background => COLOR_RUNNING,
        crate::state::PaneStatus::Waiting => COLOR_WAITING,
        crate::state::PaneStatus::Idle => COLOR_IDLE,
        crate::state::PaneStatus::Error => COLOR_ERROR,
        crate::state::PaneStatus::Unknown => COLOR_DIM,
    }
}

/// Render the UI based on the current mode
pub fn render(frame: &mut Frame, area: Rect, state: &AppState) {
    match state.mode {
        Mode::Sidebar => render_sidebar(frame, area, state),
        Mode::Popup => render_popup(frame, area, state),
    }
}

/// Render the sidebar (vertical card layout)
fn render_sidebar(frame: &mut Frame, area: Rect, state: &AppState) {
    if state.cards.is_empty() {
        let style = if state.sidebar_focused {
            Style::default().fg(COLOR_DIM).bg(COLOR_FOCUS_BG)
        } else {
            Style::default().fg(COLOR_DIM)
        };
        let paragraph = Paragraph::new(" No tmux windows").style(style);
        frame.render_widget(paragraph, area);
        return;
    }

    // Top padding so the first card isn't flush against the top
    const TOP_PADDING: u16 = 1;

    // Render focus background and optional borders when sidebar is focused
    let card_area = if state.sidebar_focused {
        let block = Block::default()
            .borders(Borders::LEFT | Borders::RIGHT)
            .border_style(Style::default().fg(COLOR_DIM))
            .style(Style::default().bg(COLOR_FOCUS_BG));
        let inner = block.inner(area);
        frame.render_widget(block, area);
        Rect::new(inner.x, inner.y + TOP_PADDING, inner.width, inner.height.saturating_sub(TOP_PADDING))
    } else {
        Rect::new(area.x, area.y + TOP_PADDING, area.width, area.height.saturating_sub(TOP_PADDING))
    };

    // Each card is 4 content rows + 1 gap row between cards
    let gap: u16 = 1;
    let scroll_offset = state.scroll_offset;

    // Build all card lines into a single paragraph and use ratatui's scroll
    let mut all_lines: Vec<Line> = Vec::new();
    let mut card_is_active = Vec::new();

    for (i, card) in state.cards.iter().enumerate() {
        let is_active = card.window_active;
        card_is_active.push((i, is_active));

        // Row 1: folder pill (active) or folder text (inactive)
        if is_active {
            let icon_color = if let Some(ref agent) = card.agent {
                status_color(&agent.status)
            } else {
                COLOR_DIM
            };
            all_lines.push(Line::from(vec![
                Span::styled(
                    format!(" {PILL_LEFT}"),
                    Style::default().fg(icon_color),
                ),
                Span::styled(
                    format!("{} {}", icons::ICON_FOLDER, card.folder),
                    Style::default().fg(COLOR_BG).bg(icon_color).add_modifier(Modifier::BOLD),
                ),
                Span::styled(
                    PILL_RIGHT.to_string(),
                    Style::default().fg(icon_color),
                ),
            ]));
        } else {
            all_lines.push(Line::from(vec![
                Span::styled(
                    format!(" {} {}", icons::ICON_FOLDER, card.folder),
                    Style::default().fg(COLOR_DIM),
                ),
            ]));
        }

        // Row 2: session icon (or zoom icon) + window_name
        let text_style = if is_active {
            Style::default().fg(COLOR_TEXT)
        } else {
            Style::default().fg(COLOR_DIM)
        };
        let row2_icon = if card.zoomed { icons::ICON_ZOOMED } else { icons::ICON_SESSION };
        all_lines.push(Line::from(vec![
            Span::styled(
                format!(" {row2_icon} {}", card.window_name),
                text_style,
            ),
        ]));

        // Row 3: git branch (or empty)
        if let Some(ref branch) = card.git_branch {
            all_lines.push(Line::from(vec![
                Span::styled(
                    format!(" {} {}", icons::ICON_GIT_BRANCH, branch),
                    text_style,
                ),
            ]));
        } else {
            all_lines.push(Line::from(""));
        }

        // Row 4: status icon + agent type badge
        if let Some(ref agent) = card.agent {
            let s_icon = icons::status_icon(&agent.status);
            let s_color = status_color(&agent.status);
            let agent_label = agent.agent_type.to_string();
            all_lines.push(Line::from(vec![
                Span::styled(
                    format!(" {s_icon} "),
                    Style::default().fg(s_color),
                ),
                Span::styled(
                    format!("{agent_label}"),
                    text_style,
                ),
            ]));
        } else {
            all_lines.push(Line::from(""));
        }

        // Gap between cards (except after the last one)
        if i < state.cards.len() - 1 {
            all_lines.push(Line::from(""));
        }
    }

    let paragraph = Paragraph::new(all_lines)
        .scroll((scroll_offset, 0));

    frame.render_widget(paragraph, card_area);
}

/// Render the popup (horizontal card layout, like macOS Cmd+Tab)
fn render_popup(frame: &mut Frame, area: Rect, state: &AppState) {
    if state.cards.is_empty() {
        let paragraph = Paragraph::new(" No tmux windows")
            .style(Style::default().fg(COLOR_DIM).bg(COLOR_BG));
        frame.render_widget(paragraph, area);
        return;
    }

    // Calculate how many cards fit in the visible area
    let available_width = area.width.saturating_sub(2); // subtract popup borders
    let cards_that_fit = if available_width >= CARD_WIDTH {
        (available_width + CARD_GAP) / (CARD_WIDTH + CARD_GAP)
    } else {
        1
    };

    // Calculate horizontal scroll offset to keep selected card visible
    let selected = state.selected_index as u16;
    let scroll_offset = if selected >= cards_that_fit {
        selected - cards_that_fit + 1
    } else {
        0
    };

    let mut x: u16 = 0;
    for (i, card) in state.cards.iter().enumerate() {
        let idx = i as u16;
        if idx < scroll_offset {
            continue;
        }

        let card_x = area.x + x;
        if card_x + CARD_WIDTH > area.x + area.width.saturating_sub(1) {
            break;
        }

        let card_area = Rect {
            x: card_x,
            y: area.y,
            width: CARD_WIDTH.min(area.width.saturating_sub(x)),
            height: CARD_HEIGHT.min(area.height),
        };

        let is_selected = i == state.selected_index;
        render_card(frame, card_area, card, is_selected);

        x += CARD_WIDTH + CARD_GAP;
    }
}

fn render_card(frame: &mut Frame, area: Rect, card: &WindowCard, selected: bool) {
    let text_style = if selected || card.window_active {
        Style::default().fg(COLOR_TEXT)
    } else {
        Style::default().fg(COLOR_DIM)
    };

    // Row 1: folder pill (active/selected) or folder text (inactive)
    let row1 = if card.window_active || selected {
        // Active/selected window: rounded pill matching status bar style
        let icon_color = if let Some(ref agent) = card.agent {
            status_color(&agent.status)
        } else {
            COLOR_DIM
        };

        Line::from(vec![
            Span::styled(
                format!(" {PILL_LEFT}"),
                Style::default().fg(icon_color),
            ),
            Span::styled(
                format!(" {} {} ", icons::ICON_FOLDER, card.folder),
                Style::default().fg(COLOR_BG).bg(icon_color).add_modifier(Modifier::BOLD),
            ),
            Span::styled(
                PILL_RIGHT.to_string(),
                Style::default().fg(icon_color),
            ),
        ])
    } else {
        // Inactive window: dim folder with padding
        Line::from(vec![
            Span::styled(
                format!(" {} {}", icons::ICON_FOLDER, card.folder),
                Style::default().fg(COLOR_DIM),
            ),
        ])
    };

    // Row 2: session icon (or zoom icon when zoomed) + window_name
    let row2_icon = if card.zoomed {
        icons::ICON_ZOOMED
    } else {
        icons::ICON_SESSION
    };
    let row2 = Line::from(vec![
        Span::styled(
            format!(" {row2_icon} {}", card.window_name),
            text_style,
        ),
    ]);

    // Row 3: git branch (or empty)
    let row3 = if let Some(ref branch) = card.git_branch {
        Line::from(vec![
            Span::styled(
                format!(" {} {}", icons::ICON_GIT_BRANCH, branch),
                text_style,
            ),
        ])
    } else {
        Line::from("")
    };

    // Row 4: status icon + agent type badge
    let row4 = if let Some(ref agent) = card.agent {
        let s_icon = icons::status_icon(&agent.status);
        let s_color = status_color(&agent.status);
        //let a_icon = icons::agent_icon(&agent.agent_type);
        let agent_label = agent.agent_type.to_string();

        Line::from(vec![
            Span::styled(
                format!(" {s_icon} "),
                Style::default().fg(s_color),
            ),
            Span::styled(
                format!("{agent_label}"),
                text_style,
            ),
        ])
    } else {
        Line::from("")
    };

    let block = Block::default();

    let paragraph = Paragraph::new(vec![row1, row2, row3, row4])
        .block(block);

    frame.render_widget(paragraph, area);
}

/// Calculate the popup dimensions based on the number of windows
pub fn popup_dimensions(num_cards: usize, term_width: u16, term_height: u16) -> (u16, u16) {
    let n = num_cards.max(1) as u16;

    // Ideal width: all cards side by side with gaps
    let ideal_width = n * CARD_WIDTH + n.saturating_sub(1) * CARD_GAP + 2; // +2 for popup border
    let max_width = term_width * 90 / 100;

    let width = ideal_width.min(max_width).max(CARD_WIDTH + 2);
    let height = CARD_HEIGHT + 2; // +2 for popup border

    // Don't exceed terminal dimensions
    let width = width.min(term_width);
    let height = height.min(term_height);

    (width, height)
}
