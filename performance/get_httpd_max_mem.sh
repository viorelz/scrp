#!/bin/bash

if [ ! $# -eq 1  ]; then
	echo "Usage: $0 apache_user"
	exit 1
fi

apacheusr=$1

lynx --dump --width=200 http://localhost/server-status > /tmp/get_http_max_mem.dump
ps aux --sort -rss | grep $apacheusr | head -n5 | while read line; do
        procid=`echo $line | awk '{print $2}'`
        memrss=`echo $line | awk '{print $6}'`

        echo "PS reported RSS:                                                            $memrss"
        grep $procid /tmp/get_http_max_mem.dump
done
