#!/bin/bash

# Backup all of my secrets to Google Drive
SECRETS_FOLDER="/Users/rodrigo/Google Drive/Backups/Secrets"

ln -s "$SECRETS_FOLDER/wakatime.cfg" ~/.wakatime.cfg
ln -s "$SECRETS_FOLDER/karabiner.json" ~/.config/karabiner/karabiner.json
ln -s "$SECRETS_FOLDER/aws" ~/.aws
ln -s "$SECRETS_FOLDER/ssh"  ~/.ssh
