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

## Features & Quick Reference

### Zsh Shell

**History**
- 50,000 commands saved across sessions
- Duplicates automatically removed
- Shared between all terminal sessions

**Directory Navigation**
- `AUTO_CD` - Type directory name to cd into it (no `cd` needed)
- `AUTO_PUSHD` - Directory stack for quick navigation with `cd -`
- `zoxide` - Smart cd that learns your habits (`z project` jumps to ~/Developer/project)

**Key Plugins**
| Plugin | Description |
|--------|-------------|
| `zsh-autosuggestions` | Fish-like suggestions based on history |
| `zsh-syntax-highlighting` | Command highlighting (green=valid, red=invalid) |
| `alias-tips` | Reminds you of aliases when typing full commands |
| `sudo` | Press `ESC ESC` to prepend sudo to current/last command |
| `extract` | Extract any archive with `extract file.tar.gz` |
| `colored-man-pages` | Colorized man pages |

### Tmux Multiplexer

**Prefix Key:** `Ctrl+A` (instead of default Ctrl+B)

**Session Management**
| Key | Action |
|-----|--------|
| `t` (alias) | Attach to existing session or create new |
| `Ctrl+A d` | Detach from session |
| `Ctrl+A r` | Reload tmux config |

**Window & Pane Management**
| Key | Action |
|-----|--------|
| `Ctrl+A \|` | Split vertical (new pane right) |
| `Ctrl+A -` | Split horizontal (new pane below) |
| `Ctrl+A h/j/k/l` | Navigate panes (Vim-style) |
| `Alt+Arrow` | Navigate panes (no prefix needed) |
| `Ctrl+A H/J/K/L` | Resize panes |

**Copy Mode (Vi-style)**
| Key | Action |
|-----|--------|
| `Ctrl+A [` | Enter copy mode |
| `v` | Start selection |
| `y` or `Enter` | Copy to clipboard (pbcopy) |
| `q` | Exit copy mode |

**Plugins (via TPM)**
- `tmux-resurrect` - Save/restore sessions across restarts
- `tmux-continuum` - Auto-save sessions every 15 minutes
- `tmux-yank` - Enhanced clipboard support
- `tmux-copycat` - Regex search in scrollback

### FZF Fuzzy Finder

**Keyboard Shortcuts**
| Key | Action |
|-----|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Search files in current directory |
| `Alt+C` | cd into subdirectory |

**Configuration**
- Height: 40% of terminal
- Layout: Reverse (results at top)
- Uses `fd` for faster file finding (respects .gitignore)

### Modern CLI Replacements

These are auto-aliased when installed:

| Original | Replacement | Benefits |
|----------|-------------|----------|
| `ls` | `eza` | Icons, git status, colors |
| `cat` | `bat` | Syntax highlighting, line numbers |
| `cd` | `zoxide` | Learns frequently used directories |
| `grep` | `ripgrep` | Faster, respects .gitignore |
| `find` | `fd` | Simpler syntax, faster |

**Eza Aliases**
- `ls` - Basic listing
- `ll` - Long format
- `la` - Include hidden files
- `lt` - Tree view

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
