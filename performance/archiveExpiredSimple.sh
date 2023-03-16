#!/bin/bash

today=$(date "+%Y.%m.%d")
workDir="/root/expiredDomainArchives/${today}"
#workDir="/root/expiredDomainArchives/2019.03.11"
mkdir -p "$workDir"
cp /tmp/expired.txt "${workDir}/"
echo "" >> "${workDir}/expired.txt"

cat "${workDir}/expired.txt" | while read line; do
    siteName="$line"
    siteID=$(echo $siteName | cut -f1 -d.)
    siteDir="/var/www/${siteName}"

    if [ -d "$siteDir" ] && [[ "$siteName" =~ ".domain.tld" ]]; then
        echo
        echo "Found $siteID  $siteName $siteDir"
        cp "/etc/httpd/vhosts.d/${siteName}.conf" ${workDir}
        tar zcf ${workDir}/${siteName}.tgz $siteDir

        find /var/lib/db_backups/daily -type f  -name "daily_${siteID}*" -mtime -1 -exec cp {} "${workDir}" \;

        mysql -Be "drop database ${siteID}"
        mysql -Be "drop user ${siteID}u@localhost"
    else
        echo "Missing $siteID  $siteName $siteDir"
    fi
done

cat "${workDir}/expired.txt" | while read line; do
    siteName="$line"
    siteID=$(echo $siteName | cut -f1 -d.)
    siteDir="/var/www/${siteName}"

    if [ -d "$siteDir" ] && [[ "$siteName" =~ ".domain.tld" ]]; then
        echo rm -fr "/etc/httpd/vhosts.d/${siteName}.conf" "$siteDir" "/var/www/log/${siteName}*"
    fi
done

