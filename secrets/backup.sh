#!/bin/bash

# Backup all of my secrets to Google Drive
DESTINATION_FOLDER="~/Google\ Drive/Backups"

cp ~/.wakatime.cfg $DESTINATION_FOLDER/wakatime.cfg
cp ~/.config/karabiner/karabiner.json $DESTINATION_FOLDER/karabiner.json
cp -r ~/.aws $DESTINATION_FOLDER/aws
cp -r ~/.ssh $DESTINATION_FOLDER/ssh
