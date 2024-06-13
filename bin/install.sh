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

# Update Homebrew recipes
brew update

# Install dependencies from Brewfile
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Create a projects directories
mkdir $HOME/Code
mkdir $HOME/Herd

# Symlink the Mackup config file to the home directory
ln -s ./.mackup.cfg $HOME/.mackup.cfg

# Symlink other dotfiles
ln -s ./.gitconfig $HOME/.gitconfig
ln -s ./.npmrc $HOME/.npmrc
ln -s ./ohmyposh.toml $HOME/.config/ohmyposh.toml
ln -s ./.tmux.conf $HOME/.tmux.conf
