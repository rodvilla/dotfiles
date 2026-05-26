#!/usr/bin/env bash

input=$(cat)

# --- Extract fields ---
cwd=$(echo "$input" | jq -r '.cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')


# --- Folder ---
folder=$(basename "$cwd")

# --- Git info ---
git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    git_info=" ${branch}*"
  else
    git_info=" ${branch}"
  fi
fi

# --- Context % with color: green <50%, yellow 50-80%, red >80% ---
ctx_int=${ctx_pct%.*} # truncate to integer
if [ "$ctx_int" -ge 80 ] 2>/dev/null; then
  ctx_color="31" # red
elif [ "$ctx_int" -ge 50 ] 2>/dev/null; then
  ctx_color="33" # yellow
else
  ctx_color="32" # green
fi



# --- PHP version ---
php_info=""
if command -v php >/dev/null 2>&1; then
  php_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
  php_info="  ${php_ver}"
fi

# --- Assemble: model folder branch* ctx% 󰧦 php ---
printf "\033[2m%s\033[0m \033[94m%s\033[0m\033[37m%s\033[0m \033[${ctx_color}mctx %s%%\033[0m\033[35m%s\033[0m" \
  "$model" \
  "$folder" \
  "$git_info" \
  "$ctx_int" \
  "$php_info"
