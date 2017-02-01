# -------------------------------------------------------------------------------------------------
# Custom shell options
# -------------------------------------------------------------------------------------------------
shopt -q -s cdspell        # correct small typos when issuing cd
shopt -q -s extglob        # allow regular expressions in file expansions
shopt -q -s globstar       # treat **-pattern differently than *
shopt -q -s nocaseglob     # ignore case in wildcard file expansions
#--------------------------------------------------------------------------------------------------
# Aliases
# -------------------------------------------------------------------------------------------------
alias dev='cd $HOME/development'
alias doc='cd $HOME/documents'
alias down='cd $HOME/downloads'
alias script='cd $HOME/scripts'
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
# -------------------------------------------------------------------------------------------------
# Aliases for clipboard (requires: xclip)
# -------------------------------------------------------------------------------------------------
alias cc='xclip -sel clip'    # cat file.txt | cc ('Ctrl+C')
alias cv='xclip -o -sel clip' # cv > file.txt ('Ctrl+V')
# -------------------------------------------------------------------------------------------------
# Generic functions
# -------------------------------------------------------------------------------------------------
# Change directory and list contents immediately (unless there are more than 50 files/folders)
## Fancy replacement for built-in cd
### Example: c next_folder
function c() { 
  cd "$@" 
  local numObj=$(ls . | wc -l)
  local objComparison=$(echo "$numObj <= 50" | bc)

  echo "  Current directory:        $(pwd)"
  echo "  Number of files/folders:  $numObj"

  if [ "$objComparison" = "1" ]; then
    ls
  fi
}
# Move any number of folders up in the hierarchy
## Usage: up [ number (default: 1) ]
### Example: up 4
function up() {
    local arg=${1:-1}
    local dir=""
    while [ $arg -gt 0 ]; do
        dir="../$dir"
        arg=$(($arg - 1));
    done
    c $dir #>&/dev/null
}
# Echo a string in a primary colour
## Usage: colEcho string [ "red" | "green" | "blue" | "yellow" (default: "red") ]
### Example colEcho "this is some text" "blue"
function colEcho() {
  [ $# -eq 0 ] && echo "colEcho(): at least one argument is required" && return 1

  local escSeq="\x1b["
  local colReset=$escSeq"39;49;00m"
  local colRed=$escSeq"31;01m"
  local colGreen=$escSeq"32;01m"
  local colYellow=$escSeq"33;01m"
  local colBlue=$escSeq"34;01m"

  local text="$1"
  local colour="${2,,}"   # convert to lower case
  local colPrefix=""
  

  if [ "$colour" = "yellow" ]; then
    colPrefix="$colYellow"    
  elif [ "$colour" = "green" ]; then
    colPrefix="$colGreen"
  elif [ "$colour" = "blue" ]; then
    colPrefix="$colBlue"
  else
    colPrefix="$colRed"
  fi

  echo -e "$colPrefix $text $colReset"
}
# Case-insensitive search with 1 line of context
## Usage: s pattern [ folder (default: .) ]
### Example: s sometext (= s sometext .)
### Example: s sometext /some/folder
function s() {
  [ $# -eq 0 ] && echo "s(): at least one argument is required" && return 1

  grep -n1ir "$1" "${2:-.}"
}
# Case-sensitive search with 1 line of context
## Usage: S pattern [ folder (default: .) ]
### Example: S SomeText (= S sometext .)
### Example: S SomeText /some/folder
function S() {
  [ $# -eq 0 ] && echo "S(): at least one argument is required" && return 1

  grep -n1r "$1" "${2:-.}"
}
# Alternative to locate (from pwd)
## Usage: sfile file
### Example sfile 'file.csv'
function sfile { 
  [ $# -ne 1 ] && echo "sfile(): one argument is required" && return 1

  find . -name '.snapshot' -prune ! -readable -prune -o -iname "$1" 2>/dev/null
}
# Search process
## Usage: sps pattern
### Example sps postgres
function sps {
  [ $# -ne 1 ] && echo "sps(): one argument is required" && return 1

  pgrep "$@" | xargs ps -o uid,pid,ppid,stime,time,%cpu,%mem,sz,uname,ruser,comm,args
}
# Search full process listing
## Usage: sfps pattern
### Example sfps postgres
function sfps {
  [ $# -ne 1 ] && echo "sfps(): one argument is required" && return 1

  ps -ef | grep "$1" | grep -v 'grep'
}
# Search man page for context
## sman manPage pattern
### sman cp recursive
function sman {
  [ $# -ne 2 ] && echo "sman(): two arguments are required" && return 1  

  man "$1" | grep -n5i "$2"
}
# List top N files and directories, ordered by size
## Usage: dl /some/folder N (default: 10)
### Example: dl /var 20
function dl {
  [ $# -eq 0 ] && echo "dl(): at least one argument is required" && return 1

  du -a "$1" | sort -rh | head -n "${2:-10}"
}
# Search PDF files recursively (from pwd)
## Usage: spdf pattern
### Example: spdf "some text"
function spdf {
  [ $# -ne 1 ] && echo "spdf(): one argument is required" && return 1

  find ./ ! -readable -prune -o -iname '*.pdf' -exec pdfgrep -H "$1" {} + 2>/dev/null
}
# Interactive Git rebase
## Usage: gr [ number (default: 2) ]
### Example: gr (= gr 2)
### Example: gr 3
function gr() {  
  git rebase -i HEAD~${1:-2}
}
# Recursively replace spaces with underscores in file and folder names
## Usage: rmspaces [ folder (default: .) ]
### Example: rmspaces (= rmspaces .)
### Example: rmspaces /some/folder
function rmspaces() {
  local dir="$1"

  if [ "$dir" = "/" ] ; then
    echo "rmspaces(): cannot replace spaces from / onwards" && return 1
  else
    find "${dir:-.}" -depth -name '* *' -execdir bash -c \
    'for i; do mv "$i" "${i// /_}"; done' _ "{}" +
  fi
}
# Recursively strip headers (i.e. skip) from files from pwd
## Usage: rmheaders [ linesToSkip (default: 1) }]
### Example: rmheaders (= rmheaders 1)
function rmheaders() {
  local dir=`pwd`
  local start_at=$((1+${1:-1}))

  if [ "$dir" = "/" ] ; then
    echo "rmheaders(): cannot remove headers from / onwards" && return 1
  else
    find "${dir:-.}" -depth -type f ! -name '.*' -execdir bash -c \
    'for i; do t=tmp.$$$(date +%s%N); tail -n+$0 "$i" > $t; mv -f $t "$i"; done' $start_at "{}" +
  fi
}
# Recursively strip headers (i.e. skip) from files with a certain pattern from pwd
## Usage: rmpheaders pattern [ linesToSkip (default: 1) }]
### Example: rmpheaders '*.csv' (= rmpatheaders '*.csv' 1)
function rmpheaders() {
  [ $# -eq 0 ] && echo "rmpheaders(): at least one argument is required" && return 1

  local dir=`pwd`
  local pat="$1"
  local start_at=$((1+${2:-1}))

  if [ "$dir" = "/" ] ; then
    echo "rmpatheaders(): cannot remove headers from / onwards" && return 1
  else
    find "${dir:-.}" -depth -type f -name "$pat" -execdir bash -c \
    'for i; do t=tmp.$$$(date +%s%N); tail -n+$0 "$i" > $t; mv -f $t "$i"; done' $start_at "{}" +
  fi
}
# Copy or move files with a certain extension and directory/file pattern (from pwd)
## Usage: transferFiles extension pattern { mv | cp } [ folder (default: $HOME) ]
### Example: transferFiles txt left cp (= transferFiles txt left cp $HOME/)
### Example: transferFiles txt left mv $HOME/some_folder/
function transferFiles() {
  [ $# -le 3 ] && echo "transferFiles(): at least three arguments are required" && return 1

  local ext='*.'"$1"
  local pat="$2"

  # if the path pattern ought to include anything, you might as well use a simple cp/mv  
  if [ "$pat" != "*" ]; then
    pat='*'"$pat"'*'
  fi

  local oper="$3"
  local dest="${4:-$HOME}"

  if [[ "$oper" != "mv" && "$oper" != "cp" ]]; then
    echo "transferFiles(): only cp and mv are supported" && return 1
  fi
  
  find . -type f -name "$ext" -path "$pat" | xargs -I '{}' "$oper" '{}' "$dest"
}
# Copy a large number of files (when cp alone does not work)
## Usage: bulkCopy [ sourceFolder (default: .) [ destFolder (default: $HOME) ] ]
### Example: bulkCopy /source/folder /dest/folder
### Example: bulkCopy (= bulkCopy . $HOME)
function bulkCopy() {
  
  local sourceFolder="${1:-.}"

  # Disable globbing of * in variable creation
  set -f

  if [ "$sourceFolder" != "/" ]; then
    sourceFolder="${sourceFolder%/}/*"
  else
    echo "bulkCopy(): cannot copy everything from /" && return 1
  fi

  set +f

  local destFolder="${2:-$HOME}"

  # add final / unless the destination is the root directory
  if [ "$destFolder" != "/" ]; then
    destFolder="${destFolder%/}/"
  fi

  for file in $sourceFolder; do
    [[ -d "$file" ]] && cp -r "$file" "$destFolder" && continue
    cp "$file" "$destFolder"
  done
}
# Swap two file names around
## Usage swap firstFile secondFile
### Example: swap file1.txt file2.csv
function swap() {
    local temp_file=tmp.$$$(date +%s%N) # alternative: append PID with $$

    [ $# -ne 2 ] && echo "swap(): two arguments are required" && return 1
    [ ! -e "$1" ] && echo "swap(): $1 does not exist" && return 1
    [ ! -e "$2" ] && echo "swap(): $2 does not exist" && return 1

    mv "$1" $temp_file
    mv "$2" "$1"
    mv $temp_file "$2"
}
# Extract a compressed file
## Usage: extract fileToExtract
### Example: extract file.zip
function extract () {
  [ $# -ne 1 ] && echo "extract(): one argument is required" && return 1

  if [ -f "$1" ] ; then
      case "$1" in
          *.tar.bz2)  tar xjf "$1"      ;;
          *.tar.gz)   tar xzf "$1"      ;;
          *.bz2)      bunzip2 "$1"      ;;
          *.rar)      rar x "$1"        ;;
          *.gz)       gunzip "$1"       ;;
          *.tar)      tar xf "$1"       ;;
          *.tbz2)     tar xjf "$1"      ;;
          *.tgz)      tar xzf "$1"      ;;
          *.zip)      unzip "$1"        ;;
          *.Z)        uncompress "$1"   ;;
          *)          echo "'$1' cannot be extracted with extract()" ;;
      esac
  else
      echo "'$1' is not a valid file"
  fi
}
# Encode a URL
## Usage: encodeURL someURL
### Example: encodeURL www.google.com/some-link
encodeURL() {
  # -lt: spaces 'look like' multiple arguments when arguments are unquoted
  [ $# -lt 1 ] && echo "encodeURL(): one argument is required" && return 1

  # str takes care of 'multiple arguments' by assuming they are one big string
  local str="$@"
  local len=${#str}
  for (( i = 0; i < len; i++ )); do
    local char="${str:i:1}"
    case $char in
      [[:alnum:]-:.~_/=?\&\"]) printf "$char" ;;
      *) printf '%s' "$char" | xxd -p -c1 |
        while read char; do printf '%%%s' "$char"; done ;;
    esac
  done
}
# -------------------------------------------------------------------------------------------------
# LaTeX functions
# -------------------------------------------------------------------------------------------------
# Force-capitalize bibliography (BibTeX) files
## Usage: capbib bibtexFile.bib
### Example: capbib references.bib
function capbib {
  [ $# -ne 1 ] && echo "capbib(): one argument is required" && return 1

  sed '/^@/!s/[A-Z]/{&}/g' "$1" > "${1%.bib}_caps.bib"
}
# Add a trailing space after each full stop, exclamation/question mark in TeX files (from pwd)
## Usage: spacetex
function spacetex {
  find ./ -maxdepth 1 -type f -name '*.tex' | xargs sed -i 's/\(\?\|\!\|\.\|\,\)$/\1\ /'
}
