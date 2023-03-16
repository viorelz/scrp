#!/bin/bash

if [ ! $# -eq 1 ]; then
	echo "Usage: $0 file2import"
	exit 1
fi

egrep '(^web[0-9]+)' $1 | while read line; do
	gname=`echo $line | cut -f1 -d\:`
	gid=`echo $line | cut -f3 -d\:`
	echo "$gname   $gid"
	groupadd -g $gid $gname
done
