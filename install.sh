#!/bin/bash

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ln -s "${DOTFILES_DIR}/.gitconfig" ~
ln -s "${DOTFILES_DIR}/.notable.json" ~
ln -s "${DOTFILES_DIR}/.tmux.conf" ~
ln -s "${DOTFILES_DIR}/.wakatime.cfg" ~
ln -s "${DOTFILES_DIR}/.zshrc" ~
ln -s "${DOTFILES_DIR}/.iterm" ~