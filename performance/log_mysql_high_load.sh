#!/bin/bash

if [ -f /tmp/mysql-high-load ]; then
	echo "Already running"
	exit
fi
touch /tmp/mysql-high-load

/usr/lib64/nagios/plugins/check_load -w 8,6,4 -c 15,12,10 | grep OK > /dev/null 2>&1
doit=$?

if [ ! $doit -eq 0 ]; then
	mysql -Be "show full processlist" >> /var/log/mysql-high-load.log
fi

rm -f /tmp/mysql-high-load
