HDP_DATA="/data"
HIVE_SERVER="localhost"
HIVE_PORT="10000"

alias beehive='beeline -u jdbc:hive2://$HIVE_SERVER:$HIVE_PORT -n $USER -p none' # in scripts
alias bee='beehive --color=true' # interactive use only
