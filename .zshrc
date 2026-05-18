# =============================================================================
# Zsh Configuration
# =============================================================================

# Path to dotfiles
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

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
# history-search-end provides the *-end variants that move cursor to EOL after search
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# =============================================================================
# Environment Variables
# =============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Default editor (used by Ghostty +edit-config, git, etc.)
if command -v code-insiders &> /dev/null; then
  export EDITOR="code-insiders --wait"
  export VISUAL="code-insiders --wait"
elif command -v code &> /dev/null; then
  export EDITOR="code --wait"
  export VISUAL="code --wait"
else
  export EDITOR="vi"
  export VISUAL="vi"
fi

# Java / Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
if /usr/libexec/java_home -v 17 &> /dev/null; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
fi
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
export NVM_AUTOLOAD=1

# WakaTime
export ZSH_WAKATIME_PROJECT_DETECTION=true

# Claude
export CLAUDE_CODE_NO_FLICKER=1

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

# Include OMZ completion cache in fpath for docker/kubectl completions
fpath=("$ZSH_CACHE_DIR/completions" $fpath)

# Clone antidote if needed
if [[ ! -d ${ZDOTDIR:-~}/.antidote ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
fi

# Source antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# Plugin configuration (before loading)
zstyle ':omz:plugins:nvm' autoload yes

# Initialize completion system with daily dump caching
# Must run BEFORE antidote load because plugins use compdef
# -C skips the expensive fpath scan and reuses the cached dump
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Load plugins from file
antidote load ${DOTFILES}/shell/plugins.txt

# Compile zcompdump in background for faster loading
{
  if [[ -s ~/.zcompdump && (! -s ~/.zcompdump.zwc || ~/.zcompdump -nt ~/.zcompdump.zwc) ]]; then
    zcompile ~/.zcompdump
  fi
} &!

# =============================================================================
# Aliases
# =============================================================================
source ${DOTFILES}/shell/aliases.zsh

# =============================================================================
# Shell Hooks
# =============================================================================
source ${DOTFILES}/shell/hooks.zsh

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
export HERD_CONFIG_DIR="$HOME/Library/Application Support/Herd/config/php"
export HERD_PHP_81_INI_SCAN_DIR="$HERD_CONFIG_DIR/81/"
export HERD_PHP_82_INI_SCAN_DIR="$HERD_CONFIG_DIR/82/"
export HERD_PHP_83_INI_SCAN_DIR="$HERD_CONFIG_DIR/83/"
export HERD_PHP_84_INI_SCAN_DIR="$HERD_CONFIG_DIR/84/"
export PATH="$HOME/Library/Application Support/Herd/bin/:$PATH"

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



# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/84/"


# Herd injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="/Users/rodrigo/Library/Application Support/Herd/config/php/82/"
