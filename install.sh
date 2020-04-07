#!/bin/bash

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Make sure we are in the repo folder, so we can load the Brewfile
cd $DOTFILES_DIR

# Install all apps
brew bundle

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install zgen
git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"

# Install Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');"
    && chmod +X composer.phar \
    && mv composer.phar /usr/local/bin/composer

# Install Prestissimo & Deployer
composer global require hirak/prestissimo \
    && composer global require deployer/deployer

# Copy all of our configuration files
ln -s "${DOTFILES_DIR}/gitconfig" ~/.gitconfig
ln -s "${DOTFILES_DIR}/iterm" ~/.iterm
ln -s "${DOTFILES_DIR}/notable.json" ~/.notable.json
ln -s "${DOTFILES_DIR}/tmux.conf" ~/.tmux.conf
ln -s "${DOTFILES_DIR}/zshrc" ~/.zshrc
