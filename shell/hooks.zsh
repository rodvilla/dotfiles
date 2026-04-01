# =============================================================================
# Shell Hooks (chpwd, precmd, etc.)
# =============================================================================

# Auto-rename tmux window based on current directory
# Inside ~/Developer/* → window name = folder basename
# Outside ~/Developer  → window name = "zsh"
#
# Guarded: only runs in the shell directly owned by the tmux pane,
# so coding-agent subshells (Claude Code, opencode, etc.) won't
# hijack the window name.

function _auto_rename_tmux_window() {
  [[ -n "$TMUX" ]] || return
  [[ "$$" == "$_TMUX_PANE_PID" ]] || return

  local name
  if [[ "$PWD" = "$HOME/Developer/"* ]]; then
    name="${PWD##*/}"
  else
    name="zsh"
  fi

  # Preserve agent status icon (⚡/✓/❓) if present on current window
  local current icon=""
  current=$(command tmux display-message -p '#{window_name}')
  if [[ "$current" =~ ^(⚡|✓|❓)" " ]]; then
    icon="${match[1]} "
  fi

  command tmux rename-window "${icon}${name}"
}

# Cache the pane's direct-child PID once at startup (avoids calling
# tmux on every cd).  $$ is the PID of *this* shell; it will only
# match _TMUX_PANE_PID when we are the top-level pane shell.
if [[ -n "$TMUX" ]]; then
  _TMUX_PANE_PID=$(command tmux display-message -p '#{pane_pid}')
fi

chpwd_functions+=(_auto_rename_tmux_window)

# Run once at startup (handles opening a shell already inside ~/Developer)
_auto_rename_tmux_window
