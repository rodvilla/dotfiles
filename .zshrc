# Path to dotfiles
export DOTFILES=$HOME/.dotfiles

# System variables
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export NVM_AUTOLOAD=1

# External Services
export ZSH_WAKATIME_PROJECT_DETECTION=true
export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_SDK_ROOT=~/Library/Android/sdk
export ANDROID_AVD_HOME=~/.android/avd
export NVM_DIR="$HOME/.nvm"

# Tokens, API Keys, etc.
if [ -f ~/.secrets ]; then
  source ~/.secrets
fi

# Plugins options
zstyle ':omz:plugins:nvm' autoload yes

# Load zgen
source "${HOME}/.zgen/zgen.zsh"

# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load Rbenv
eval "$(rbenv init - zsh)"

# Configure Zgen
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
  zgen load zsh-users/zsh-autosuggestions
  zgen load djui/alias-tips
  zgen load sticklerm3/alehouse
  zgen load jessarcher/zsh-artisan
  zgen load chrissicool/zsh-256color
  zgen load srijanshetty/docker-zsh
  zgen load zsh-users/zsh-syntax-highlighting

  # generate the init script from plugins above
  zgen save
fi

# Alias
alias c="clear"
alias pa="php artisan"
alias doc="docker"
alias docc="docker compose"
alias doce="docker exec -it"
alias docce="docker compose exec -it"
alias docfresh="docker compose down && docker compose up -d"
alias hc="herd composer"
alias hp="herd php"
alias hpa="herd php artisan"
alias yt="yarn test"
alias ytw="yarn test --watch"
alias t="tmux attach || tmux new -s base"

# Oh My Posh only inside Tmux
if [[ -n $TMUX ]] && [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh.toml)"
fi

# Herd injected PHP 8.1 configuration.
export HERD_PHP_81_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/81/"

# Herd injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/82/"

# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/83/"

# Herd injected PHP binary.
export PATH="/Users/rodrigo/Library/Application Support/Herd/bin/":$PATH
