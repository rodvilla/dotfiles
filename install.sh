#!/bin/bash

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install from the backup brew file
cd $DOTFILES_DIR && brew bundle

ln -s "${DOTFILES_DIR}/gitconfig" ~/.gitconfig
ln -s "${DOTFILES_DIR}/notable.json" ~/.notable.json
ln -s "${DOTFILES_DIR}/tmux.conf" ~/.tmux.conf
ln -s "${DOTFILES_DIR}/wakatime.cfg" ~/.wakatime.cfg
ln -s "${DOTFILES_DIR}/zshrc" ~/.zshrc
ln -s "${DOTFILES_DIR}/iterm" ~/.iterm
ln -s "${DOTFILES_DIR}/ssh-config" ~/ssh/config