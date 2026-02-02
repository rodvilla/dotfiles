# =============================================================================
# Zsh Configuration
# =============================================================================

# Path to dotfiles
export DOTFILES=$HOME/.dotfiles

# =============================================================================
# Environment Variables
# =============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Java / Android
export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_SDK_ROOT=~/Library/Android/sdk
export ANDROID_AVD_HOME=~/.android/avd

# NVM
export NVM_DIR="$HOME/.nvm"
export NVM_AUTOLOAD=1

# WakaTime
export ZSH_WAKATIME_PROJECT_DETECTION=true

# =============================================================================
# Secrets (API keys, tokens, etc.)
# =============================================================================
[[ -f ~/.secrets ]] && source ~/.secrets

# =============================================================================
# NVM - Node Version Manager
# =============================================================================
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# =============================================================================
# Rbenv - Ruby Version Manager
# =============================================================================
if command -v rbenv &> /dev/null; then
  eval "$(rbenv init - zsh)"
fi

# =============================================================================
# Antidote - Zsh Plugin Manager
# =============================================================================
# Clone antidote if needed
if [[ ! -d ${ZDOTDIR:-~}/.antidote ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
fi

# Source antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# Plugin configuration (before loading)
zstyle ':omz:plugins:nvm' autoload yes

# Load plugins from file
antidote load ${DOTFILES}/shell/plugins.txt

# =============================================================================
# Aliases
# =============================================================================
source ${DOTFILES}/shell/aliases.zsh

# =============================================================================
# Oh My Posh Prompt
# =============================================================================
# Load Oh My Posh in supported terminals (iTerm2, Ghostty, tmux)
# Skip in basic Apple Terminal
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
  if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/config.toml)"
  fi
fi

# =============================================================================
# Herd PHP Configuration
# =============================================================================
export HERD_PHP_81_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/81/"
export HERD_PHP_82_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_83_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/83/"
export PATH="/Users/rodrigo/Library/Application Support/Herd/bin/":$PATH

# =============================================================================
# FZF - Fuzzy Finder
# =============================================================================
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi
