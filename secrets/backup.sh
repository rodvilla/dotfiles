#!/bin/bash

# Backup all of my secrets to Google Drive
DESTINATION_FOLDER="/Users/rodrigo/Google Drive/Backups/Secrets"

# Change dir to destination folder
cd "$DESTINATION_FOLDER"

cp ~/.wakatime.cfg ./wakatime.cfg
cp ~/.config/karabiner/karabiner.json ./karabiner.json
cp -r ~/.aws ./aws
cp -r ~/.ssh ./ssh
