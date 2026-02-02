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
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
DOTFILES_DIR="$HOME/.dotfiles"

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
  command -v "$1" &> /dev/null
}

symlink() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]]; then
    log_info "Symlink already exists: $dest"
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
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
  fi
}

install_brew_packages() {
  log_info "Updating Homebrew..."
  brew update

  log_info "Installing packages from Brewfile..."
  brew bundle --file "$DOTFILES_DIR/Brewfile" --no-lock

  # Install profile-specific packages
  if [[ "$PROFILE" == "workstation" ]] && [[ -f "$DOTFILES_DIR/Brewfile.workstation" ]]; then
    log_info "Installing workstation-specific packages..."
    brew bundle --file "$DOTFILES_DIR/Brewfile.workstation" --no-lock
  elif [[ "$PROFILE" == "media-server" ]] && [[ -f "$DOTFILES_DIR/Brewfile.media-server" ]]; then
    log_info "Installing media-server-specific packages..."
    brew bundle --file "$DOTFILES_DIR/Brewfile.media-server" --no-lock
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

  mkdir -p "$HOME/Code"
  mkdir -p "$HOME/.config/ghostty"
  mkdir -p "$HOME/.config/ohmyposh"

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

  log_success "Symlinks created"
}

install_chezmoi() {
  if command_exists chezmoi; then
    log_success "Chezmoi already installed"
  else
    log_info "Chezmoi will be installed via Homebrew"
  fi
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
    workstation|media-server|minimal)
      log_info "Using profile: $PROFILE"
      ;;
    *)
      log_error "Unknown profile: $PROFILE"
      log_info "Valid profiles: workstation, media-server, minimal"
      exit 1
      ;;
  esac

  # Check if dotfiles directory exists
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "Dotfiles directory not found at $DOTFILES_DIR"
    log_info "Please clone the repository first:"
    log_info "  git clone https://github.com/yourusername/dotfiles.git $DOTFILES_DIR"
    exit 1
  fi

  # Core installation (all profiles)
  log_info "Starting core installation..."
  install_homebrew
  setup_directories
  setup_symlinks
  install_antidote
  install_tpm

  # Profile-specific installation
  if [[ "$PROFILE" != "minimal" ]]; then
    install_nvm
    install_brew_packages
  else
    log_info "Minimal profile - skipping NVM and full Brew packages"
    # Install just essential CLI tools for minimal profile
    brew install git zsh tmux oh-my-posh fzf bat eza fd ripgrep zoxide
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
  echo ""
}

main "$@"
