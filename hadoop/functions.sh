#!/bin/bash
# Databaseline code repository
#
# Code for post: Shell Scripts to Each Life with Hadoop
# Base URL:      https://databaseline.tech
# Author:        Ian Hellström
# -----------------------------------------------------------------------------
# Source Hadoop configurations and generic functions
# -----------------------------------------------------------------------------
source aliases.sh
# -----------------------------------------------------------------------------
# Generate a normalized HDFS path
# -----------------------------------------------------------------------------
function __hdfs_folder() {
  local dir="${1:-$HDP_DATA}"

  if [ "$dir" != "/" ]; then
    dir="${dir%/}"
  fi

  local full_dir=""
  if [ "$dir" != "" ] ; then
    if [ "${dir%${dir#?}}" = "/" ] ; then
        full_dir="$dir"
    else
      full_dir="$HDP_DATA/$dir"
    fi
  fi
  echo "$full_dir"
}
# -----------------------------------------------------------------------------
# Retrieve HDFS configurations
# -----------------------------------------------------------------------------
# Usage:   hconf
function hconf() {
  local priNameNodes=$(hdfs getconf -namenodes 2> /dev/null)
  local secNameNodes=$(hdfs getconf -secondaryNameNodes 2> /dev/null)
  local backupNodes=$(hdfs getconf -backupNodes 2> /dev/null)
  local blockSize=$(hdfs getconf -confKey dfs.block.size 2> /dev/null)
  local replication=$(hdfs getconf -confKey dfs.replication 2> /dev/null)
  local replInterval=$(hdfs getconf -confKey dfs.replication.interval 2> /dev/null)
  local maxObjects=$(hdfs getconf -confKey dfs.max.objects 2> /dev/null)

  blockSize=$(echo "$blockSize/1024/1024" | bc)

  if [ "$maxObjects" = "0" ]; then
    maxObjects="unlimited"
  fi

  echo "Primary namenodes:        $priNameNodes"
  echo "Secondary namenodes:      $secNameNodes"
  echo "Backup nodes:             $backupNodes"
  echo "Block size (MB):          $blockSize"
  echo "Replication factor:       $replication"
  echo "Replication interval (s): $replInterval"
  echo "Max. # of objects:        $maxObjects"
}
# -----------------------------------------------------------------------------
# Lazy (wo)man's 'hdfs dfs -' prefix command
# -----------------------------------------------------------------------------
# Usage:   hdp commandToExecute
# Example: hdp ls -R /data
function hdp() {
  [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

  hdfs dfs -$@
}
# -----------------------------------------------------------------------------
# Lazy (wo)man's 'hdfs dfs -ls' command
# -----------------------------------------------------------------------------
# Usage:   hls [ hdfsDir (default: $HDP_DATA) ]
# Example: hls (= hls $HDP_DATA)
# Example: hls some_dir (= hls $HDP_DATA/some_dir)
# Example: hls /path/to/dir
function hls() {
  local folder="$(__hdfs_folder "$1")"

  hdp ls "$folder"
}
# -----------------------------------------------------------------------------
# Lazy (wo)man's 'hdfs dfs -rm -R' command to remove entire folders
# -----------------------------------------------------------------------------
# Usage:   hrm hdfsDir
# Example: hrm some_dir (= hrm $HDP_DATA/some_dir)
# Example: hrm /path/to/dir
function hrm() {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  local folder="$(__hdfs_folder $1)"

  if [ "$folder" = "$HDP_DATA" ]; then
    echo "$FUNCNAME: cannot remove all of $HDP_DATA" && return 2
  fi

  hdp rm -R "$folder"
}
# -----------------------------------------------------------------------------
# Lazy (wo)man's 'hdfs dfs -du' command
# -----------------------------------------------------------------------------
# Usage:   hdu [ hdfsDir (default: $HDP_DATA) ]
# Example: hdu (= hdu $HDP_DATA)
# Example: hdu some_dir (= hls $HDP_DATA/some_dir)
# Example: hdu /path/to/dir
function hdu() {
  local folder="$(__hdfs_folder $1)"

  hdp du -h "$folder"
}
# -----------------------------------------------------------------------------
# Create a directory in HDFS with appropriate permissions
# -----------------------------------------------------------------------------
# Usage:   hmkdir hdfsDir
# Example: hmkdir new_folder (= hmkdir $HDP_DATA/new_folder)
# Example: hmkdir /path/to/dir
function hmkdir() {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  local folder="$(__hdfs_folder $1)"

  if [ "$folder" != "" ] ; then
    hdp mkdir "$folder"
    hdp chmod -R u+rwx,g=rwx,o=rx "$folder"
  fi
}
# -----------------------------------------------------------------------------
# Copy from local file system to HDFS
# -----------------------------------------------------------------------------
# Usage:   hcp localFileOrFolder hdfsDir
# Example: hcp file.csv some_dir (= hcp file.csv $HDP_DATA/some_dir)
# Example: hcp file.csv /path/to/dir
function hcp() {
  [ $# -ne 2 ] && echo "$FUNCNAME: two arguments are required" && return 1

  local folder="$(__hdfs_folder "$2")"

  if [ "$folder" != "" ] ; then
    hdp copyFromLocal "$1" "$folder"
  fi
}
# -----------------------------------------------------------------------------
# Show recursive HDFS file tree
# -----------------------------------------------------------------------------
# Usage:   htree [ hdfsDir (default: $HDP_DATA) ]
# Example: htree (= htree $HDP_DATA)
# Example: htree some_dir (= htree $HDP_DATA/some_dir)
# Example: htree /path/to/dir
function htree() {
  local folder="$(__hdfs_folder $1)"

  hdp ls -C -R "$folder" | awk '{ print $1 }' | \
    sed -e 's/[^-][^\/]*\//--/g' -e 's/^/ /' -e 's/-/|/'
}
# -----------------------------------------------------------------------------
# Show the number of directories, files and total size per subdirectory
# -----------------------------------------------------------------------------
# Usage:   hcount [ hdfsDir (default: $HDP_DATA) ]
# Example: hcount (= hcount $HDP_DATA)
# Example: hcount some_dir (= hcount $HDP_DATA/some_dir)
# Example: hcount /path/to/dir
function hcount() {
 local folder="$(__hdfs_folder "$1")"

  hdfs dfs -ls -C "$folder" | awk '{ system("hdfs dfs -count -h " $1) }'
}
# -----------------------------------------------------------------------------
# Remove all empty subdirectories
# -----------------------------------------------------------------------------
# Usage:   hclear hdfsDir
# Example: hclear some_dir (= hclear $HDP_DATA/some_dir)
# Example: hclear /path/to/dir
function hclear() {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  local folder="$(__hdfs_folder "$1")"

  hdp ls -C -d "$folder" | \
    awk '{ system("hdfs dfs -count " $1) }' | \
    awk 'index($2, "0") { system("hdfs dfs -rm -R " $4) }'
}
# -----------------------------------------------------------------------------
# Show list of most recent YARN applications
# -----------------------------------------------------------------------------
# Usage:   ylist [ numApps [ appStates [ appTypes ]]]
# Example: ylist (= ylist 10)
# Example: ylist 50 KILLED SPARK,MAPREDUCE
function ylist() {
  local num="${1:-10}"
  local states="${2:-ALL}"

  local apps=""
  if [[ "$3" != "" ]]; then
    apps="-appTypes ${3^^}"
  fi

  local cmd="yarn application -list $apps -appStates ${states^^}"
  eval "$cmd | \grep '^application_' | sort | tail -n$num"
}
# -----------------------------------------------------------------------------
# Show list of most recent YARN applications roughly every thirty seconds
# -----------------------------------------------------------------------------
# Usage:   ymon [ numApps [ appStates [ appTypes ]]]
# Example: ymon (= ymon 10)
# Example: ymon 5 RUNNING SPARK,MAPREDUCE
function ymon() { while sleep 30; do echo "$(date)"; ylist $@; done; }
# -----------------------------------------------------------------------------
# Show list of most recent completed (incl. failed/killed) YARN applications
# -----------------------------------------------------------------------------
# Usage:   ydone [ numApps (default: 10) ]
# Example: ydone (= ylast 10)
# Example: ydone 50 SPARK
function ydone() {
  ylist "${1:-10}" "FINISHED,FAILED,KILLED" "$2"
}
# -----------------------------------------------------------------------------
# Show logs of last completed (incl. failed/killed) YARN application
# -----------------------------------------------------------------------------
# Usage:   ylast [ appTypes ]
# Example: ylast
# Example: ylast SPARK
function ylast() {
  ydone "1" "$1" | \
    awk '{ system("yarn logs -applicationId " $1) }'
}
# -----------------------------------------------------------------------------
# Show list of most recent running YARN applications
# -----------------------------------------------------------------------------
# Usage:   ycurr [ numApps (default: 10) ]
# Example: ycurr (= ycurr 10)
# Example: ycurr 50 SPARK
function ycurr() {
  ylist 1 "$1" "RUNNING" "$2" | awk '{ system("ylog " $1) }'
}

# -----------------------------------------------------------------------------
# Show log for specific YARN application ID
# -----------------------------------------------------------------------------
# Usage:   ylog applicationId
# Example: ylog application_1234567890_0042
function ylog() {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  yarn logs -applicationId "$1"
}
# -----------------------------------------------------------------------------
# Show errors from log for specific YARN application ID
# -----------------------------------------------------------------------------
# Usage:   yerr applicationId
# Example: yerr application_1234567890_0042
function yerr() {
  [ $# -ne 1 ] && echo "$FUNCNAME: one argument is required" && return 1

  yarn logs -applicationId "$1" | grep -n5 ' ERROR '
}

# -----------------------------------------------------------------------------
# Cycle through filtered errors from log for specific YARN application ID
# -----------------------------------------------------------------------------
# Usage:   yc applicationId [ additionalRegEx (default: 'Caused by| ERROR ')]
# Example: yc application_1234567890_0042
# Example: yc application_1234567890_0042 ' FATAL '
# Note:    press 'n' (next) and 'N' (previous) to cycle through matches
function yc() {
  [ $# -lt 1 ] && echo "$FUNCNAME: at least one argument is required" && return 1
 
  local pattern="Caused by| ERROR "
  if [[ ! -z $2 ]]; then pattern="${pattern}|$2"; fi
  ylog "$1" | grep -vE "${__IGNORE_ERRORS}" | less -Np "$pattern"
}
