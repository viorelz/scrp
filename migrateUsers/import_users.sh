#!/bin/bash

if [ ! $# -eq 1 ]; then
	echo "Usage: $0 file2import"
	exit 1
fi

egrep '(^web[0-9]+)' $1 | while read line; do
	uname=`echo $line | cut -f1 -d\:`
	uid=`echo $line | cut -f3 -d\:`
	gid=`echo $line | cut -f4 -d\:`
	ufname=`echo $line | cut -f5 -d\:`
	udir=`echo $line | cut -f6 -d\:`
	#echo "$uname   $uid   $gid   $ufname   $udir"
	useradd -d $udir -g $gid -M -s /bin/false -u $uid $uname
done
