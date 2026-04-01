#!/usr/bin/env bash
set -euo pipefail
# Claude Code hook: agent status icon on tmux window + notification sound.

[ -n "${TMUX:-}" ] || { cat > /dev/null; exit 0; }
PANE_ID="${TMUX_PANE:-}"
[ -n "$PANE_ID" ] || { cat > /dev/null; exit 0; }

JSON=$(cat)
HOOK="$1"
SOUND=""
COLOR=""

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

# Rename window
CURRENT=$(tmux display-message -t "$PANE_ID" -p '#{window_name}' 2>/dev/null) || exit 0
CLEAN=$(echo "$CURRENT" | sed 's/^[⚡✓❓] //')

# If window is focused: ⚡ always shows, but ✓/❓ just strip any existing icon
if [ "$ACTIVE" = "1" ] && [ "$ICON" != "⚡" ]; then
  [ "$CURRENT" != "$CLEAN" ] && tmux rename-window -t "$PANE_ID" "$CLEAN" 2>/dev/null
  tmux set-window-option -t "$PANE_ID" -u window-status-style 2>/dev/null
  exit 0
fi

tmux rename-window -t "$PANE_ID" "$ICON $CLEAN" 2>/dev/null

# Set window status color based on agent state
if [ -n "$COLOR" ]; then
  tmux set-window-option -t "$PANE_ID" window-status-style "fg=$COLOR,bg=colour235" 2>/dev/null
else
  tmux set-window-option -t "$PANE_ID" -u window-status-style 2>/dev/null
fi

# Play notification sound (background, non-blocking)
if [ -n "$SOUND" ]; then
  SOUND_NAME=$(tmux show-option -gqv @agent-sound 2>/dev/null)
  [ "$SOUND" = "ask" ] && {
    ASK_SOUND=$(tmux show-option -gqv @agent-ask-sound 2>/dev/null)
    [ -n "$ASK_SOUND" ] && SOUND_NAME="$ASK_SOUND"
  }
  : "${SOUND_NAME:=Glass}"
  [ "$SOUND_NAME" = "none" ] || afplay "/System/Library/Sounds/${SOUND_NAME}.aiff" 2>/dev/null &
fi

exit 0
