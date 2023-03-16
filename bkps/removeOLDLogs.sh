#!/bin/bash

if [ -f /tmp/removalOLD ]; then
    echo "Already running"
    exit
fi
touch /tmp/removalOLD

dayOfWeek=`date "+%u"`

if [ -d "/var/log" ]; then
	echo "Entering /var/log";
	find "/var/log" -type f -mtime +366 -delete
fi


rm -f /tmp/removalOLD


