# -------------------------------------------------------------------------------------------------
# Change directory and list contents immediately (unless there are more than 50 files/folders)
# -------------------------------------------------------------------------------------------------
# Usage:   c some_folder
# Example: c /some/folder
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
# -------------------------------------------------------------------------------------------------
# Move any number of folders up in the hierarchy
# -------------------------------------------------------------------------------------------------
# Usage:   up [ number (default: 1) ]
# Example: up 4
function up() {
    local arg="${1:-1}"
    local dir=""
    while [ $arg -gt 0 ]; do
        dir="../$dir"
        arg="$(($arg - 1))";
    done
    c $dir #>&/dev/null
}
# -------------------------------------------------------------------------------------------------
# Echo a string in a primary colour
# -------------------------------------------------------------------------------------------------
# Usage:   colEcho string [ "red" | "green" | "blue" | "yellow" (default: "red") ]
# Example: colEcho "this is some text" "blue"
function colEcho() {
  [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

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
# -------------------------------------------------------------------------------------------------
# Case-insensitive search with 1 line of context
# -------------------------------------------------------------------------------------------------
# Usage:   s pattern [ folder (default: .) ]
# Example: s sometext (= s sometext .)
# Example: s sometext /some/folder
function s() {
  [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

  grep -n1ir "$1" "${2:-.}"
}
# -------------------------------------------------------------------------------------------------
# Case-sensitive search with 1 line of context
# -------------------------------------------------------------------------------------------------
# Usage:   S pattern [ folder (default: .) ]
# Example: S SomeText (= S sometext .)
# Example: S SomeText /some/folder
function S() {
  [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

  grep -n1r "$1" "${2:-.}"
}
# -------------------------------------------------------------------------------------------------
# Alternative to locate (from pwd)
# -------------------------------------------------------------------------------------------------
# Usage:   sfile file
# Example: sfile 'file.csv'
function sfile { 
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  find . -name '.snapshot' -prune ! -readable -prune -o -iname "$1" 2>/dev/null
}
# -------------------------------------------------------------------------------------------------
# Search process
# -------------------------------------------------------------------------------------------------
# Usage:   sps pattern
# Example: sps postgres
function sps {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  pgrep "$@" | xargs ps -o uid,pid,ppid,stime,time,%cpu,%mem,sz,uname,ruser,comm,args
}
# -------------------------------------------------------------------------------------------------
# Search full process listing
# -------------------------------------------------------------------------------------------------
# Usage:   sfps pattern
# Example: sfps postgres
function sfps {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  ps -ef | grep "$1" | grep -v 'grep'
}
# -------------------------------------------------------------------------------------------------
# Search man page for context
# -------------------------------------------------------------------------------------------------
# Usage:   sman manPage pattern
# Example: sman cp recursive
function sman {
  [ $# -ne 2 ] && echo "$FUNCNAME: two arguments are required" && return 1  

  man "$1" | grep -n5i "$2"
}
# -------------------------------------------------------------------------------------------------
# List top N files and directories, ordered by size
# -------------------------------------------------------------------------------------------------
# Usage:   dl /some/folder N (default: 10)
# Example: dl /var 20
function dl {
  [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

  du -a "$1" | sort -rh | head -n "${2:-10}"
}
# -------------------------------------------------------------------------------------------------
# Search PDF files recursively (from pwd)
# -------------------------------------------------------------------------------------------------
# Usage:   spdf pattern
# Example: spdf "some text"
function spdf {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  find ./ ! -readable -prune -o -iname '*.pdf' -exec pdfgrep -H "$1" {} + 2>/dev/null
}
# -------------------------------------------------------------------------------------------------
# Interactive Git rebase
# -------------------------------------------------------------------------------------------------
# Usage:   gr [ number (default: 2) ]
# Example: gr (= gr 2)
# Example: gr 3
function gr() {  
  git rebase -i HEAD~${1:-2}
}
# -------------------------------------------------------------------------------------------------
# Synchronize a branch from the upstream repository
# -------------------------------------------------------------------------------------------------
function __git_sync() {
  git checkout "$1" && git pull
}
# -------------------------------------------------------------------------------------------------
# Branch off another branch that has been synchronized from the upstream repository
# -------------------------------------------------------------------------------------------------
function __git_sync_branch {
  __git_sync "$1" && git checkout -b "$2"
}
# -------------------------------------------------------------------------------------------------
# Synchronize from the upstream repository, merge a branch, and push
# -------------------------------------------------------------------------------------------------
function __git_sync_merge {
  __git_sync "$1" && git merge "$2" && git push
}
# -------------------------------------------------------------------------------------------------
# Synchronize from the upstream repository, merge a branch, push, and prune topic branch
# -------------------------------------------------------------------------------------------------
function __git_sync_merge_prune {
  __git_sync_merge "$1" "$2" && git branch -d "$2"
}
# -------------------------------------------------------------------------------------------------
# Create a new feature branch
# -------------------------------------------------------------------------------------------------
# Usage:   gbf featureDesc [ devBranch (default: $GIT_DEVELOP_BRANCH) ]
# Example: gbf ISSUE-123 (= gcf ISSUE-123 $GIT_DEVELOP_BRANCH)
# Example: gbf ISSUE-999 dev
function gbf() {
  __git_sync_branch "${2:-$GIT_DEVELOP_BRANCH}" "${GIT_FEATURE_PREFIX}$1"
}
# -------------------------------------------------------------------------------------------------
# Create a new hotfix branch
# -------------------------------------------------------------------------------------------------
# Usage:   gbh hotfixDesc [ masterBranch (default: $GIT_MASTER_BRANCH) ]
# Example: gbh ISSUE-123 (= gcf ISSUE-123 $GIT_MASTER_BRANCH)
# Example: gbh ISSUE-999 main
function gbh() {
  __git_sync_branch "${2:-$GIT_MASTER_BRANCH}" "${GIT_HOTFIX_PREFIX}$1"
}
# -------------------------------------------------------------------------------------------------
# Create a new release branch
# -------------------------------------------------------------------------------------------------
# Usage:   gbr releaseDesc [ devBranch (default: $GIT_DEVELOP_BRANCH) ]
# Example: gbr 1.0.5 (= gcf 1.0.5 $GIT_DEVELOP_BRANCH)
# Example: gbr 2.6 dev
function gbr() { 
  __git_sync_branch "${2:-$GIT_DEVELOP_BRANCH}" "${GIT_RELEASE_PREFIX}$1"
}
# -------------------------------------------------------------------------------------------------
# Merge the current topic branch into development (and master for hotfixes and releases)
# -------------------------------------------------------------------------------------------------
# Usage:   gm [ branch (default: current) 
#               [ masterBranch (default: $GIT_MASTER_BRANCH) 
#                 [ devBranch (default: $GIT_DEVELOP_BRANCH) ] ] ]
# Example: gm (= gm current $GIT_MASTER_BRANCH $GIT_DEVELOP_BRANCH)
# Example: gm ISSUE-123 (= gm ISSUE-123 $GIT_MASTER_BRANCH $GIT_DEVELOP_BRANCH)
# Example: gm ISSUE-999 main dev
# Note:    The function will ask for a tag when merging a release branch
function gm() {
  local current="$(git rev-parse --abbrev-ref HEAD)"
  local branch="${1:-$current}"
  local master="${2:-$GIT_MASTER_BRANCH}"
  local devel="${3:-$GIT_DEVELOP_BRANCH}"


  case "$branch" in 
    "$GIT_FEATURE_PREFIX"?*) 
      colEcho "$FUNCNAME: Merging $branch into $devel..."
      __git_sync_merge_prune "$devel" "$branch"
      ;;
    "$GIT_HOTFIX_PREFIX"?*) 
      colEcho "$FUNCNAME: Merging $branch into $master..."
      __git_sync_merge_prune "$master" "$branch"
      colEcho "$FUNCNAME: Merging $master back into $devel..."
      __git_sync_merge "$devel" "$master"
      ;;
    "$GIT_RELEASE_PREFIX"?*) 
      colEcho "$FUNCNAME: Merging $branch into $master..."
      __git_sync_merge "$master" "$branch"
      colEcho "$FUNCNAME: Please provide a version label: " "blue"
      read version
      git tag -a "$version" && git push origin --tags
      colEcho "$FUNCNAME: Merging $master back into $devel..."
      __git_sync_merge "$devel" "$master"
       ;;
    *) 
       echo "$FUNCNAME: $branch is not a topic branch" && return 1
       ;;
  esac
}
# -------------------------------------------------------------------------------------------------
# Recursively replace spaces with underscores in file and folder names
# -------------------------------------------------------------------------------------------------
# Usage:   rmspaces [ folder (default: .) ]
# Example: rmspaces (= rmspaces .)
# Example: rmspaces /some/folder
function rmspaces() {
  local dir="$1"

  if [ "$dir" = "/" ] ; then
    echo "$FUNCNAME: cannot replace spaces from / onwards" && return 1
  else
    find "${dir:-.}" -depth -name '* *' -execdir bash -c \
    'for i; do mv "$i" "${i// /_}"; done' _ "{}" +
  fi
}
# -------------------------------------------------------------------------------------------------
# Recursively strip headers (i.e. skip) from files from pwd
# -------------------------------------------------------------------------------------------------
# Usage:   rmheaders [ linesToSkip (default: 1) }]
# Example: rmheaders (= rmheaders 1)
function rmheaders() {
  local dir="$(pwd)"
  local start_at=$((1+${1:-1}))

  if [ "$dir" = "/" ] ; then
    echo "$FUNCNAME: cannot remove headers from / onwards" && return 1
  else
    find "${dir:-.}" -depth -type f ! -name '.*' -execdir bash -c \
    'for i; do t=tmp.$$$(date +%s%N); tail -n+$0 "$i" > $t; mv -f $t "$i"; done' $start_at "{}" +
  fi
}
# -------------------------------------------------------------------------------------------------
# Recursively strip headers (i.e. skip) from files with a certain pattern from pwd
# -------------------------------------------------------------------------------------------------
# Usage:   rmpheaders pattern [ linesToSkip (default: 1) }]
# Example: rmpheaders '*.csv' (= rmpatheaders '*.csv' 1)
function rmpheaders() {
  [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

  local dir="$(pwd)"
  local pat="$1"
  local start_at=$((1+${2:-1}))

  if [ "$dir" = "/" ] ; then
    echo "$FUNCNAME: cannot remove headers from / onwards" && return 2
  else
    find "${dir:-.}" -depth -type f -name "$pat" -execdir bash -c \
    'for i; do t=tmp.$$$(date +%s%N); tail -n+$0 "$i" > $t; mv -f $t "$i"; done' $start_at "{}" +
  fi
}
# -------------------------------------------------------------------------------------------------
# Copy or move files with a certain extension and directory/file pattern (from pwd)
# -------------------------------------------------------------------------------------------------
# Usage:   transferFiles extension pattern { mv | cp } [ folder (default: $HOME) ]
# Example: transferFiles txt left cp (= transferFiles txt left cp $HOME/)
# Example: transferFiles txt left mv $HOME/some_folder/
function transferFiles() {
  [ $# -le 3 ] && echo "$FUNCNAME: at least three arguments are required" && return 1

  local ext='*.'"$1"
  local pat="$2"

  # if the path pattern ought to include anything, you might as well use a simple cp/mv  
  if [ "$pat" != "*" ]; then
    pat='*'"$pat"'*'
  fi

  local oper="$3"
  local dest="${4:-$HOME}"

  if [[ "$oper" != "mv" && "$oper" != "cp" ]]; then
    echo "$FUNCNAME: only cp and mv are supported" && return 1
  fi
  
  find . -type f -name "$ext" -path "$pat" | xargs -I '{}' "$oper" '{}' "$dest"
}
# -------------------------------------------------------------------------------------------------
# Copy a large number of files (when cp alone does not work)
# -------------------------------------------------------------------------------------------------
# Usage:   bulkCopy [ sourceFolder (default: .) [ destFolder (default: $HOME) ] ]
# Example: bulkCopy /source/folder /dest/folder
# Example: bulkCopy (= bulkCopy . $HOME)
function bulkCopy() {
  local sourceFolder="${1:-.}"

  # Disable globbing of * in variable creation
  set -f

  if [ "$sourceFolder" != "/" ]; then
    sourceFolder="${sourceFolder%/}/*"
  else
    echo "$FUNCNAME: cannot copy everything from /" && return 1
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
# -------------------------------------------------------------------------------------------------
# Swap two file names around
# -------------------------------------------------------------------------------------------------
# Usage:   swap firstFile secondFile
# Example: swap file1.txt file2.csv
function swap() {
    local temp_file=tmp.$$$(date +%s%N) # alternative: append PID with $$

    [ $# -ne 2 ] && echo "$FUNCNAME: two arguments are required" && return 1
    [ ! -e "$FUNCNAME: $1 does not exist" && return 2
    [ ! -e "$FUNCNAME: $2 does not exist" && return 3

    mv "$1" $temp_file
    mv "$2" "$1"
    mv $temp_file "$2"
}
# -------------------------------------------------------------------------------------------------
# Extract a compressed file
# -------------------------------------------------------------------------------------------------
# Usage:   extract fileToExtract
# Example: extract file.zip
function extract () {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

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
          *)          echo "$1 cannot be extracted with $FUNCNAME" ;;
      esac
  else
      echo "$1 is not a valid file"
  fi
}
# -------------------------------------------------------------------------------------------------
# Encode a URL
# -------------------------------------------------------------------------------------------------
# Usage:   encodeURL someURL
# Example: encodeURL www.google.com/some-link
encodeURL() {
  # -lt: spaces 'look like' multiple arguments when arguments are unquoted
  [ $# -lt 1 ] && echo "$FUNCNAME: one argument is required" && return 1

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
# Join array elements by a character (à la Scala's mkString)
# -------------------------------------------------------------------------------------------------
# Usage:   join char array
# Example: join "," "${arr[@]}"
function join() { local d="$1"; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }
# -------------------------------------------------------------------------------------------------
# Check whether a website is up or not
# -------------------------------------------------------------------------------------------------
# Usage:   isup url
# Example: isup www.google.com
function isup() { lynx --dump www.isup.me/"$1" | head -n1 }
# -------------------------------------------------------------------------------------------------
# Force-capitalize bibliography (BibTeX) files
# -------------------------------------------------------------------------------------------------
# Usage:   capbib bibtexFile.bib
# Example: capbib references.bib
function capbib {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  sed '/^@/!s/[A-Z]/{&}/g' "$1" > "${1%.bib}_caps.bib"
}
# -------------------------------------------------------------------------------------------------
# Add a trailing space after each full stop, exclamation/question mark in TeX files (from pwd)
# -------------------------------------------------------------------------------------------------
# Usage: spacetex
function spacetex {
  find ./ -maxdepth 1 -type f -name '*.tex' | xargs sed -i 's/\(\?\|\!\|\.\|\,\)$/\1\ /'
}
