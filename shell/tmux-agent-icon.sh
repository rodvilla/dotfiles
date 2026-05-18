#!/usr/bin/env bash
set -euo pipefail
# Claude Code hook: agent status icon on tmux window + notification sound.

LOG_FILE="${TMUX_AGENT_ICON_LOG_FILE:-/tmp/tmux-agent-icon.log}"

timestamp() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

log_debug() {
  printf '[%s] pid=%s pane=%s hook=%s active=%s event=%s\n' \
    "$(timestamp)" "$$" "${PANE_ID:-}" "${HOOK:-}" "${ACTIVE:-}" "$1" >> "$LOG_FILE" 2>/dev/null || true
}

[ -n "${TMUX:-}" ] || { cat > /dev/null; exit 0; }
PANE_ID="${TMUX_PANE:-}"
[ -n "$PANE_ID" ] || { cat > /dev/null; exit 0; }

JSON=$(cat)
HOOK="$1"
SOUND=""
COLOR=""
TOOL=""

# Check if the window is focused
ACTIVE=$(tmux display-message -t "$PANE_ID" -p '#{window_active}' 2>/dev/null) || true

case "$HOOK" in
  UserPromptSubmit) ICON="⚡" ;;
  PreToolUse)
    TOOL=$(echo "$JSON" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' \
      | head -1 | sed 's/.*"tool_name"[[:space:]]*:[[:space:]]*"//;s/"//')
    if [ "$TOOL" = "AskUserQuestion" ]; then
      ICON="❓"; SOUND="ask"; COLOR="colour196"
    else
      ICON="⚡"
    fi
    ;;
  Stop) ICON="✓"; SOUND="done"; COLOR="colour82" ;;
  Notification) exit 0 ;;
  *) exit 0 ;;
esac

log_debug "received icon=$ICON sound=${SOUND:-none} tool=${TOOL:-none}"

# Rename window
CURRENT=$(tmux display-message -t "$PANE_ID" -p '#{window_name}' 2>/dev/null) || exit 0
CLEAN=$(echo "$CURRENT" | sed 's/^[⚡✓❓] //')

# If window is focused: ⚡ always shows, but ✓/❓ just strip any existing icon
if [ "$ACTIVE" = "1" ] && [ "$ICON" != "⚡" ]; then
  log_debug "skip-focused current=$(printf '%q' "$CURRENT")"
  [ "$CURRENT" != "$CLEAN" ] && tmux rename-window -t "$PANE_ID" "$CLEAN" 2>/dev/null
  tmux set-window-option -t "$PANE_ID" -u window-status-style 2>/dev/null
  exit 0
fi

tmux rename-window -t "$PANE_ID" "$ICON $CLEAN" 2>/dev/null
log_debug "renamed window=$(printf '%q' "$CLEAN") color=${COLOR:-default}"

# Set window status color based on agent state
if [ -n "$COLOR" ]; then
  tmux set-window-option -t "$PANE_ID" window-status-style "fg=$COLOR,bg=colour235" 2>/dev/null
else
  tmux set-window-option -t "$PANE_ID" -u window-status-style 2>/dev/null
fi

# Resolve a sound name to a file path (custom dir → system sounds → absolute path)
resolve_sound() {
  local name="$1"
  local custom_dir="$HOME/.dotfiles/sounds"
  for ext in mp3 aiff wav m4a; do
    [ -f "$custom_dir/$name.$ext" ] && echo "$custom_dir/$name.$ext" && return
  done
  [ -f "/System/Library/Sounds/$name.aiff" ] && echo "/System/Library/Sounds/$name.aiff" && return
  [ -f "$name" ] && echo "$name" && return
}

# Pick a random sound from a comma-separated list and play it
pick_and_play() {
  local sound_list="$1"
  IFS=',' read -ra sounds <<< "$sound_list"
  local idx=$(( RANDOM % ${#sounds[@]} ))
  local picked
  picked=$(echo "${sounds[$idx]}" | xargs)
  if [ "$picked" = "none" ]; then
    log_debug "sound-suppressed picked=none list=$(printf '%q' "$sound_list")"
    return
  fi
  local path
  path=$(resolve_sound "$picked")
  if [ -n "$path" ]; then
    log_debug "sound-play picked=$picked path=$(printf '%q' "$path") list=$(printf '%q' "$sound_list")"
    afplay "$path" 2>/dev/null &
  else
    log_debug "sound-missing picked=$picked list=$(printf '%q' "$sound_list")"
  fi
}

# Play notification sound (background, non-blocking)
if [ -n "$SOUND" ]; then
  SOUND_NAME=$(tmux show-option -gqv @agent-sound 2>/dev/null)
  [ "$SOUND" = "ask" ] && {
    ASK_SOUND=$(tmux show-option -gqv @agent-ask-sound 2>/dev/null)
    [ -n "$ASK_SOUND" ] && SOUND_NAME="$ASK_SOUND"
  }
  : "${SOUND_NAME:=Glass}"
  if [ "$SOUND_NAME" = "none" ]; then
    log_debug "sound-disabled type=$SOUND"
  else
    log_debug "sound-selected type=$SOUND list=$(printf '%q' "$SOUND_NAME")"
    pick_and_play "$SOUND_NAME"
  fi
fi

exit 0
