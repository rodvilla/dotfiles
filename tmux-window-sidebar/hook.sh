#!/usr/bin/env bash
set -euo pipefail
# hook.sh — Thin shell wrapper for Claude/Codex hooks
# Called by Claude Code hooks configuration and Codex hooks.
# Pipes stdin JSON to the Rust binary's hook subcommand.

AGENT="${1:-}"
EVENT="${2:-}"

if [ -z "$AGENT" ] || [ -z "$EVENT" ]; then
  echo "Usage: hook.sh <agent> <event>" >&2
  echo "  agent: claude, codex, opencode" >&2
  echo "  event: session-start, session-end, user-prompt-submit, etc." >&2
  exit 1
fi

# Read JSON from stdin
JSON=$(cat)

# Forward to the Rust binary
echo "$JSON" | tmux-window-sidebar hook "$AGENT" "$EVENT"

exit 0