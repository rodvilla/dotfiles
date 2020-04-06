#!/bin/bash

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Backup configurations file
cp ~/.gitconfig $DOTFILES_DIR/gitconfig
cp ~/.notable.json $DOTFILES_DIR/notable.json
cp ~/.tmux.json $DOTFILES_DIR/tmux.json
cp ~/.zshrc $DOTFILES_DIR/zshrc
cp -r ~/.iterm $DOTFILES_DIR/iterm