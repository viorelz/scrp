#!/bin/bash

UPDATES_FILE="/root/updates.txt"
MAIL_TO="maintenance@domain.tld"
MAIL_SUBJECT="Updates for $HOSTNAME"

## get the available updates
yum check-update > $UPDATES_FILE

## delete the useless lines
#get the first empty line
EMPTY_LINE=`grep -n -E ^$ $UPDATES_FILE | awk -F: '{print $1}'`

#check if there are updates
if [ $EMPTY_LINE ]
then
	#delete the useless lines
	sed -i "1,$EMPTY_LINE d" $UPDATES_FILE

	## send mail with the result
	mail -s "$MAIL_SUBJECT" $MAIL_TO < $UPDATES_FILE
fi
sleep 2
rm -f $UPDATES_FILE

