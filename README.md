# Rod's Dotfiles

Personal dotfiles for macOS development environment. Configures Zsh, Ghostty terminal, Tmux, Oh My Posh prompt, and manages packages via Homebrew.

## Installation

```bash
# Clone the repository
git clone git@github.com:rodvilla/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run install script with a profile
./bin/install.sh workstation    # Full dev environment
./bin/install.sh media-server   # Basic shell for remote access
./bin/install.sh minimal        # Just essential CLI tools

# Restore secrets (after Google Drive sync)
./bin/secrets.sh
```

## Directory Structure

```
dotfiles/
├── bin/
│   ├── install.sh              # Installation script with profile support
│   └── secrets.sh              # Restore SSH keys from backup
├── config/
│   ├── ghostty/config          # Ghostty terminal configuration
│   └── ohmyposh/config.toml    # Oh My Posh prompt theme
├── shell/
│   ├── aliases.zsh             # Shell aliases
│   └── plugins.txt             # Antidote plugin list
├── .zshrc                      # Zsh configuration
├── .tmux.conf                  # Tmux configuration
├── .gitconfig                  # Git configuration
├── .npmrc                      # NPM registry config
├── Brewfile                    # Base packages (all machines)
├── Brewfile.workstation        # Dev-specific packages
└── Brewfile.media-server       # Media server packages
```

## Key Technologies

| Component | Tool |
|-----------|------|
| Shell | Zsh |
| Plugin Manager | [Antidote](https://getantidote.github.io/) |
| Terminal | [Ghostty](https://ghostty.org/) |
| Prompt | [Oh My Posh](https://ohmyposh.dev/) |
| Multiplexer | Tmux |
| Package Manager | Homebrew |
| Dotfile Manager | [Chezmoi](https://chezmoi.io/) |

## Shell Aliases

```bash
# PHP / Laravel
pa        # php artisan
hc        # herd composer
hp        # herd php
hpa       # herd php artisan

# Docker
doc       # docker
docc      # docker compose
doce      # docker exec -it
docce     # docker compose exec -it
docfresh  # docker compose down && up -d

# Tmux
t         # tmux attach || tmux new -s base

# Modern CLI (auto-aliased if installed)
ls        # eza
cat       # bat
cd        # zoxide
```

## Installation Profiles

| Profile | Use Case |
|---------|----------|
| `workstation` | Full dev environment: IDEs, databases, API tools, VSCode extensions |
| `media-server` | Basic shell setup for remote access via SSH/Tailscale |
| `minimal` | Just essential CLI tools (fzf, bat, eza, ripgrep, etc.) |

## Development Stack

Laravel/PHP (Herd), Node.js (NVM), Ruby (Rbenv), Docker, Kubernetes
