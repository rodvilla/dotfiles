#!/bin/bash
# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# Usage: ./install.sh <profile>
#
# Profiles:
#   workstation   - Full development environment (IDEs, databases, etc.)
#   media-server  - Basic shell setup for remote access
#   minimal       - Just shell and essential CLI tools
#   links-only    - Only create directories and symlinks, no package installs
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
DOTFILES_DIR="$HOME/.dotfiles"
BREWFILE_BASE="$DOTFILES_DIR/Brewfile"

# =============================================================================
# Show usage if no profile specified
# =============================================================================
show_usage() {
  echo ""
  echo "Usage: ./install.sh <profile>"
  echo ""
  echo "Profiles:"
  echo "  workstation   - Full development environment (IDEs, databases, etc.)"
  echo "  media-server  - Basic shell setup for remote access"
  echo "  minimal       - Just shell and essential CLI tools"
  echo "  links-only    - Only create directories and symlinks, no package installs"
  echo ""
  echo "Example: ./install.sh workstation"
  echo ""
}

if [[ $# -eq 0 ]]; then
  show_usage
  exit 0
fi

PROFILE="$1"

# =============================================================================
# Colors and Logging
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Helper Functions
# =============================================================================
command_exists() {
  command -v "$1" &>/dev/null
}

symlink() {
  local src="$1"
  local dest="$2"
  local dest_dir

  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      log_info "Symlink already exists: $dest"
    else
      log_warning "Symlink at $dest points elsewhere, replacing it"
      rm "$dest"
      ln -s "$src" "$dest"
      log_success "Symlinked $src -> $dest"
    fi
  elif [[ -e "$dest" ]]; then
    log_warning "File exists at $dest, backing up to ${dest}.backup"
    mv "$dest" "${dest}.backup"
    ln -s "$src" "$dest"
    log_success "Symlinked $src -> $dest"
  else
    ln -s "$src" "$dest"
    log_success "Symlinked $src -> $dest"
  fi
}

# =============================================================================
# Installation Functions
# =============================================================================

install_homebrew() {
  if command_exists brew; then
    log_success "Homebrew already installed"
  else
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
      if [[ ! -f "$HOME/.zprofile" ]] || ! grep -Fq 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
      fi
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
  fi
}

prepare_brewfile() {
  local brewfile="$1"

  if mas account &>/dev/null; then
    printf '%s\n' "$brewfile"
    return 0
  fi

  log_warning "Skipping Mac App Store apps from $(basename "$brewfile") until you sign in to the App Store" >&2

  local filtered
  filtered="$(mktemp)"
  grep -v '^mas "' "$brewfile" >"$filtered"
  printf '%s\n' "$filtered"
}

install_brew_bundle_file() {
  local brewfile="$1"
  local prepared

  prepared="$(prepare_brewfile "$brewfile")"
  brew bundle --file "$prepared"

  if [[ "$prepared" != "$brewfile" ]]; then
    rm -f "$prepared"
  fi
}

install_brew_packages() {
  log_info "Updating Homebrew..."
  brew update

  log_info "Installing shared packages..."
  install_brew_bundle_file "$BREWFILE_BASE"

  # Install profile-specific packages
  if [[ "$PROFILE" == "workstation" ]] && [[ -f "$DOTFILES_DIR/Brewfile.workstation" ]]; then
    log_info "Installing workstation-specific packages..."
    install_brew_bundle_file "$DOTFILES_DIR/Brewfile.workstation"
  elif [[ "$PROFILE" == "media-server" ]] && [[ -f "$DOTFILES_DIR/Brewfile.media-server" ]]; then
    log_info "Installing media-server-specific packages..."
    install_brew_bundle_file "$DOTFILES_DIR/Brewfile.media-server"
  fi

  log_success "Brew packages installed"
}

install_nvm() {
  if [[ -d "$HOME/.nvm" ]]; then
    log_success "NVM already installed"
  else
    log_info "Installing NVM..."
    # Get latest NVM version from GitHub
    local nvm_version
    nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    log_success "NVM $nvm_version installed"
  fi
}

install_tpm() {
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_success "TPM already installed"
  else
    log_info "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    log_success "TPM installed"
  fi
}

install_antidote() {
  if [[ -d "$HOME/.antidote" ]]; then
    log_success "Antidote already installed"
  else
    log_info "Installing Antidote (Zsh plugin manager)..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
    log_success "Antidote installed"
  fi
}

setup_directories() {
  log_info "Setting up directories..."

  mkdir -p "$HOME/Developer"
  mkdir -p "$HOME/.claude"
  mkdir -p "$HOME/.config/ghostty"
  mkdir -p "$HOME/.config/ohmyposh"
  mkdir -p "$HOME/.config/opencode"
  mkdir -p "$HOME/.config/zed"

  log_success "Directories created"
}

setup_symlinks() {
  log_info "Setting up symlinks..."

  # Shell configuration
  symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

  # Git configuration
  symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

  # Tmux configuration
  symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

  # NPM configuration
  symlink "$DOTFILES_DIR/.npmrc" "$HOME/.npmrc"

  # Ghostty terminal
  symlink "$DOTFILES_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"

  # Oh My Posh prompt
  symlink "$DOTFILES_DIR/config/ohmyposh/config.toml" "$HOME/.config/ohmyposh/config.toml"

  # Neovim configuration
  symlink "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"

  # Opencode configuration
  symlink "$DOTFILES_DIR/config/opencode/oh-my-opencode.json" "$HOME/.config/opencode/oh-my-opencode.json"
  symlink "$DOTFILES_DIR/config/opencode/oh-my-opencode-slim.json" "$HOME/.config/opencode/oh-my-opencode-slim.json"
  symlink "$DOTFILES_DIR/config/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
  symlink "$DOTFILES_DIR/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  symlink "$DOTFILES_DIR/config/opencode/tui.json" "$HOME/.config/opencode/tui.json"
  symlink "$DOTFILES_DIR/config/opencode/command" "$HOME/.config/opencode/command"
  symlink "$DOTFILES_DIR/config/opencode/commands" "$HOME/.config/opencode/commands"
  symlink "$DOTFILES_DIR/config/opencode/plugins" "$HOME/.config/opencode/plugins"
  symlink "$DOTFILES_DIR/config/opencode/profiles" "$HOME/.config/opencode/profiles"
  symlink "$DOTFILES_DIR/config/opencode/skills" "$HOME/.config/opencode/skills"
  symlink "$DOTFILES_DIR/config/opencode/themes" "$HOME/.config/opencode/themes"

  # Claude configuration (curated; local/session/auth files stay out of repo)
  symlink "$DOTFILES_DIR/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  symlink "$DOTFILES_DIR/config/claude/RTK.md" "$HOME/.claude/RTK.md"
  symlink "$DOTFILES_DIR/config/claude/settings.json" "$HOME/.claude/settings.json"
  symlink "$DOTFILES_DIR/config/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  symlink "$DOTFILES_DIR/config/claude/commands" "$HOME/.claude/commands"
  symlink "$DOTFILES_DIR/config/claude/hooks" "$HOME/.claude/hooks"
  symlink "$DOTFILES_DIR/config/claude/hud" "$HOME/.claude/hud"

  # Zed editor configuration
  symlink "$DOTFILES_DIR/config/zed/settings.json" "$HOME/.config/zed/settings.json"
  symlink "$DOTFILES_DIR/config/zed/keymap.json" "$HOME/.config/zed/keymap.json"
  symlink "$DOTFILES_DIR/config/zed/tasks.json" "$HOME/.config/zed/tasks.json"
  symlink "$DOTFILES_DIR/config/zed/themes" "$HOME/.config/zed/themes"

  log_success "Symlinks created"
}

# =============================================================================
# Main Installation
# =============================================================================

main() {
  echo ""
  echo "=============================================="
  echo "  Dotfiles Installation - Profile: $PROFILE"
  echo "=============================================="
  echo ""

  # Validate profile
  case "$PROFILE" in
  workstation | media-server | minimal | links-only)
    log_info "Using profile: $PROFILE"
    ;;
  *)
    log_error "Unknown profile: $PROFILE"
    log_info "Valid profiles: workstation, media-server, minimal, links-only"
    exit 1
    ;;
  esac

  # Check if dotfiles directory exists
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found at $DOTFILES_DIR"
    log_info "Please clone the repository first:"
    log_info "  git clone git@github.com:rodvilla/dotfiles.git $DOTFILES_DIR"
    exit 1
  fi

  # Core installation (all profiles)
  log_info "Starting core installation..."
  if [[ "$PROFILE" == "links-only" ]]; then
    setup_directories
    setup_symlinks
    log_success "Links-only setup complete"
    exit 0
  fi

  install_homebrew
  setup_directories
  setup_symlinks
  install_antidote
  install_tpm

  # Profile-specific installation
  install_brew_packages

  if [[ "$PROFILE" == "workstation" ]]; then
    install_nvm
  else
    log_info "$PROFILE profile - skipping NVM"
  fi

  echo ""
  echo "=============================================="
  echo "  Installation Complete!"
  echo "=============================================="
  echo ""
  log_info "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Install tmux plugins: Press prefix + I (Ctrl-a + I) in tmux"
  if [[ "$PROFILE" == "workstation" ]]; then
    echo "  3. Set up Node.js: nvm install --lts"
    echo "  4. Restore secrets: ./bin/secrets.sh"
  fi
  echo "  5. If App Store apps were skipped, sign in and rerun: ./bin/install.sh $PROFILE"
  echo ""
}

main "$@"
