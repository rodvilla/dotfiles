#!/usr/bin/env bash
set -euo pipefail
# tmux-hook.sh — Claude Code hook bridge for tmux-window-sidebar
# Maps Claude Code hook triggers to `tmux-window-sidebar hook claude <event>` calls.
# Reads JSON from stdin and pipes it to the Rust binary.
# Lives at ~/.dotfiles/shell/tmux-hook.sh

AGENT="$1"    # claude
EVENT="$2"    # e.g. session-start, stop, notification

if [ -z "${AGENT:-}" ] || [ -z "${EVENT:-}" ]; then
  echo "Usage: tmux-hook.sh <agent> <event>" >&2
  exit 1
fi

# Read JSON from stdin (Claude Code hooks pipe JSON via stdin)
JSON=$(cat)

# Call the Rust binary's hook subcommand
echo "$JSON" | tmux-window-sidebar hook "$AGENT" "$EVENT"

exit 0