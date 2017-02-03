#!/bin/bash
# Databaseline code repository
# 
# Code for post: A Quickie on Collecting Table and Column Statistics in MemSQL
# Base URL:      https://databaseline.bitbucket.io
# Author:        Ian Hellström
# -----------------------------------------------------------------------------
# Source MemSQL configurations and table/column definitions
# -----------------------------------------------------------------------------
source memsql.cfg
readarray -t tabs < tables.cfg
# -----------------------------------------------------------------------------
# Clear log when it exceeds the maximum size
# -----------------------------------------------------------------------------
[[ $(find $MEM_LOG -type f -size +$MEM_MAX_LOG_SIZE 2>/dev/null) ]] && rm -f "$MEM_LOG"
# -----------------------------------------------------------------------------
# Execute a SQL statement on the MemSQL master node
# -----------------------------------------------------------------------------
function exec_memsql() {
  mysql -u "$MEM_USER" -h "$MEM_SERVER" -P "$MEM_PORT" -e "$1" "$MEM_SCHEMA"
}
# -----------------------------------------------------------------------------
# Add an entry to $MEM_LOG
# -----------------------------------------------------------------------------
function add_log_entry() {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%4N")|$(hostname -f)|$USER|$HOME|$1|$2" >> "$MEM_LOG"
}
# -----------------------------------------------------------------------------
# Optimizes the tables and collects column statistics
# -----------------------------------------------------------------------------
function collect_col_stats() {
  add_log_entry "$1" "Row flush started"
  exec_memsql "OPTIMIZE TABLE $1 FLUSH"
  add_log_entry "$1" "Row flush completed"

  add_log_entry "$1" "Table optimization started"
  exec_memsql "OPTIMIZE TABLE $1"
  add_log_entry "$1" "Table optimization completed"

  add_log_entry "$1" "Column statistics collection started"
  exec_memsql "ANALYZE TABLE $1"
  add_log_entry "$1" "Column statistics collection completed"
}
# -----------------------------------------------------------------------------
# Collects range statistics
# -----------------------------------------------------------------------------
function collect_range_stats() {
  add_log_entry "$1" "Range statistics collection started"
  exec_memsql "ANALYZE TABLE $1 COLUMNS $2 ENABLE"
  add_log_entry "$1" "Range statistics collection completed"
}
# -----------------------------------------------------------------------------
# Replace whitespace from a string
# -----------------------------------------------------------------------------
function trim() {
  echo "${*// /}"
}
# -----------------------------------------------------------------------------
# Main logic
# -----------------------------------------------------------------------------
add_log_entry "Script" "Started"

# Collect full table statistics (in parallel)
for tab in "${tabs[@]%:*}"; do collect_col_stats "$tab" & done

# Collect column range statistics (in sequence)
for entry in "${tabs[@]}"; do
  if [[ "$entry" == *":"* ]]; then
    tab="${entry%:*}"
    cols="$(trim "${entry#*:}")"
    collect_range_stats "$tab" "$cols" 
  fi
done

add_log_entry "Script" "Completed"
