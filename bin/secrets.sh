#!/bin/bash

set -euo pipefail

SECRETS_FOLDER="${SECRETS_FOLDER:-$HOME/Library/CloudStorage/GoogleDrive-rodrigovilla3@gmail.com/My Drive/Backups/Secrets}"
SECRETS_FILE_SOURCE="$SECRETS_FOLDER/secrets"
SSH_SOURCE_DIR="$SECRETS_FOLDER/ssh"
SECRETS_LINK_DEST="$HOME/.secrets"
SSH_DEST_DIR="$HOME/.ssh"

log() {
  printf '[secrets] %s\n' "$1"
}

if [[ ! -d "$SECRETS_FOLDER" ]]; then
  log "Secrets folder not found: $SECRETS_FOLDER"
  log "Set SECRETS_FOLDER to your backup location after Google Drive finishes syncing."
  exit 1
fi

if [[ -e "$SECRETS_FILE_SOURCE" ]]; then
  if [[ -L "$SECRETS_LINK_DEST" ]] && [[ "$(readlink "$SECRETS_LINK_DEST")" == "$SECRETS_FILE_SOURCE" ]]; then
    log "Secrets symlink already configured"
  else
    if [[ -e "$SECRETS_LINK_DEST" ]] || [[ -L "$SECRETS_LINK_DEST" ]]; then
      mv "$SECRETS_LINK_DEST" "${SECRETS_LINK_DEST}.backup"
      log "Backed up existing ~/.secrets to ~/.secrets.backup"
    fi
    ln -s "$SECRETS_FILE_SOURCE" "$SECRETS_LINK_DEST"
    log "Linked ~/.secrets"
  fi
else
  log "Secrets file not found at $SECRETS_FILE_SOURCE"
fi

if [[ -d "$SSH_SOURCE_DIR" ]]; then
  mkdir -p "$SSH_DEST_DIR"
  cp -R "$SSH_SOURCE_DIR/." "$SSH_DEST_DIR/"
  chmod -R go-rwx "$SSH_DEST_DIR"
  chmod 700 "$SSH_DEST_DIR"
  log "Restored SSH files into ~/.ssh"
else
  log "SSH backup folder not found at $SSH_SOURCE_DIR"
fi
