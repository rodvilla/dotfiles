# System variables
export LC_ALL=en_GB.UTF-8  
export LANG=en_GB.UTF-8
export ZSH_WAKATIME_PROJECT_DETECTION=true
export HOMEBREW_GITHUB_API_TOKEN=fbbc72dc88b0d36b2aaea228344f6aba752ee584

# Load zgen
source "${HOME}/.zgen/zgen.zsh"

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
  zgen load wbingli/zsh-wakatime
  zgen load sticklerm3/alehouse
  zgen load gretzky/auto-color-ls
  zgen load jessarcher/zsh-artisan
  zgen load chrissicool/zsh-256color
  zgen load zpm-zsh/colorize
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
alias xslt='docker run --rm -v "`pwd`:/wrk" svilstrup/xsltproc'

# AWS RDS
alias rds-icon="ssh -N -L 3307:vicondb.cptz51gn1569.us-east-1.rds.amazonaws.com:3306 vicon.xmlteam.com"
alias rds-prod="ssh -N -L 3308:vproddb.cptz51gn1569.us-east-1.rds.amazonaws.com:3306 ops01.xmlteam.com"
alias rds-prefeed="ssh -N -L 3309:prefeeddb.caeklsu5i325.us-west-2.rds.amazonaws.com:3306 prefeed.xmlteam.com"
alias rds-tva="ssh -N -L 3310:tva.cptz51gn1569.us-east-1.rds.amazonaws.com:3306 tvahttp1.xmlteam.com"
alias rds-dev="ssh -N -L 3311:vdevdb.cptz51gn1569.us-east-1.rds.amazonaws.com:3306 vdev.xmlteam.com"
alias rds-games="ssh -N -L 3312:vgamesproddb.cptz51gn1569.us-east-1.rds.amazonaws.com:3306 vgamesprod.xmlteam.com"