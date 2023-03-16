#!/bin/sh

if [ ! $# -eq 1 ]; then
	echo "Usage $0 mail_list_file (ie. /usr/majordomo/lists/comun)"
	exit 1
fi

maillistfile=$1

cat $maillistfile | cut -d\@ -f1 | while read line; do
	#echo
	#echo
	#echo "Trying: $line"
	grep -w "$line" /etc/passwd > /dev/null 2>&1
	if [ $? -eq 1 ]; then
		#echo "Not found, searching aliases"
		grep -w "is.domain.tld" /etc/aliases | grep -w "$line" > /dev/null 2>&1
		if [ $? -eq 1 ]; then
			echo $line
		fi
	fi
done
