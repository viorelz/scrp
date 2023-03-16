#!/bin/bash

if [ -f /tmp/wwwAndDBs ]; then
    echo "Already running"
    exit
fi
touch /tmp/wwwAndDBs

dayOfWeek=`date "+%u"`

FTP_PASSWORD="DRLM" /usr/bin/duplicity --no-encryption --include="/var/www" --include="/var/lib/db_backups/daily" --exclude '**' / ftp://u@677.your-backup.de/ --full-if-older-than 1W >> /root/rotateFtpBkp.log



rm -f /tmp/wwwAndDBs


