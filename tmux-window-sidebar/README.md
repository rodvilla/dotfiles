# tmux-window-sidebar

A tmux sidebar TUI (Rust + ratatui) that replaces the tmux status bar with per-window agent cards. Each card shows folder, window name, git branch, and agent status for every tmux window across all sessions.

## Card Layout

```
┌─────────────────────────────┐
│ 󰉋 dotfiles                  │  Row 1: folder (icon color = agent status)
│ ▣ 1:zsh                     │  Row 2: session icon + window_index:window_name
│ 󰊢 main                       │  Row 3: git branch (or empty)
│ ⚡ opencode                  │  Row 4: status icon + agent type
└─────────────────────────────┘
```

| Row | Content | Icon | Color Logic |
|-----|---------|------|-------------|
| 1 | `󰉋 <folder>` | 󰉋 (Nerd Font folder) | Icon color matches agent status (green/amber/red/dim) |
| 2 | `<index>:<window_name>` | ▣ (session) or ⟰ (zoomed) | Active: bright text. Inactive: dim text |
| 3 | `󰊢 <branch>` or empty | 󰊢 (Nerd Font git-branch) | Muted color. Hidden when not in a git repo |
| 4 | `<status_icon> <agent_type>` | Status icon (⚡/○/◐/✕/·) | Status icon color per state. Agent badge color per agent type |

**Active window card**: Highlighted border (`#9CDFC5` accent), bright text
**Inactive window cards**: Dim border (`#020111` matching Ghostty bg), muted text

## Color Palette

Tokyo Night–inspired palette designed for Ghostty's dark theme.

| Role | Hex | RGB | Swatch | Used For |
|------|-----|-----|--------|----------|
| Background | `#020111` | (2, 1, 17) | 🟣 | Sidebar background, inactive card borders |
| Accent | `#9CDFC5` | (156, 223, 197) | 🟢 | Active window card border, highlights |
| Text | `#FFFFFF` | (255, 255, 255) | ⚪ | Active window text |
| Dim | `#6C7086` | (108, 112, 134) | 🔘 | Inactive text, unknown status |
| Running | `#9ECE6A` | (158, 206, 106) | 🟢 | Running & background status |
| Waiting | `#E0AF68` | (224, 175, 104) | 🟡 | Waiting status |
| Idle | `#7AA2F7` | (122, 162, 247) | 🔵 | Idle status |
| Error | `#F7768E` | (247, 118, 142) | 🔴 | Error status |

### Configurable via tmux options

All colors can be overridden in `tmux-window-sidebar.conf` or via tmux options:

```bash
@ws_color_bg        "#020111"    # Background
@ws_color_accent    "#9CDFC5"    # Active window accent
@ws_color_text      "#ffffff"    # Primary text
@ws_color_dim       "#6c7086"    # Muted text
@ws_color_running   "#9ece6a"    # Running status
@ws_color_waiting   "#e0af68"    # Waiting status
@ws_color_idle      "#7aa2f7"    # Idle status
@ws_color_error     "#f7768e"    # Error status
```

## Status Icons

| Status | Icon | Color | Meaning |
|--------|------|-------|---------|
| Running | ⚡ | `#9ECE6A` (green) | Agent is actively working |
| Background | ◎ | `#9ECE6A` (green) | Agent running in background |
| Waiting | ◐ | `#E0AF68` (amber) | Agent waiting for user input |
| Idle | ○ | `#7AA2F7` (blue) | Agent idle, ready for input |
| Error | ✕ | `#F7768E` (red) | Agent encountered an error |
| Unknown | · | `#6C7086` (dim) | Status unknown |

The folder icon on Row 1 inherits the agent status color, making state visible at a glance even when Row 4 is off-screen.

## Agent Type Icons

