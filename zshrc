# System variables
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export ZSH_WAKATIME_PROJECT_DETECTION=true

# Load zgen
source "${HOME}/.zgen/zgen.zsh"

if [[ -z $TMUX ]]; then
  # Edit the path only once!
  export PATH="/Users/rodrigo/.composer/vendor/bin:/usr/local/opt/node@10/bin:/usr/local/sbin:$PATH"
fi

# If the init scipt doesn't exist
if ! zgen saved; then
  # Oh My Zsh plugins
  zgen oh-my-zsh
  zgen oh-my-zsh plugins/aws
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/osx
  zgen oh-my-zsh plugins/tmux
  zgen oh-my-zsh plugins/extract
  zgen load unixorn/autoupdate-zgen
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load zsh-users/zsh-autosuggestions
  zgen load djui/alias-tips
  zgen load sticklerm3/alehouse
  zgen load jessarcher/zsh-artisan
  zgen load chrissicool/zsh-256color
  zgen load srijanshetty/docker-zsh
  zgen load denysdovhan/spaceship-prompt spaceship

  # generate the init script from plugins above
  zgen save
fi

# Spaceship prompt options
SPACESHIP_TIME_SHOW=true

# Alias
alias c="clear"
alias pa="php artisan"

# Docker
alias doc="docker"
alias docc="docker-compose"
alias doce="docker exec -it"

SECRETS="${HOME}/.secrets"
if [[ -f "$SECRETS" ]]; then
    source "$SECRETS"
fi

