#!/bin/bash

if [ -f /tmp/mediaBKP ]; then
    echo "Already running"
    exit
fi
touch /tmp/mediaBKP

dayOfWeek=`date "+%u"`
FTP_PASSWORD='YOUR+PASSWORD_HERE'
export FTP_PASSWORD
mail_to="maintenance@domain.tld"
me=$(basename "$0")


function mail_error {
    resp=$(tail --lines=1 /var/log/duplicity/bkp.log)
    echo $resp | mail -s "Spirac backup error in $me" $mail_to
        exit -1
}


if [ $dayOfWeek = "1" ]
then
    #if it is Monday do full backup (spirac, qms, spironet)
    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings --include /var/www/spirac.com/sites/default/settings.php --exclude /var/www/spirac.com/sites/default/files/tmp --exclude /var/www/spirac.com/sites/default/files/temp --include /var/www/spirac.com/sites/default/files --exclude='**' / ftp://yourUser@yourFtpServer//spirac_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings --include /var/www/qms.spirac.com/sites/default/settings.php --exclude /var/www/qms.spirac.com/sites/default/files/tmp --include /var/www/qms.spirac.com/sites/default/files --exclude='**' / ftp://yourUser@yourFtpServer//qms_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings --include /var/www/spironet.spirac.com/sites/default/settings.php --exclude /var/www/spironet.spirac.com/sites/default/files/tmp --include /var/www/spironet.spirac.com/sites/default/files --exclude='**' / ftp://yourUser@yourFtpServer//spironet_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

else
    #if it is not Monday then do incremental backups (spirac, qms, spironet)
    duplicity --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings --include /var/www/spirac.com/sites/default/settings.php --exclude /var/www/spirac.com/sites/default/files/tmp --exclude /var/www/spirac.com/sites/default/files/temp --include /var/www/spirac.com/sites/default/files --exclude='**' / ftp://yourUser@yourFtpServer//spirac_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings --include /var/www/qms.spirac.com/sites/default/settings.php --exclude /var/www/qms.spirac.com/sites/default/files/tmp --include /var/www/qms.spirac.com/sites/default/files --exclude='**' / ftp://yourUser@yourFtpServer//qms_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings --include /var/www/spironet.spirac.com/sites/default/settings.php --exclude /var/www/spironet.spirac.com/sites/default/files/tmp --include /var/www/spironet.spirac.com/sites/default/files --exclude='**' / ftp://yourUser@yourFtpServer//spironet_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
fi


#delete all backups but the last 5 full 
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings remove-all-but-n-full 5 --force ftp://yourUser@yourFtpServer//spirac_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings remove-all-but-n-full 5 --force ftp://yourUser@yourFtpServer//qms_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings remove-all-but-n-full 5 --force ftp://yourUser@yourFtpServer//spironet_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
#delete all incremental backups except the last 2 full backup set, and its incremental backups
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings remove-all-inc-of-but-n-full 2 --force ftp://yourUser@yourFtpServer//spirac_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings remove-all-inc-of-but-n-full 2 --force ftp://yourUser@yourFtpServer//qms_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings remove-all-inc-of-but-n-full 2 --force ftp://yourUser@yourFtpServer//spironet_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
rm -f /tmp/mediaBKP



#check disk space on storagebox

if [ -f /tmp/DiskSpaceChkRuning ]; then
    echo "Already running"
    exit
fi

touch /tmp/DiskSpaceChkRuning

DISKUSED="$(echo du -hs | lftp -u yourUser,URhCjlM9T31pH5tK yourFtpServer | awk -F '.' '{print$1}')"

if [ "$DISKUSED" -gt 80 ]; then
    mail -s "Disk space usage on Spirac Backup is: ${DISKUSED}G used from 100G available" maintenance@domain.tld < /root/LowDSKspace
fi

rm -f /tmp/DiskSpaceChkRuning

