#!/bin/bash

if [ ! $# -eq 2 ]; then
	echo "Usage: $0 dbNameListFile dbSuffix"
	exit 1
fi

# dbNameListFile si the file that contains all the DBs you want imported
dbNameListFile=$1
# if the sql file names are like /tmp/dbs/daily_sharebox_2020-04-26_03h04m_Sunday.sql
# THEN dbSuffix is 2020-04-26_03h04m_Sunday.sql
dbSuffix=$2

echo "###### THESE FILES WILL PROBABLY BE IMPORTED"
ls -l /tmp/dbs/daily_*
echo "###### THESE FILES WILL PROBABLY BE IMPORTED"
echo "###### STARTING IMPORT"

cat $dbNameListFile | while read line; do
	#ls -l "/tmp/dbs/daily_${line}_${dbSuffix}"
	#mysql -Be "create database ${line}"
	mysql "$line" < "/tmp/dbs/daily_${line}_${dbSuffix}"
done

