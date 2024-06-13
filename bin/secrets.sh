#!/bin/bash

# Backup all of my secrets to Google Drive
SECRETS_FOLDER="/Users/rodrigo/Library/CloudStorage/GoogleDrive-rodrigovilla3@gmail.com/My Drive/Backups/Secrets"

# Main secrets
ln -s "$SECRETS_FOLDER/secrets" $HOME/.secrets

# Make .ssh directory if it does not exist
if [ ! -d "$HOME/.ssh" ]; then
    mkdir $HOME/.ssh
    cp -r "$SECRETS_FOLDER/ssh/*" $HOME/.ssh
    chown -R rodrigo:rodrigo $HOME/.ssh
    chmod 700 $HOME/.ssh
fi

cp $SECRETS_FOLDER/ssh/config $HOME/.ssh/config
