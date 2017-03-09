# -------------------------------------------------------------------------------------------------
# Aliases for the 'ls' family
# -------------------------------------------------------------------------------------------------
alias ls='ls -h --color'
alias ll='ls -lv --group-directories-first'

alias lx='ls -lXB'         # sort by extension
alias lk='ls -lSr'         # sort by size (ascending)
alias lt='ls -ltr'         # sort by date (ascending)
alias lc='ls -ltcr'        # sort by modification/change time (ascending)
alias lu='ls -ltur'        # sort by access time (ascending)
alias lp='ll | less'       # pipe through 'less'
alias lr='ll -R'           # recursive ls
alias la='ll -A'           # show hidden files

alias tree='tree -Csuh'    # Alternative to lr
alias treep='tree | less'  # Pipe through 'less'
# -------------------------------------------------------------------------------------------------
# Generic aliases
# -------------------------------------------------------------------------------------------------
alias vi='vim'                       # always use vim
alias ncat='cat -sn'                 # cat with line numbers
alias more='less'                    # always use less
alias grep='grep --color=always'     # grep with colours

alias du='du -kh'                    # make output readable
alias df='df -kTh'                   # make output readable

alias path='echo -e ${PATH//:/\\n}'  # print PATH in readable form

alias netstat='netstat -ano'         # all sockets with numeric addresses
alias vmstat='vmstat -w'             # wide-format vmstat
# -------------------------------------------------------------------------------------------------
# Aliases for Git: could also go in .gitconfig [alias] section
# -------------------------------------------------------------------------------------------------
alias gs='git status'
alias gl='git log'
alias ga='git add -A'
alias gc='git commit -e'
alias gco='git checkout'
alias gb='gco -b'
alias gg='gl --grep='
alias gls='gl --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate'
alias glg='gl --pretty=format:"%h %s" --graph'
alias gll='gls --numstat'
alias gd='git diff'
alias gdc='gd --cached'
alias discard='git reset --hard'
# -------------------------------------------------------------------------------------------------
# Aliases for clipboard (requires: xclip)
# -------------------------------------------------------------------------------------------------
alias cc='xclip -sel clip'    # cat file.txt | cc ('Ctrl+C')
alias cv='xclip -o -sel clip' # cv > file.txt ('Ctrl+V')
# -------------------------------------------------------------------------------------------------
# Variables for Git
# -------------------------------------------------------------------------------------------------
GIT_MASTER_BRANCH="master"
GIT_DEVELOP_BRANCH="develop"
GIT_FEATURE_PREFIX="feature/"
GIT_HOTFIX_PREFIX="hotfix/"
GIT_RELEASE_PREFIX="release/"