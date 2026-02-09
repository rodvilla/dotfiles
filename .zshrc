# =============================================================================
# Zsh Configuration
# =============================================================================

# Path to dotfiles
export DOTFILES=$HOME/.dotfiles

# =============================================================================
# PATH Configuration
# =============================================================================
# Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# User local binaries (Claude CLI, etc.)
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# Zsh Options
# =============================================================================
# History improvements
setopt HIST_IGNORE_ALL_DUPS  # Don't save duplicates
setopt HIST_SAVE_NO_DUPS     # Don't write duplicates
setopt HIST_REDUCE_BLANKS    # Remove extra blanks
setopt SHARE_HISTORY         # Share history between sessions
HISTSIZE=50000
SAVEHIST=50000

# Directory navigation
setopt AUTO_CD               # cd by typing directory name
setopt AUTO_PUSHD            # Push dirs to stack automatically
setopt PUSHD_IGNORE_DUPS     # No duplicates in dir stack
setopt CDABLE_VARS           # cd to named directories

# Completion
setopt COMPLETE_IN_WORD      # Complete from cursor position
setopt ALWAYS_TO_END         # Move cursor to end after completion

# History search: type prefix then use up/down to search matching commands
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

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
# Antidote - Zsh Plugin Manager
# =============================================================================
# Set cache dir for OMZ plugins (required for docker completions, etc.)
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

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
# NVM - Node Version Manager (Lazy Loaded for Performance)
# =============================================================================
# Lazy load NVM - only initializes when you first use node/npm/nvm
lazy_load_nvm() {
  unset -f node npm npx nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
node() { lazy_load_nvm && node "$@"; }
npm() { lazy_load_nvm && npm "$@"; }
npx() { lazy_load_nvm && npx "$@"; }
nvm() { lazy_load_nvm && nvm "$@"; }

# =============================================================================
# Rbenv - Ruby Version Manager
# =============================================================================
if command -v rbenv &> /dev/null; then
  eval "$(rbenv init - zsh)"
fi

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
export HERD_PHP_81_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/81/"
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
export PATH="$HOME/Library/Application Support/Herd/bin/":$PATH

# =============================================================================
# FZF - Fuzzy Finder
# =============================================================================
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)

  # Better defaults for fzf
  export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border
    --info=inline
  '

  # Use fd for faster file finding (if installed)
  if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
  fi
fi
