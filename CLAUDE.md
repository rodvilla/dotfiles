# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository for macOS development environment. Configures shell (Zsh with Antidote), terminal (Ghostty), multiplexer (Tmux), prompt (Oh My Posh), and manages application installations via Homebrew with profile-based setup.

## Setup Commands

```bash
# Full workstation installation (development machine)
git clone https://github.com/rodvilla/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./bin/install.sh workstation

# Media server / minimal setup
./bin/install.sh media-server   # Basic shell setup for remote access
./bin/install.sh minimal        # Just essential CLI tools

# Restore secrets (after Google Drive sync)
./bin/secrets.sh
```

## Directory Structure

```
dotfiles/
├── bin/
│   ├── install.sh          # Main installation script with profile support
│   └── secrets.sh          # Restore SSH keys from backup
├── config/
│   ├── ghostty/config      # Ghostty terminal configuration
│   └── ohmyposh/config.toml # Oh My Posh prompt theme
├── shell/
│   ├── aliases.zsh         # Shell aliases (extracted from .zshrc)
│   └── plugins.txt         # Antidote plugin list
├── .zshrc                  # Zsh config (loads Antidote, aliases)
├── .tmux.conf              # Tmux config with plugins
├── .gitconfig              # Git configuration
├── .npmrc                  # NPM registry config
├── Brewfile                # Base packages (all machines)
├── Brewfile.workstation    # Dev-specific packages
└── Brewfile.media-server   # Media server packages
```

## Key Technologies

| Component | Tool | Config |
|-----------|------|--------|
| Shell | Zsh | `.zshrc` |
| Plugin Manager | Antidote | `shell/plugins.txt` |
| Terminal | Ghostty | `config/ghostty/config` |
| Prompt | Oh My Posh | `config/ohmyposh/config.toml` |
| Multiplexer | Tmux | `.tmux.conf` |
| Package Manager | Homebrew | `Brewfile*` |
| Dotfile Manager | Chezmoi | (installed via Brewfile) |

## Shell Aliases

Located in `shell/aliases.zsh`:

```bash
# PHP / Laravel
pa    # php artisan
hc    # herd composer
hp    # herd php
hpa   # herd php artisan

# Docker
doc   # docker
docc  # docker compose
doce  # docker exec -it
docce # docker compose exec -it
docfresh # docker compose down && up -d

# Tmux
t     # tmux attach || tmux new -s base

# Modern CLI (auto-aliased if installed)
ls    # eza (better ls)
cat   # bat (better cat)
cd    # zoxide (smarter cd)
```

## Development Stack

Primary: Laravel/PHP with Herd, Node.js (NVM), Ruby (Rbenv), Docker, Kubernetes

## Installation Profiles

- **workstation**: Full development environment with IDEs, databases, API tools
- **media-server**: Basic shell setup for remote access via SSH/Tailscale
- **minimal**: Just essential CLI tools (fzf, bat, eza, etc.)

## Migration Notes

- Migrated from iTerm2 to Ghostty terminal
- Migrated from Zgen to Antidote plugin manager
- Migrated from Mackup to Chezmoi for dotfile management
