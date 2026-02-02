# =============================================================================
# Shell Aliases
# =============================================================================

# General
alias c="clear"

# =============================================================================
# PHP / Laravel
# =============================================================================
alias pa="php artisan"
alias hc="herd composer"
alias hp="herd php"
alias hpa="herd php artisan"

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
# Tmux
# =============================================================================
alias t="tmux attach || tmux new -s base"

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
  alias cd="z"
fi
