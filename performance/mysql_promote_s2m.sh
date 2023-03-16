#!/bin/bash

myver=`mysql -Be "STATUS;" | grep Ver | egrep -o '(5\.[0-9]\.[0-9]+)' | egrep -o '(5\.[0-9]\.)'`

if [[ "$myver" = "5.5." ]]; then
	mysql -Be "stop slave;  reset slave all;"
else
	mysql -Be "stop slave; change master to MASTER_HOST=''; reset slave;"
fi

