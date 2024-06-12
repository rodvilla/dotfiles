# Path to dotfiles
export DOTFILES=$HOME/.dotfiles

# System variables
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export NVM_AUTOLOAD=1

# External Services
export ZSH_WAKATIME_PROJECT_DETECTION=true
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_SDK_ROOT=~/Library/Android/sdk
export ANDROID_AVD_HOME=~/.android/avd

# GH Token, etc
if [ -f ~/.secrets ]; then
  source ~/.secrets
fi

# Plugin options
zstyle ':omz:plugins:nvm' autoload yes

# Load zgen
source "${HOME}/.zgen/zgen.zsh"

if [[ -z $TMUX ]]; then
  # Edit the path only once
  export PATH=/opt/homebrew/bin:$PATH
  export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/platform-tools
  export PATH=$PATH:~/.composer/vendor/bin

# Herd injected PHP binary.
export PATH="/Users/rodrigo/Library/Application Support/Herd/bin/":$PATH
fi

if ! zgen saved; then
  # Oh My Zsh plugins
  zgen oh-my-zsh
  zgen oh-my-zsh plugins/aws
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/macos
  zgen oh-my-zsh plugins/tmux
  zgen oh-my-zsh plugins/nvm
  zgen oh-my-zsh plugins/extract
  # Other plugins
  zgen load unixorn/autoupdate-zgen
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load zsh-users/zsh-autosuggestions
  zgen load djui/alias-tips
  zgen load sticklerm3/alehouse
  zgen load jessarcher/zsh-artisan
  zgen load chrissicool/zsh-256color
  zgen load srijanshetty/docker-zsh

  # generate the init script from plugins above
  zgen save
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Spaceship prompt options
SPACESHIP_TIME_SHOW=true

# Alias
alias c="clear"
alias pa="php artisan"

# Docker
alias doc="docker"
alias docc="docker compose"
alias doce="docker exec -it"
alias docce="docker compose exec -it"
alias doceb='docker run --platform linux/amd64 --rm -it -v $HOME/.aws:/root/.aws -v $HOME/.ssh:/root/.ssh -v $(pwd)/.elasticbeanstalk:/.elasticbeanstalk lawnstarter/awsebcli'
alias docfresh="docker compose down && docker compose up -d"

alias ytw="yarn test --watch"

alias hpa="herd php artisan"
alias hc="herd composer"

# Herd injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/82/"

# Herd injected PHP 8.1 configuration.
export HERD_PHP_81_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/81/"

eval "$(rbenv init - zsh)"
eval "$(starship init zsh)"
