#!/bin/bash
# https://docs.hetzner.com/robot/storage-box/backup-space-ssh-keys


if [ -f /tmp/mediaBKP ]; then
    echo "Already running"
    exit
fi
touch /tmp/mediaBKP

dayOfWeek=`date "+%u"`
FTP_PASSWORD='zJ5Y0nCAMN9dHXIT'
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
    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings --include /var/www/spirac.com/sites/default/settings.php --exclude /var/www/spirac.com/sites/default/files/tmp --exclude /var/www/spirac.com/sites/default/files/temp --include /var/www/spirac.com/sites/default/files --exclude='**' / ftp://u231550@u231550.your-storagebox.de//spirac_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings --include /var/www/qms.spirac.com/sites/default/settings.php --exclude /var/www/qms.spirac.com/sites/default/files/tmp --include /var/www/qms.spirac.com/sites/default/files --exclude='**' / ftp://u231550@u231550.your-storagebox.de//qms_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity full --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings --include /var/www/spironet.spirac.com/sites/default/settings.php --exclude /var/www/spironet.spirac.com/sites/default/files/tmp --include /var/www/spironet.spirac.com/sites/default/files --exclude='**' / ftp://u231550@u231550.your-storagebox.de//spironet_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

else
    #if it is not Monday then do incremental backups (spirac, qms, spironet)
    duplicity --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings --include /var/www/spirac.com/sites/default/settings.php --exclude /var/www/spirac.com/sites/default/files/tmp --exclude /var/www/spirac.com/sites/default/files/temp --include /var/www/spirac.com/sites/default/files --exclude='**' / ftp://u231550@u231550.your-storagebox.de//spirac_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings --include /var/www/qms.spirac.com/sites/default/settings.php --exclude /var/www/qms.spirac.com/sites/default/files/tmp --include /var/www/qms.spirac.com/sites/default/files --exclude='**' / ftp://u231550@u231550.your-storagebox.de//qms_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi

    duplicity --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings --include /var/www/spironet.spirac.com/sites/default/settings.php --exclude /var/www/spironet.spirac.com/sites/default/files/tmp --include /var/www/spironet.spirac.com/sites/default/files --exclude='**' / ftp://u231550@u231550.your-storagebox.de//spironet_files_settings/ >> /var/log/duplicity/bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
fi


#delete all backups but the last 5 full 
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings remove-all-but-n-full 5 --force ftp://u231550@u231550.your-storagebox.de//spirac_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings remove-all-but-n-full 5 --force ftp://u231550@u231550.your-storagebox.de//qms_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings remove-all-but-n-full 5 --force ftp://u231550@u231550.your-storagebox.de//spironet_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
#delete all incremental backups except the last 2 full backup set, and its incremental backups
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spirac_files_settings remove-all-inc-of-but-n-full 2 --force ftp://u231550@u231550.your-storagebox.de//spirac_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=qms_files_settings remove-all-inc-of-but-n-full 2 --force ftp://u231550@u231550.your-storagebox.de//qms_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
    ret_code=$?
    if [ $ret_code -gt 0 ]; then
        mail_error
    fi
    
    duplicity  --no-encryption --archive-dir=/home/duplicity_cache --name=spironet_files_settings remove-all-inc-of-but-n-full 2 --force ftp://u231550@u231550.your-storagebox.de//spironet_files_settings/ >> /var/log/duplicity/del_bkp.log 2>&1
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

echo "df -h" | sftp -i .ssh/storage_box u231550@u231550.your-storagebox.de > /root/STBox_RAW_disk_usage
USAGE="$(cat /root/STBox_RAW_disk_usage | awk '{print $5}' | grep -v Capacity| grep '%' | awk -F '%' '{print $1}')"

if [ "$USAGE" -gt 8 ]; then
    mail -s "Disk space usage on Spirac Backup is: $USAGE%" maintenance@domain.tld < /root/LowDSKspace
fi

rm -f /tmp/DiskSpaceChkRuning

