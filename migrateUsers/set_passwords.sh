#!/bin/bash

if [ ! $# -eq 1 ]; then
	echo "Usage: $0 file2import"
	exit 1
fi

egrep '(^web[0-9]+)' "$1" | while read line; do
	uname=`echo $line | cut -f1 -d\:`
	uhash=`echo $line | cut -f2 -d\:`
	if [ ! "$uhash" = "*" ]; then
	usermod -p $uhash $uname
	fi
done
