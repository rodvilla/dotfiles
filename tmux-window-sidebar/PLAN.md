# tmux-window-sidebar — Full Specification

A tmux sidebar (Rust TUI using ratatui + crossterm) that **replaces the tmux status bar**, showing per-window information cards stacked vertically. Each card shows folder, window name, git branch, and agent status for every tmux window across all sessions.

## 1. Card Layout

Each tmux window renders as a card:

```
┌─────────────────────────┐
│ 󰉋 dotfiles              │  Row 1: 󰉋 folder (icon color = agent status)
│ 1:zsh                    │  Row 2: window_index:window_name
│ 󰥔 main                   │  Row 3: 󰥔 git branch (or empty)
│ ⚡ opencode              │  Row 4: status icon + agent type badge
└─────────────────────────┘
```

**Row details**:

| Row | Content | Icon | Color Logic |
|-----|---------|------|-------------|
| 1 | `󰉋 <folder>` | 󰉋 (folder Nerd Font icon) | Folder icon color matches agent status: green=running, yellow=waiting, dim=idle, red=error |
| 2 | `<index>:<window_name>` | No icon | Active window: bright text. Inactive: dim text |
| 3 | `󰥔 <branch>` or empty | 󰥔 (git-branch Nerd Font) | Muted color. Hidden if not in a git repo |
| 4 | `<status_icon> <agent_type>` | Status icon (⚡/○/◐/✕/·) | Status icon color per state. Agent badge color per agent type |

**Active window card**: Highlighted border (`#9CDFC5` accent), bright text  
**Inactive window cards**: Dim border (`#020111` matching Ghostty bg), muted text

### Agent Icons (Nerd Fonts)

| Agent | Icon | Color (256) |
|-------|------|------------|
| Claude | `󱙺` (or `󰧑`) | 174 (dusty rose) |
| Codex | `󱙺` (codex variant) | 141 (purple) |
| OpenCode | `󰚩` | 117 (cyan) |
| No agent | (row 4 hidden) | — |

### Status Icons

| Status | Icon | Color |
|--------|------|-------|
| Running | ⚡ | 114 (green) |
| Background | ◎ | 114 (green) |
| Waiting | ◐ | 221 (yellow) |
| Idle | ○ | 110 (dim cyan) |
| Error | ✕ | 167 (red) |
| Unknown | · | 244 (gray) |

### Folder Icon as Status Indicator (Row 1)

The `󰉋` folder icon on Row 1 uses the **agent status color** — making the card's state visible at a glance even when row 4 is off-screen or the card is scrolled out of view.

---

## 2. Agent Event Hooks

### 2.1 Supported Events (all 16 from hiroppy's adapter layer)

The OpenCode plugin and Claude Code hooks fire these via the Rust binary's `hook` subcommand:

| Event | Claude Code Hook | OpenCode Plugin | Used By Sidebar |
|-------|-----------------|----------------|----------------|
| session-start | `SessionStart` | `session.created` | Set @pane_agent, @pane_cwd, @pane_permission_mode, @pane_session_id, rename window |
| session-end | `SessionEnd` | (via session.idle/error) | Clear all pane meta, notifications |
| user-prompt-submit | `UserPromptSubmit` | `chat.message` + `tool.execute.before` | Set @pane_status=running, @pane_prompt, rename window with ⚡ |
| notification | `Notification` | `permission.ask` / `event(session.status.busy)` | Set @pane_status=waiting, @pane_attention, sound |
| stop | `Stop` | `session.idle` | Set @pane_status=idle, rename window with ✓, sound |
| stop-failure | `StopFailure` | — | Set @pane_status=error, ✕ icon, sound |
| permission-denied | `PermissionDenied` | — | Set @pane_attention, notification |
| cwd-changed | `CwdChanged` | — | Update @pane_cwd |
| subagent-start | `SubagentStart` | — | Append to @pane_subagents |
| subagent-stop | `SubagentStop` | — | Remove from @pane_subagents |
| activity-log | `PostToolUse` | `tool.execute.after` | Write activity log (for future use) |
| task-created | `TaskCreated` | — | (Future: progress bar) |
| task-completed | `TaskCompleted` | — | Notification |
| teammate-idle | `TeammateIdle` | — | Notification |
| worktree-create | `WorktreeCreate` | — | (Future) |
| worktree-remove | `WorktreeRemove` | — | (Future) |

