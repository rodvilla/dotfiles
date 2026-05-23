#!/usr/bin/env bash
set -euo pipefail
# Clears agent status icon and resets pane options when switching to a window.
# Works with both the old tmux-agent-icon system and the new tmux-window-sidebar system.

PANE_ID="$1"
[ -n "$PANE_ID" ] || exit 0

# Clear window name icon prefix (⚡, ✓, ❓, ✕)
CURRENT=$(tmux display-message -t "$PANE_ID" -p '#{window_name}' 2>/dev/null) || exit 0

# Keep ⚡ (working) — only clear ✓ (done), ❓ (question), ✕ (error)
case "$CURRENT" in
  "⚡ "*) exit 0 ;;
esac

CLEAN=$(echo "$CURRENT" | sed 's/^[✓❓✕] //')
if [ "$CURRENT" != "$CLEAN" ]; then
  tmux rename-window -t "$PANE_ID" "$CLEAN" 2>/dev/null || true
fi

# Reset window status style
tmux set-window-option -t "$PANE_ID" -u window-status-style 2>/dev/null || true

# Clear pane attention flag (new sidebar system)
tmux set-option -p -t "$PANE_ID" -u @pane_attention 2>/dev/null || true

exit 0