#!/bin/bash

modified=`find /var/lib/collectd -type f -mtime -1 | wc -l`;
if [ $modified -eq 0 ]; then
	echo "No modified files"
	exit 1
else
	echo "Ok - Files have been modified at least 1 day ago!"
	exit 0
fi

