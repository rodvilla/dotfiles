# System variables
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export ZSH_WAKATIME_PROJECT_DETECTION=true
export HOMEBREW_GITHUB_API_TOKEN=fbbc72dc88b0d36b2aaea228344f6aba752ee584

# Load zgen
source "${HOME}/.zgen/zgen.zsh"

if [[ -z $TMUX ]]; then
  # Edit the path only once!
  export PATH="/Users/rodrigo/.composer/vendor/bin:/usr/local/opt/node@10/bin:/usr/local/sbin:$PATH"
fi

# If the init scipt doesn't exist
if ! zgen saved; then
  # Oh My Zsh plugins
  zgen oh-my-zsh
  zgen oh-my-zsh plugins/aws
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/osx
  zgen oh-my-zsh plugins/tmux
  zgen oh-my-zsh plugins/extract
  zgen load unixorn/autoupdate-zgen
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load zsh-users/zsh-autosuggestions
  zgen load djui/alias-tips
  zgen load sticklerm3/alehouse
  zgen load jessarcher/zsh-artisan
  zgen load chrissicool/zsh-256color
  zgen load srijanshetty/docker-zsh
  zgen load denysdovhan/spaceship-prompt spaceship

  # generate the init script from plugins above
  zgen save
fi

# Spaceship prompt options
SPACESHIP_TIME_SHOW=true

# Alias
alias c="clear"
alias pa="php artisan"

# Docker
alias doc="docker"
alias docc="docker-compose"
alias doce="docker exec -it"

# AWS RDS
alias rds-icon="ssh -N -L 3307:vicondb.cptz51gn1569.us-east-1.rds.amazonaws.com:3306 vicon.xmlteam.com"
alias rds-xmlt-production="ssh -N -L 3308:xmlt-production.cluster-cptz51gn1569.us-east-1.rds.amazonaws.com:3306 ops01.xmlteam.com"
alias rds-xmlt-development="ssh -N -L 3313:xmlt-development.cluster-cptz51gn1569.us-east-1.rds.amazonaws.com:3306 dev1.xmlteam.com"
alias rds-gamesv5="ssh -N -L 3313:gamesv5.cluster-cptz51gn1569.us-east-1.rds.amazonaws.com:3306 devops02.xmlteam.com"
alias rds-gamesv5-prod="ssh -N -L 3314:gamesv5-prod.cluster-cptz51gn1569.us-east-1.rds.amazonaws.com:3306 web.forecastergames.com"
alias tunnel-amsterdam="ssh -N -L 3308:127.0.0.1:3306 villalobos.im"
