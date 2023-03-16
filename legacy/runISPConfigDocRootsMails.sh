#!/bin/bash

find /var/www -maxdepth 1 -mindepth 1 -type d -name 'web[0-9]*' | while read line; do
	if [ -d "${line}/web" ]; then
		siteNameDir="$(ls -l /var/www/ | grep -w "${line}" | tail -n 1 | egrep -o '(www.*)')"
		find "${line}/user/" -type d -name 'new' -exec du -hs {} \; | grep G

		#find "${line}/web" -type d -iname 'phpmyadmin'
	fi
done

