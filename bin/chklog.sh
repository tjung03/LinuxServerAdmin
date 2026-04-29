#!/bin/bash

export LANG=en_US.UTF-8


if [ $# -ne 1 ] ; then
	echo "Usage: $0 <Log filename>"
	exit 1
fi
LOGFILE="$1"

if [ ! -f "$LOGFILE" ]; then
	echo "Error: file not found: $LOGFILE"
	exit 2
fi

MONTH=$(date +'%b')
DAY=$(date +'%e')
grep -E "$MONTH $DAY" "$LOGFILE" | grep -E -n -i --color=auto 'warn|error|fail|crit|alert|emerg'
