#!/bin/bash

today=$(date "+%Y.%m.%d")
workDir="/root/expiredDomainArchives/${today}"
#workDir="/root/expiredDomainArchives/2019.03.11"
mkdir -p "$workDir"
cp /tmp/expired.txt "${workDir}/"
echo "" >> "${workDir}/expired.txt"

cat "${workDir}/expired.txt" | while read line; do
	siteID=$(echo $line | cut -f1 -d\ )
	siteName=$(echo $line | cut -f2 -d\ )
	siteDir="/var/www/web${siteID}"

	if [ -d "$siteDir" ] && [ ! -n "$siteID" ]; then
		#ls -l "/var/www/${siteName}"
		#echo "$siteDir"
		echo "tar zcf ${workDir}/${siteName}.tgz $siteDir"
		tar zcf ${workDir}/${siteName}.tgz $siteDir

    	echo "$line"
    	#find /var/lib/db_backups/daily -type f  -name "daily_web${siteID}db*" -mtime -2
    	find /var/lib/db_backups/daily -type f  -name "daily_web${siteID}db*" -mtime -2 -exec cp {} "${workDir}" \;
	else
		echo "Missing $siteID  $siteName"
	fi
done
