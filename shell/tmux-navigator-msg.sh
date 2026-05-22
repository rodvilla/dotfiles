#!/usr/bin/env zsh
set -euo pipefail

pane_id="$1"
shift

direction="$1"

case "$direction" in
  left)  target_cmd="C-h" ;;
  down)  target_cmd="C-j" ;;
  up)    target_cmd="C-k" ;;
  right) target_cmd="C-l" ;;
esac

tmux send-keys -t "$pane_id" "$target_cmd"