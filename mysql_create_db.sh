#!/bin/bash

which python3 > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "python3 missing, exiting!"
	exit 1
fi

if [ ! $# -eq 1 ] && [ ! $# -eq 3 ]; then
        echo "Usage $0 sitename [user pass]"
        exit
fi

if [ ! -f rpwgen.py ]; then
	echo "rpwgen not found, exiting!"
	exit 1
fi

sitename=$1
if [ $# -eq 1 ]; then
	mysqluser="${sitename}u"
    mysqlpass=$(./rpwgen.py)
elif [ $# -eq 3 ]; then
	mysqluser=$2
	mysqlpass=$3
fi

mysqlconn="mysql -e"
#mysqlconn="echo "

$mysqlconn "CREATE DATABASE $sitename"
$mysqlconn "CREATE user $mysqluser@localhost IDENTIFIED BY '${mysqlpass}'"
$mysqlconn "GRANT ALL ON $sitename.* TO $mysqluser@localhost"
$mysqlconn "FLUSH PRIVILEGES"

echo "db_name: $sitename"
echo "u/p:  $mysqluser / ${mysqlpass}"

