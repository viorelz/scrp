#!/bin/bash

BKP_PATH="/var/lib/db_backups"
WEEKLY_BKP_PATH="$BKP_PATH/weekly"
DAYS_TO_KEEP=30
DAY=$(date +"%A")
DB_NAME="domaincrm"
DMP_FILE="${BKP_PATH}/${DAY}_${DB_NAME}.sql"

# save last Monday backup
if [ "$DAY" == "Sunday" ]; then
	d="Monday"
	OLD_FILE="${BKP_PATH}/${d}_${DB_NAME}.sql.gz"
	d=$(stat -c %y $OLD_FILE | awk '{print $1}')
	NEW_FILE="${WEEKLY_BKP_PATH}/${d}_${DB_NAME}.sql.gz"
	cp $OLD_FILE $NEW_FILE
fi

# dump the database
/usr/bin/pg_dump --host 127.0.0.1 --port 5432 --username=devel -w --clean $DB_NAME > $DMP_FILE
sleep 1

# compress the dump
/usr/bin/gzip -f $DMP_FILE
sleep 1

# delete older files
/usr/bin/find $WEEKLY_BKP_PATH -type f -mtime +${DAYS_TO_KEEP} -delete

