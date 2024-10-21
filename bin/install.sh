#!/bin/sh

echo "Setting up your Mac..."

# Install Oh My Zsh
if test ! $(which omz); then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Homebrew
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Copy the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -sw $HOME/.dotfiles/.zshrc $HOME/.zshrc

# @TODO: Zgen
# @TODO: TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# @TODO: NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Update Homebrew recipes
brew update

# Install dependencies from Brewfile
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Create a projects directories
mkdir $HOME/Code

# Mackup takes care of a lot of files
# Run mackup restore once Google Drive is setup
ln -s $HOME/.dotfiles/.mackup.cfg $HOME/.mackup.cfg

# Symlink other dotfiles
ln -s $HOME/.dotfiles/.npmrc $HOME/.npmrc
mkdir $HOME/.config
ln -s $HOME/.dotfiles/ohmyposh.toml $HOME/.config/ohmyposh.toml
