export ZSH=/home/ian/.oh-my-zsh

POWERLEVEL9K_MODE="awesome-fontconfig"
ZSH_THEME="powerlevel9k/powerlevel9k"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(colored-man-pages colorize cp dircycle git gradle jira sbt scala)

source $ZSH/oh-my-zsh.sh

export BROWSER=/usr/bin/chromium
export EDITOR=/usr/bin/nano
export PATH="$PATH:$HOME/scripts:$(ruby -e 'print Gem.user_dir')/bin"

source $HOME/scripts/bash_lib.sh
