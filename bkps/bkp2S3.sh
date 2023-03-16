#!/bin/bash

MAIL_TO="maintenance@domain.tld"
MAIL_FILE="/root/mail.txt"

DIR_TO_SYNC="/var/www/html"
METADATA_URL="http://169.254.169.254/latest/meta-data"
BUCKET_NAME="ub-backups"

# get the instance name
INSTANCE_ID=$(curl --silent $METADATA_URL/instance-id)
INSTANCE_NAME=$(aws ec2 --output text describe-instances --instance-ids $INSTANCE_ID | grep TAGS | grep -w Name | awk '{print $3}')

echo "Subject: ERROR in S3 sync on $INSTANCE_NAME" > $MAIL_FILE

# do the sync operations
ERRORS=0
# DocumentRoot
msg=$(aws s3 sync $DIR_TO_SYNC s3://$BUCKET_NAME/$INSTANCE_NAME/html --only-show-errors 2>&1)
if [ "$msg" != "" ]; then
	echo $msg >> $MAIL_FILE
	ERRORS=1
fi
# /etc folder
msg=$(aws s3 sync /etc s3://$BUCKET_NAME/$INSTANCE_NAME/etc --no-follow-symlinks --only-show-errors 2>&1)
if [ "$msg" != "" ]; then
        echo $msg >> $MAIL_FILE
        ERRORS=1
fi
# /var/spool/cron folder
msg=$(aws s3 sync /var/spool/cron s3://$BUCKET_NAME/$INSTANCE_NAME/cron --only-show-errors 2>&1)
if [ "$msg" != "" ]; then
        echo $msg >> $MAIL_FILE
        ERRORS=1
fi

# send mail if there were erors
if [ $ERRORS -ne 0 ]; then
	sendmail $MAIL_TO < $MAIL_FILE
fi
rm -f $MAIL_FILE