### 2.2 Window Name Sync

When a session starts (or a session name becomes known), the tmux window name is updated to match the agent session name:

1. **Claude**: Scan `~/.claude/sessions/<sessionID>.json` → read `name` field
2. **OpenCode**: Use `sessionID` → call `client.session.get()` → read session name
3. On `session-start` hook: set `@pane_session_id` → background thread resolves name → `tmux rename-window`

This replaces the current icon-prefix window naming (`⚡ zsh`) with session-aware naming (`⚡ my-feature-branch`).

### 2.3 Sound Notifications

Carried over from existing `tmux-agent-icon.sh`:

- **Done sound** (agent finishes): Random from `@agent-sound` (default: `Blow`)
- **Ask sound** (agent needs input): Random from `@agent-ask-sound` (default: `NaviHey,NaviListen,...`)
- **3-second debounce** on done sounds (from `tmux-agent-status.ts`)
- **Custom sound resolution**: `~/.dotfiles/sounds/` → `/System/Library/Sounds/` → absolute path
- Sound played when window is **not focused** (from `tmux-agent-icon.sh`)

### 2.4 Pane Options Written by Hooks

These tmux pane user options serve as the data bus between hooks and the TUI:

| Option | Set By | Purpose |
|--------|--------|---------|
| `@agent` | Session start | Agent type: `claude`, `codex`, `opencode` |
| `@pane_status` | Every hook | `running`, `idle`, `waiting`, `error`, `background` |
| `@pane_prompt` | User prompt submit | Truncated current prompt |
| `@pane_prompt_source` | User prompt submit | `user` or `system` |
| `@pane_cwd` | Session start, cwd-changed | Agent's working directory |
| `@pane_permission_mode` | Session start | `default`, `plan`, `auto`, `dontAsk`, `bypassPermissions`, `defer` |
| `@pane_session_id` | Session start | For name resolution |
| `@pane_started_at` | User prompt submit | Unix timestamp of run start |
| `@pane_wait_reason` | Notification | Why agent is waiting |
| `@pane_attention` | Notification | `1` if needs attention |
| `@pane_worktree_name` | Session start (in worktree) | Worktree name |
| `@pane_worktree_branch` | Session start (in worktree) | Worktree branch |
| `@pane_subagents` | Subagent start/stop | Comma-separated subagent list |
| `@pane_bg_cmd` | Background shell | Running background command |
| `@pane_name` | Session name resolution | Human-readable session name |

---

## 3. OpenCode Plugin: `tmux-window-sidebar.ts`

Replaces `tmux-agent-status.ts`. Lives at `~/.dotfiles/config/opencode/plugins/tmux-window-sidebar.ts`.