Requires a [Nerd Font](https://www.nerdfonts.com/) installed.

| Agent | Icon | Codepoint | Nerd Font Name | Color (256) |
|-------|------|-----------|----------------|-------------|
| Claude | `󱙺` | `\u{f4b8}` | `nf-dev-robot` | 174 (dusty rose) |
| Codex | `󱙺` | `\u{f4b8}` | `nf-dev-robot` | 141 (purple) |
| OpenCode | `󰚩` | `\u{e70e}` | `nf-dev-code_badge` | 117 (cyan) |

## Semantic Icons

| Icon | Codepoint | Nerd Font Name | Used In |
|------|-----------|----------------|---------|
| 󰉋 | `\u{f07b}` | `nf-fa-folder` | Row 1 — project folder |
| 󰊢 | `\u{f126}` | `nf-fa-code_branch` | Row 3 — git branch |
| ▣ | `\u{f2d0}` | `nf-fa-window_maximize` | Row 2 — normal window |
| ⟰ | `\u{f00d3}` | `nf-md-arrow_expand_all` | Row 2 — zoomed window |

## Powerline Pill Characters

Used for the folder pill on Row 1 of active/selected cards:

| Character | Codepoint | Shape |
|-----------|-----------|-------|
| `` | `\u{e0b6}` | Right semicircle ── |
| `` | `\u{e0b4}` | Left semicircle ── |

The pill uses the agent status color as its background, with white folder text on top.

## Window Status Bar Integration

The tmux window status bar is colorized to match sidebar status:

| Agent Status | Window Status Style |
|--------------|-------------------|
| Running | `fg=#9ece6a,bg=colour235` |
| Waiting | `fg=#e0af68,bg=colour235` |
| Error | `fg=#f7768e,bg=colour235` |
| Idle | default (reset) |

Window names are prefixed with status icons: `⚡` (running), `✓` (done), `❓` (waiting), `✕` (error).

## Sound Notifications

| Option | Default | Description |
|--------|---------|-------------|
| `@agent-sound` | `Blow` | Sound when agent finishes |
| `@agent-ask-sound` | `NaviHey,NaviListen,NaviHello,NaviFairy,NaviWatchOut` | Sound when agent asks for input (randomly selected) |

Custom sounds can be placed in the `sounds/` directory.

## Keybindings

| Key | Action |
|-----|--------|
| `<prefix>e` | Toggle sidebar in current window |
| `<prefix>E` | Toggle sidebar in all windows |
| `<prefix>w` | Open popup window switcher |

### Sidebar navigation (vim-style)

| Key | Action |
|-----|--------|
| `j` / `↓` | Scroll down |
| `k` / `↑` | Scroll up |
| `g` | Jump to top |
| `G` | Jump to bottom |
| `Enter` | Switch to selected window |
| `q` / `Esc` | Close sidebar |

### Popup navigation

| Key | Action |
|-----|--------|
| `h` / `l` / `←` / `→` | Move between cards |
| `Tab` / `Shift+Tab` | Cycle through cards |
| `Enter` | Switch to selected window |
| `q` / `Esc` | Close popup |

## Build & Install

```bash
cargo build --release
# Binary installs to ~/.local/bin/tmux-window-sidebar
```

## Configuration

Key tmux options (set in `tmux-window-sidebar.conf` or via `set -g @ws_*`):

| Option | Default | Description |
|--------|---------|-------------|
| `@ws_width` | `28` | Sidebar width in columns (or `"25%"`) |
| `@ws_auto_create` | `off` | Auto-open sidebar for new windows |
| `@ws_key` | `e` | Toggle sidebar key |
| `@ws_key_all` | `E` | Toggle all windows key |
| `@ws_popup_key` | `w` | Popup window switcher key |

## Architecture

```
tmux-window-sidebar/
├── src/
│   ├── main.rs        # TUI event loop, rendering, input handling
│   ├── cli.rs         # CLI argument parsing (clap)
│   ├── tmux.rs        # tmux option queries, pane/window data
│   ├── render.rs      # Card rendering, color constants, pill drawing
│   ├── session.rs     # Session management
│   ├── sound.rs       # Sound playback (afplay)
│   └── icons.rs       # Icon/emoji constants (Nerd Font + Unicode)
├── hook.sh            # Shell bridge for Claude Code hooks
├── tmux-window-sidebar.tmux   # tmux plugin entry point
├── tmux-window-sidebar.conf   # Default tmux options
└── Cargo.toml
```

Agent events flow through hooks → `hook` subcommand → tmux options (`@pane_*`) → TUI reads on refresh.