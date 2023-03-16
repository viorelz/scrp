#!/bin/bash

if [ -f /tmp/high-load-topps ]; then
	echo "Already running"
	exit
fi
touch /tmp/high-load-topps

/usr/lib64/nagios/plugins/check_load -w 8,6,4 -c 15,12,10 | grep OK > /dev/null 2>&1
doit1=$?
/usr/lib64/nagios/plugins/check_swap -w 90% -c 85% | grep OK > /dev/null 2>&1
doit2=$?

if [ $doit1 -gt 0 ] || [ $doit2 -gt 0 ]; then
	top -bn 1 | head -30 >> /var/log/high-load-top.log
	date >> /var/log/high-load-ps.log
	ps axfu >> /var/log/high-load-ps.log
	echo -n "server-status header  " >> /var/log/high-load-ss.log
	date >> /var/log/high-load-ss.log
	/usr/bin/lynx --dump --width=200 --auth=tomcat:RSs73q http://127.0.0.1:8080/manager/status >> /var/log/high-load-ss.log
fi

rm -f /tmp/high-load-topps