**Event mappings** (matching hiroppy's OpenCode adapter):

```typescript
// Lifecycle events:
"session.created"       → hook("session-start", { cwd, session_id, source: "startup" })
"session.idle"          → hook("stop", { cwd, session_id, last_message: "" })
"session.error"         → hook("stop-failure", { cwd, session_id, error })
"session.status"(busy)  → hook("user-prompt-submit", { cwd, session_id, prompt: "" })

// Tool events:
"tool.execute.before"   → hook("user-prompt-submit" or set status=running)
"tool.execute.after"    → hook("activity-log", { tool_name, tool_input, tool_response })

// Permission:
"permission.ask"        → hook("notification", { cwd, session_id, wait_reason: "permission" })
```

**Session name resolution**: On `session.created`, call `client.session.get()` to fetch the session name, then `tmux set-option -p @pane_name <name>` and `tmux rename-window <name>`.

**Sound playback**: Same logic as current plugin (random from comma list, debounce, custom sound paths).

**Subagent detection**: Same as current — call `client.session.get()` and skip if `parentID` exists.

---

## 4. Claude Code Hook: `tmux-hook.sh`

A bash script (replacing `tmux-agent-icon.sh`) that maps Claude Code hook triggers to `tmux-window-sidebar hook claude <event>` calls. Lives at `~/.dotfiles/shell/tmux-hook.sh`.

**Hook registrations** (16 triggers, matching hiroppy's ClaudeAdapter):

```json
{
  "hooks": {
    "SessionStart":       [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude session-start" }],
    "SessionEnd":         [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude session-end" }],
    "UserPromptSubmit":   [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude user-prompt-submit" }],
    "Notification":       [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude notification" }],
    "Stop":               [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude stop" }],
    "StopFailure":        [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude stop-failure" }],
    "PermissionDenied":   [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude permission-denied" }],
    "CwdChanged":         [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude cwd-changed" }],
    "SubagentStart":      [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude subagent-start" }],
    "SubagentStop":       [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude subagent-stop" }],
    "PostToolUse":        [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude activity-log" }],
    "TaskCreated":        [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude task-created" }],
    "TaskCompleted":      [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude task-completed" }],
    "TeammateIdle":       [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude teammate-idle" }],
    "WorktreeCreate":     [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude worktree-create" }],
    "WorktreeRemove":     [{ "command": "~/.dotfiles/shell/tmux-hook.sh claude worktree-remove" }]
  }
}
```

The hook script reads JSON from stdin and pipes it to the Rust binary: `tmux-window-sidebar hook claude <event>` (same pattern as hiroppy's `hook.sh`).

---

## 5. Rust Binary Architecture

### 5.1 Module Structure

```
tmux-window-sidebar/
├── Cargo.toml
├── src/
│   ├── main.rs            # CLI entry, TUI bootstrap, SIGUSR1 handler
│   ├── app.rs             # Event loop: poll + render
│   ├── state.rs           # AppState: window cards, focus, scroll
│   ├── tmux.rs            # Query sessions/windows/panes + pane options
│   ├── render.rs          # ratatui rendering: card layout
│   ├── hook.rs            # CLI `hook` subcommand: set pane options
│   ├── sound.rs           # macOS sound playback (afplay)
│   ├── session.rs         # Scan ~/.claude/sessions/ for names
│   ├── cli.rs             # CLI subcommand dispatch
│   └── icons.rs           # Agent/status icon constants
├── tmux-window-sidebar.tmux   # TPM entry point
├── tmux-window-sidebar.conf   # tmux config (keybindings, hooks)
├── hook.sh                     # Thin shell wrapper for Claude/Codex hooks
└── .opencode/plugins/
    └── tmux-window-sidebar.js  # OpenCode plugin bridge
```

### 5.2 Key Data Types

```rust
struct WindowCard {
    window_id: String,
    window_name: String,
    window_active: bool,
    session_name: String,
    folder: String,            // basename(pane_current_path)
    git_branch: Option<String>,
    agent: Option<AgentInfo>,
}

struct AgentInfo {
    agent_type: AgentType,     // Claude, Codex, OpenCode, Unknown
    status: PaneStatus,         // Running, Background, Waiting, Idle, Error, Unknown
    prompt: String,             // truncated current prompt
    permission_mode: String,    // default, plan, auto, etc.
    session_id: Option<String>,
    session_name: Option<String>,
    wait_reason: String,
    subagents: Vec<String>,
    started_at: Option<u64>,
}

enum PaneStatus { Running, Background, Waiting, Idle, Error, Unknown }
enum AgentType { Claude, Codex, OpenCode, Unknown }
```

### 5.3 Refresh Strategy

Same as hiroppy's:

1. **Periodic poll** (1s): Re-query all sessions/windows/panes + pane options
2. **SIGUSR1** (instant): On `after-select-window`, `after-select-pane` — sets flag, causes immediate re-render
3. **Hook-driven**: pane options set by hooks → picked up on next poll

### 5.4 Key Behaviors

- **Auto-create sidebar**: Open in every window on launch (configurable via `@ws_auto_create`)
- **Toggle**: `prefix+e` toggles in current window, `prefix+E` toggles everywhere
- **Status bar**: Hidden when sidebar is open (`set -g status off`), restored on close
- **Auto-close**: Window closes when only sidebar pane remains (same as hiroppy's)
- **Session name sync**: When `@pane_session_id` is set, background thread resolves name from `~/.claude/sessions/` → sets `@pane_name` → renames tmux window

---

## 6. Configuration

tmux options (all with `@ws_` prefix to avoid collision):

```tmux
# Sidebar width (default: 25%)
set -g @ws_width "25%"

# Auto-create sidebar for new windows (default: on)
set -g @ws_auto_create "on"

# Toggle keybindings (default: e/E)
set -g @ws_key "e"
set -g @ws_key_all "E"

# Notification sounds (macOS)
set -g @agent-sound "Blow"
set -g @agent-ask-sound "NaviHey,NaviListen,NaviHello,NaviFairy,NaviWatchOut,NaviLook"

# Colors (matching Ghostty theme)
set -g @ws_color_bg "#020111"
set -g @ws_color_accent "#9CDFC5"
set -g @ws_color_text "#ffffff"
set -g @ws_color_dim "#6c7086"
set -g @ws_color_running "#9ece6a"     # green
set -g @ws_color_waiting "#e0af68"     # yellow
set -g @ws_color_idle "#7aa2f7"        # blue
set -g @ws_color_error "#f7768e"       # red
```

---

## 7. Files to Create/Modify

### New files (in `~/.dotfiles/`):

| File | Purpose |
|------|---------|
| `tmux-window-sidebar/` | Full Rust project directory |
| `tmux-window-sidebar/src/*.rs` | All Rust source files |
| `tmux-window-sidebar/Cargo.toml` | Dependencies: ratatui, crossterm, serde_json |
| `tmux-window-sidebar/tmux-window-sidebar.tmux` | TPM bootstrap script |
| `tmux-window-sidebar/tmux-window-sidebar.conf` | tmux config for hooks/keybindings |
| `tmux-window-sidebar/hook.sh` | Claude/Codex hook shell wrapper |
| `tmux-window-sidebar/.opencode/plugins/tmux-window-sidebar.js` | OpenCode plugin bridge |
| `config/opencode/plugins/tmux-window-sidebar.ts` | OpenCode TypeScript plugin (replaces `tmux-agent-status.ts`) |
| `shell/tmux-hook.sh` | Claude Code hook script (replaces `tmux-agent-icon.sh`) |

### Modified files:

| File | Change |
|------|--------|
| `.tmux.conf` | Add plugin, change keybindings, hide status bar when sidebar open |
| `shell/tmux-agent-clear.sh` | Update to work with new pane options |
| `config/opencode/plugins/tmux-agent-status.ts` | Remove (replaced by `tmux-window-sidebar.ts`) |
| `shell/tmux-agent-icon.sh` | Remove (replaced by `tmux-hook.sh`) |

---

## 8. Differences from hiroppy/tmux-agent-sidebar

| Feature | hiroppy | This plugin |
|---------|---------|------------|
| Layout | Scrolling agent list + bottom tabs | Stacked window cards, no tabs |
| Purpose | Agent monitoring dashboard | Status bar replacement |
| Git info | Full diff stats, staged/unstaged, PR links | Branch name only |
| Activity log | Tool-by-tool history | None (future) |
| Worktree spawn/remove | Full lifecycle | Deferred to v2 |
| Pet animation | Yes | No |
| Custom colors | 30+ options | ~8, matching Ghostty theme |
| Session name sync | Yes (background scan) | Yes (same approach) |
| Sound notifications | Desktop notifications (osascript) | Same + existing random sound picker |
| Code size | ~5000+ LOC Rust | Estimated ~1000-1500 LOC |
| Project location | Separate GitHub repo | `~/.dotfiles/tmux-window-sidebar/` |

---

## 9. Implementation Order

1. **Rust project scaffold** — Cargo.toml, main.rs, TUI bootstrap
2. **tmux query module** — sessions, windows, panes, pane options
3. **State model** — WindowCard, AgentInfo, AppState
4. **Renderer** — card layout with ratatui
5. **Hook CLI** — `tmux-window-sidebar hook <agent> <event>` subcommand
6. **OpenCode plugin** — `tmux-window-sidebar.ts`
7. **Claude Code hook** — `tmux-hook.sh`
8. **Session name sync** — background thread scanning `~/.claude/sessions/`
9. **Sound system** — port from `tmux-agent-icon.sh`
10. **tmux integration** — TPM install script, keybindings, status bar toggle
11. **Window name sync** — rename tmux windows based on session names
12. **Git branch detection** — per-pane `git branch --show-current`