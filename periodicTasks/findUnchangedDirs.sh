#!/bin/bash

## script to find changed or unchanged directories of files within the past specified days
## it will search your current path recursively for modified dirs or files
## you can also search for dirs with changed contents by specifying the opposite param


if [ ! $# -eq 1 ] && [ ! $# -eq 2 ]; then
    echo "Usage $0 daysOld [opposite]"
    exit
fi
daysOld="$1"
invert="$2"

tod=$(date "+%Y.%m.%d");
echo -n "Working in "
pwd

find . -mindepth 1 -maxdepth 1 -type d | while read -r line; do
    foundF=$(find "$line" -mindepth 1 -mtime "-${daysOld}" | wc -l);
    if [ "$foundF" -eq 0 ] && [ ! "$invert" = "opposite" ]; then
        ## this dir had NOT been changed within the past daysOld days

        #echo -n "$line  $foundF  ";
        du -sk "$line"
        #rsync -va -e ssh -i /root/.ssh/id_rsa "${line}" "root@bkp2.domain.tld:\"/mnt/tmp1/${line}/\""
        #rm -fr "$line"
    else if [ ! "$foundF" -eq 0 ] &&  [ "$invert" = "opposite" ]; then
            ## this dir has BEEN changed within the past daysOld days

            echo "$line"
        fi
    fi;
done
#> "/root/unchanged.${daysOld}.${tod}.txt"

