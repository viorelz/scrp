#!/bin/bash

if [ -f /tmp/mediaBKP ]; then
    echo "Already running"
    exit
fi
touch /tmp/mediaBKP

dayOfWeek=`date "+%u"`
FTP_PASSWORD='YOURpwHERE'
export FTP_PASSWORD
mail_to="maintenance@domain.tld"
me=$(basename "$0")




function mail_error {
    resp=$(tail --lines=1 /var/log/duplicity/bkp.log)
    echo $resp | mail -s "Albiro backup error in $me" $mail_to
        exit -1
}


if [ $dayOfWeek = "1" ]
then
    #if it is Monday do full backup
    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=media /var/www/docroot/pub/media/ ftp://yourFtpUser@yourFtpSite//media_bkp/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
else
    #if it is not Monday then do incremental backups
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=media /var/www/docroot/pub/media/ ftp://yourFtpUser@yourFtpSite//media_bkp/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
fi

#delete all that is older than 3 months (the last 12 full backups) 
duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=media remove-all-but-n-full 12 --force ftp://yourFtpUser@yourFtpSite//media_bkp/ >> /var/log/duplicity/del_bkp.log 2>&1
ret_code=$?
if [ $ret_code -gt 0 ]; then
    mail_error
fi
#delete all incremental backups except the last full backup set, and its incremental backups
duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=media remove-all-inc-of-but-n-full 2 --force ftp://yourFtpUser@yourFtpSite//media_bkp/ >> /var/log/duplicity/del_bkp.log 2>&1
ret_code=$?
if [ $ret_code -gt 0 ]; then
    mail_error
fi


rm -f /tmp/mediaBKP

