#!/usr/bin/env bash
set -euo pipefail
# Strips agent icon and resets window color on focus.

PANE_ID="$1"
[ -n "$PANE_ID" ] || exit 0

CURRENT=$(tmux display-message -t "$PANE_ID" -p '#{window_name}' 2>/dev/null) || exit 0
# Keep ⚡ (working) — only clear ✓ (done) and ❓ (question)
case "$CURRENT" in
  "⚡ "*) exit 0 ;;
esac

CLEAN=$(echo "$CURRENT" | sed 's/^[✓❓] //')
[ "$CURRENT" != "$CLEAN" ] || exit 0

tmux rename-window -t "$PANE_ID" "$CLEAN" 2>/dev/null
tmux set-window-option -t "$PANE_ID" -u window-status-style 2>/dev/null
exit 0
