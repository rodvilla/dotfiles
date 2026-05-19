#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // empty')

folder=$(basename "$cwd")

git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    git_info=" ${branch}*"
  else
    git_info=" ${branch}"
  fi
fi

php_info=""
if command -v php > /dev/null 2>&1; then
  php_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
  php_info=" 󰧦 ${php_ver}"
fi

printf "\033[94m%s\033[0m\033[37m%s\033[0m\033[35m%s\033[0m" \
  "$folder" \
  "$git_info" \
  "$php_info"
