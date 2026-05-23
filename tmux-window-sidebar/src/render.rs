use ratatui::{
    Frame,
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
};

use crate::state::{AgentType, AppState, PaneStatus, WindowCard};
use crate::icons;

// --- Color constants (matching Ghostty theme) ---

const COLOR_BG: Color = Color::Rgb(2, 1, 17);       // #020111
const COLOR_ACCENT: Color = Color::Rgb(156, 223, 197); // #9CDFC5
const COLOR_TEXT: Color = Color::Rgb(255, 255, 255);   // #ffffff
const COLOR_DIM: Color = Color::Rgb(108, 112, 134);    // #6c7086
const COLOR_RUNNING: Color = Color::Rgb(158, 206, 106); // #9ece6a
const COLOR_WAITING: Color = Color::Rgb(224, 175, 104); // #e0af68
const COLOR_IDLE: Color = Color::Rgb(122, 162, 247);    // #7aa2f7
const COLOR_ERROR: Color = Color::Rgb(247, 118, 142);   // #f7768e

// Agent type colors (256-color)
const COLOR_CLAUDE: Color = Color::Indexed(174);  // dusty rose
const COLOR_CODEX: Color = Color::Indexed(141);   // purple
const COLOR_OPENCODE: Color = Color::Indexed(117); // cyan

// Powerline rounded pill characters
const PILL_LEFT: &str = "\u{e0b6}";   //  (right semicircle)
const PILL_RIGHT: &str = "\u{e0b4}";  //  (left semicircle)

fn status_color(status: &PaneStatus) -> Color {
    match status {
        PaneStatus::Running => COLOR_RUNNING,
        PaneStatus::Background => COLOR_RUNNING,
        PaneStatus::Waiting => COLOR_WAITING,
        PaneStatus::Idle => COLOR_IDLE,
        PaneStatus::Error => COLOR_ERROR,
        PaneStatus::Unknown => COLOR_DIM,
    }
}

fn agent_color(agent_type: &AgentType) -> Color {
    match agent_type {
        AgentType::Claude => COLOR_CLAUDE,
        AgentType::Codex => COLOR_CODEX,
        AgentType::OpenCode => COLOR_OPENCODE,
        AgentType::Unknown => COLOR_DIM,
    }
}

/// Render the full sidebar into the given frame area
pub fn render(frame: &mut Frame, area: Rect, state: &AppState) {
    if state.cards.is_empty() {
        let paragraph = Paragraph::new(" No tmux windows")
            .style(Style::default().fg(COLOR_DIM).bg(COLOR_BG));
        frame.render_widget(paragraph, area);
        return;
    }

    // Calculate card height: 4 content rows + 2 border rows = 6
    let card_height: u16 = 6;
    let gap: u16 = 1;
    let scroll_offset = state.scroll_offset;
    let mut y: u16 = 0;
    let mut visible_y: u16 = 0;

    for card in &state.cards {
        let card_top = visible_y;
        let card_bottom = card_top + card_height;

        if card_bottom <= scroll_offset {
            visible_y += card_height + gap;
            continue;
        }
        if card_top >= scroll_offset + area.height {
            break;
        }

        let render_y = y;
        let render_height = area.height.saturating_sub(render_y).min(card_height);

        if render_height == 0 {
            break;
        }

        let card_area = Rect {
            x: area.x,
            y: area.y + render_y,
            width: area.width,
            height: render_height,
        };

        render_card(frame, card_area, card);

        y += card_height + gap;
        visible_y += card_height + gap;
    }
}

fn render_card(frame: &mut Frame, area: Rect, card: &WindowCard) {
    // All cards have invisible borders (matching background)
    // The active card is distinguished by the folder pill, not the border
    let border_color = COLOR_BG;

    let text_style = if card.window_active {
        Style::default().fg(COLOR_TEXT).bg(COLOR_BG)
    } else {
        Style::default().fg(COLOR_DIM).bg(COLOR_BG)
    };

    // Row 1: folder pill (active) or folder text (inactive)
    let row1 = if card.window_active {
        // Active window: rounded pill matching status bar style
        //   folder 
        let icon_color = if let Some(ref agent) = card.agent {
            status_color(&agent.status)
        } else {
            COLOR_DIM
        };

        Line::from(vec![
            Span::styled(
                format!(" {PILL_LEFT}"),
                Style::default().fg(COLOR_ACCENT).bg(COLOR_BG),
            ),
            Span::styled(
                format!(" {} {} ", icons::ICON_FOLDER, card.folder),
                Style::default().fg(COLOR_BG).bg(COLOR_ACCENT).add_modifier(Modifier::BOLD),
            ),
            Span::styled(
                PILL_RIGHT.to_string(),
                Style::default().fg(COLOR_ACCENT).bg(COLOR_BG),
            ),
        ])
    } else {
        // Inactive window: dim folder with padding
        Line::from(vec![
            Span::styled(
                format!(" {} {}", icons::ICON_FOLDER, card.folder),
                Style::default().fg(COLOR_DIM).bg(COLOR_BG),
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
        let a_icon = icons::agent_icon(&agent.agent_type);
        let agent_label = agent.agent_type.to_string();

        Line::from(vec![
            Span::styled(
                format!(" {s_icon} "),
                Style::default().fg(s_color).bg(COLOR_BG),
            ),
            Span::styled(
                format!("{a_icon} {agent_label}"),
                text_style,
            ),
        ])
    } else {
        Line::from("")
    };

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(border_color).bg(COLOR_BG))
        .style(Style::default().bg(COLOR_BG));

    let paragraph = Paragraph::new(vec![row1, row2, row3, row4])
        .block(block);

    frame.render_widget(paragraph, area);
}
