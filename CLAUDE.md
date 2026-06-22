# CLAUDE.md

Guidance for Claude Code when working with this dotfiles repository.

## Quick Reference

- **Full docs**: See `README.md` for installation, structure, and usage
- **Shell config**: `.zshrc` loads Antidote plugins from `shell/plugins.txt` and aliases from `shell/aliases.zsh`
- **Terminal**: Ghostty config at `config/ghostty/config`
- **Packages**: `Brewfile` (base) + `Brewfile.workstation` or `Brewfile.media-server`

## Standards

- Shell scripts use `set -euo pipefail` for error handling
- Prefer symlinks over copying files
- Keep install script idempotent (safe to run multiple times)
- Secrets are stored in `~/.secrets` (not in repo) and loaded by `.zshrc`

## Key Patterns

- **Adding aliases**: Edit `shell/aliases.zsh`
- **Adding shell hooks**: Edit `shell/hooks.zsh`
- **Adding plugins**: Edit `shell/plugins.txt` (Antidote format)
- **Adding packages**: Edit appropriate `Brewfile*` based on profile
- **Ghostty settings**: Edit `config/ghostty/config`
- **Prompt customization**: Edit `config/ohmyposh/config.toml`

## Notes

- This repo uses Antidote (not Zgen/Oh-My-Zsh directly)
- Ghostty is the terminal (not iTerm2)
- Dotfiles are managed with the symlink-based `bin/install.sh` (not Chezmoi)
- Node versions are managed with `fnm` (not nvm)
