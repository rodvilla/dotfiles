#!/usr/bin/env zsh
set -euo pipefail

_usage() {
  cat >&2 <<'EOF'
Usage:
  dev-tmux-layout.zsh start <agent-command> [editor-command]
  dev-tmux-layout.zsh attach [agent-pane] [cwd] [editor-command]

Modes:
  start   Use the current shell pane as the bottom terminal, create an agent pane
          and editor pane above it, then zoom the agent pane.
  attach  Treat the target/current pane as an already-running agent, add the
          editor pane and bottom terminal around it, then zoom the agent pane.
EOF
}

_require_tmux() {
  if [[ -z "${TMUX:-}" ]]; then
    printf 'dev-tmux-layout: run this inside a tmux session.\n' >&2
    return 1
  fi

  if ! command -v tmux &> /dev/null; then
    printf 'dev-tmux-layout: tmux is not available.\n' >&2
    return 1
  fi
}

_pane_path() {
  local pane="$1"
  command tmux display-message -p -t "$pane" '#{pane_current_path}'
}

_current_pane() {
  command tmux display-message -p '#{pane_id}'
}

_unzoom_window_if_needed() {
  local pane="$1"

  if [[ "$(command tmux display-message -p -t "$pane" '#{window_zoomed_flag}')" == "1" ]]; then
    command tmux resize-pane -Z -t "$pane"
  fi
}

_send_command() {
  local pane="$1"
  local cmd="$2"

  command tmux send-keys -t "$pane" "$cmd" C-m
}

_zoom_agent_pane() {
  local agent_pane="$1"

  command tmux select-pane -t "$agent_pane"
  command tmux resize-pane -Z -t "$agent_pane"
}

_start_layout() {
  local agent_cmd="$1"
  local editor_cmd="${2:-nvim .}"
  local cwd="${PWD:A}"
  local bottom_pane top_left_pane top_right_pane

  bottom_pane="$(_current_pane)" || return 1
  _unzoom_window_if_needed "$bottom_pane"

  # Keep the current shell as the bottom command pane (20% height),
  # then create the top row above it (80% height).
  top_left_pane="$(command tmux split-window -v -b -p 80 -c "$cwd" -t "$bottom_pane" -P -F '#{pane_id}')" || return 1

  # Split the top row into a 60% left agent pane and a 40% right editor pane.
  top_right_pane="$(command tmux split-window -h -p 40 -c "$cwd" -t "$top_left_pane" -P -F '#{pane_id}')" || return 1

  _send_command "$top_left_pane" "$agent_cmd"
  _send_command "$top_right_pane" "$editor_cmd"
  _zoom_agent_pane "$top_left_pane"
}

_attach_layout() {
  local agent_pane="${1:-}"
  local cwd="${2:-}"
  local editor_cmd="${3:-nvim .}"
  local bottom_pane editor_pane

  if [[ -z "$agent_pane" ]]; then
    agent_pane="$(_current_pane)" || return 1
  fi

  if [[ -z "$cwd" ]]; then
    cwd="$(_pane_path "$agent_pane")" || return 1
  fi

  _unzoom_window_if_needed "$agent_pane"

  # The target pane is already the agent. Add a bottom terminal (20%) below it,
  # then split the remaining top row into agent (60%) and editor (40%).
  bottom_pane="$(command tmux split-window -v -p 20 -c "$cwd" -t "$agent_pane" -P -F '#{pane_id}')" || return 1
  editor_pane="$(command tmux split-window -h -p 40 -c "$cwd" -t "$agent_pane" -P -F '#{pane_id}')" || return 1

  _send_command "$editor_pane" "$editor_cmd"
  _zoom_agent_pane "$agent_pane"
}

main() {
  _require_tmux || return 1

  local mode="${1:-}"
  shift || true

  case "$mode" in
    start)
      if [[ $# -lt 1 ]]; then
        _usage
        return 1
      fi
      _start_layout "$@"
      ;;
    attach)
      _attach_layout "$@"
      ;;
    -h|--help|help|'')
      _usage
      ;;
    *)
      printf 'dev-tmux-layout: unknown mode: %s\n\n' "$mode" >&2
      _usage
      return 1
      ;;
  esac
}

main "$@"
