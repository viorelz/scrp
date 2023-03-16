#!/bin/bash


find /var/www -mindepth 1 -maxdepth 1 -type d -name '*web*'| while read line; do
	if [ -f "${line}/web/shell/log.php" ];
	then
		echo "$line";
		if [[ "$1" = "status" ]]; then
			/usr/bin/php "${line}/web/shell/log.php" status
		else
			/usr/bin/php "${line}/web/shell/log.php" --clean --days 1
		fi
	fi
done

