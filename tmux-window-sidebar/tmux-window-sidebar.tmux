#!/usr/bin/env bash
# tmux-window-sidebar.tmux — TPM entry point
# Installs the tmux-window-sidebar plugin: builds the Rust binary and sets up keybindings.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="$HOME/.local/bin/tmux-window-sidebar"

# Build the Rust binary if not already built
ensure_binary() {
  local src_path="$CURRENT_DIR/target/release/tmux-window-sidebar"
  if [ ! -f "$src_path" ]; then
    tmux display-message -p "Building tmux-window-sidebar..."
    (cd "$CURRENT_DIR" && cargo build --release 2>/dev/null)
  fi

  # Symlink to a location in PATH
  mkdir -p "$HOME/.local/bin"
  ln -sf "$src_path" "$BIN_PATH"
}

# Get tmux option with default
get_option() {
  local option="$1"
  local default="$2"
  local value
  value=$(tmux show-option -gqv "$option" 2>/dev/null)
  if [ -z "$value" ]; then
    echo "$default"
  else
    echo "$value"
  fi
}

# Set up keybindings
setup_keybindings() {
  local toggle_key
  toggle_key=$(get_option "@ws_key" "e")
  local toggle_all_key
  toggle_all_key=$(get_option "@ws_key_all" "E")

  tmux bind-key "$toggle_key" run-shell -b "$BIN_PATH toggle"
  tmux bind-key "$toggle_all_key" run-shell -b "$BIN_PATH toggle-all"
}

# Set up hooks for instant refresh on window/pane changes
setup_hooks() {
  tmux set-hook -g after-select-window "run-shell -b \"$BIN_PATH hook internal refresh\""
  tmux set-hook -g after-select-pane "run-shell -b \"$BIN_PATH hook internal refresh\""
}

# Set up auto-create for new windows
setup_auto_create() {
  local auto_create
  auto_create=$(get_option "@ws_auto_create" "on")
  if [ "$auto_create" = "on" ]; then
    tmux set-hook -g after-new-window "run-shell -b \"$BIN_PATH toggle\""
  fi
}

main() {
  ensure_binary
  setup_keybindings
  setup_hooks
  setup_auto_create
}

main