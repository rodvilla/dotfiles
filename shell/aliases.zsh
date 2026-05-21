# =============================================================================
# Shell Aliases
# =============================================================================

# General
alias c="clear"
alias ghost="/Applications/Ghostty.app/Contents/MacOS/ghostty"
alias t="tmux attach || tmux new -s base"

# =============================================================================
# PHP / Laravel
# =============================================================================
alias pa="php artisan"
alias hc="herd composer"
alias hp="herd php"
alias hpa="herd php artisan"

# =============================================================================
# Homebrew
# =============================================================================
alias brupd="brew update"
alias brupg="brew upgrade"
alias brcle="brew cleanup"
alias bis="brew install"
alias bru="brew uninstall"

# =============================================================================
# Docker
# =============================================================================
alias doc="docker"
alias docc="docker compose"
alias doce="docker exec -it"
alias docce="docker compose exec -it"
alias docfresh="docker compose down && docker compose up -d"

# =============================================================================
# Node / Yarn
# =============================================================================
alias yt="yarn test"
alias ytw="yarn test --watch"

# =============================================================================
# Editor
# =============================================================================
if command -v code-insiders &> /dev/null; then
  alias code="code-insiders"
fi
alias v="nvim"

# =============================================================================
# AI
# =============================================================================
alias cl="claude"
alias cld="claude --dangerously-skip-permissions"
alias oco="opencode"
alias ocom="opencode models"

_dev_tmux_layout() {
  local agent_cmd="$1"
  local editor_cmd="${2:-nvim .}"
  local layout_script="${HOME}/.dotfiles/shell/dev-tmux-layout.zsh"

  zsh "$layout_script" start "$agent_cmd" "$editor_cmd"
}

agent_layout() {
  local editor_cmd="${1:-nvim .}"
  local layout_script="${HOME}/.dotfiles/shell/dev-tmux-layout.zsh"

  zsh "$layout_script" attach "" "" "$editor_cmd"
}

ccs() {
  _dev_tmux_layout "cld"
}

ocs() {
  _dev_tmux_layout "opencode"
}

# =============================================================================
# Modern CLI replacements (if installed)
# =============================================================================
# Better ls with eza
if command -v eza &> /dev/null; then
  alias ls="eza"
  alias ll="eza -l"
  alias la="eza -la"
  alias lt="eza --tree"
fi

# Better cat with bat
if command -v bat &> /dev/null; then
  alias cat="bat --paging=never"
fi

# Smarter cd with zoxide
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

tmux_hotkeys() {
  local prefix="Ctrl-a"

  if [[ -t 1 ]]; then
    printf '\033[1;36mTMUX HOTKEYS\033[0m\n'
  else
    printf 'TMUX HOTKEYS\n'
  fi

  printf '\nPrefix: %s\n' "$prefix"
  printf '  %s d      detach session\n' "$prefix"
  printf '  %s r      reload ~/.tmux.conf\n' "$prefix"
  printf '  %s f      fuzzy switch window/session\n' "$prefix"
  printf '  %s O      SessionX session manager\n' "$prefix"
  printf '  %s g      popup shell in current path\n' "$prefix"
  printf '  %s A      wrap current agent in coding layout\n' "$prefix"

  printf '\nWindows\n'
  printf '  %s c      new window in ~/Developer\n' "$prefix"
  printf '  %s ,      rename current window\n' "$prefix"
  printf '  %s 1..9   jump to window by number\n' "$prefix"
  printf '  %s n/p    next / previous window\n' "$prefix"
  printf '  %s w      list windows\n' "$prefix"

  printf '\nPanes\n'
  printf '  %s |      split horizontally\n' "$prefix"
  printf '  %s -      split vertically\n' "$prefix"
  printf '  %s h/j/k/l  move pane\n' "$prefix"
  printf '  Alt+Arrows  move pane without prefix\n'
  printf '  %s H/J/K/L  resize pane\n' "$prefix"
  printf '  %s z      zoom / unzoom pane\n' "$prefix"
  printf '  %s x      kill pane\n' "$prefix"

  printf '\nCopy Mode\n'
  printf '  %s v      enter copy mode\n' "$prefix"
  printf '  v         begin selection\n'
  printf '  y         copy selection to clipboard\n'
  printf '  Enter     copy selection to clipboard\n'

  printf '\nSessionX\n'
  printf '  Type a new name and press Enter to create a session\n'
  printf '  Ctrl-w    switch to window mode\n'
  printf '  Ctrl-e    expand from current path\n'
  printf '  Ctrl-x    browse configured paths\n'
  printf '  Ctrl-r    rename selected session\n'
  printf '  Alt-Backspace  delete selected session\n'
}

th() {
  tmux_hotkeys
}
