#!/bin/sh

if [ -f /tmp/cleanOLDandCrappy ]; then
        echo "Already running"
        exit
fi
touch /tmp/cleanOLDandCrappy
cd /var/www

if [ -d /root/ispconfig ]; then
    ## clean new (unchecked) emails older then 90 days
    find . -maxdepth 5 -path '*Maildir/new' | while read line; do find "$line" -type f -mtime +90 -delete; done
    find /root/Maildir/new -type f -mtime +90 -delete
fi

## empty/clean error logs and cache files
find . -mindepth 1 -maxdepth 3 -type f -name error.log -exec ls -1 {} \; | while read line; do cat /dev/null > "$line"; done
find . -mindepth 1 -maxdepth 5 -type f -name '*deprecation*log' | while read line; do cat /dev/null > "$line"; done
find . -mindepth 1 -maxdepth 3 -type d -name typo3temp | while read line; do find "$line" -type f -mtime +15 -delete; done
find . -mindepth 1 -maxdepth 5 -type f -path '*typo3temp*' -name '*log' -delete
find . -mindepth 1 -maxdepth 5 -type f -path '*var/log*' -name '*log' -delete

## empty/clean error logs from home dirs
cd /home
find . -mindepth 1 -maxdepth 5 -type f -path '*log*' -name '*log' -exec truncate -s 0 {} \;

## empty/clean session dirs
cd /home
find /var/opt/remi -mtime +7 -type f -path '*php*/lib/php/session/*' -name 'sess_*' -delete

rm -f /tmp/cleanOLDandCrappy


