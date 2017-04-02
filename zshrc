export ZSH=/home/ian/.oh-my-zsh

POWERLEVEL9K_MODE="awesome-fontconfig"

ZSH_THEME="powerlevel9k/powerlevel9k"

POWERLEVEL9K_SHORTEN_DIR_LENGTH="4"
POWERLEVEL9K_SHORTEN_DIR_STRATEGY="truncate_middle"
POWERLEVEL9K_BATTERY_ICON="\uf1e6"
POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M \uf073 %d/%m/%Y}"
POWERLEVEL9K_STATUS_VERBOSE="false"
POWERLEVEL9K_PROMPT_ON_NEWLINE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon root_indicator context dir dir_writable ssh vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs battery time)

plugins=(colored-man-pages colorize cp dircycle gitfast gradle jira sbt scala)

source $ZSH/oh-my-zsh.sh

export BROWSER=/usr/bin/chromium
export EDITOR=/usr/bin/nano
export PATH="$PATH:$HOME/scripts:$(ruby -e 'print Gem.user_dir')/bin"

source $HOME/scripts/bash_lib.sh
