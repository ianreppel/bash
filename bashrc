[[ $- != *i* ]] && return
PS1='[\u@\h \w (\A)]\$ '
BROWSER=/usr/bin/chromium
EDITOR=/usr/bin/nano
PATH="$PATH:$HOME/scripts:$(ruby -e 'print Gem.user_dir')/bin"
source $HOME/scripts/options.sh
source $HOME/scripts/aliases.sh
source $HOME/scripts/functions.sh