#!/usr/bin/env bash

input=$(cat)

prefix=$(printf '%s' "$input" | bash "$HOME/.claude/statusline-command.sh")
suffix=$(printf '%s' "$input" | node "$HOME/.claude/hud/omc-hud.mjs")

if [ -n "$prefix" ] && [ -n "$suffix" ]; then
  printf '%s \033[2;37m·\033[0m %s' "$prefix" "$suffix"
else
  printf '%s%s' "$prefix" "$suffix"
fi
