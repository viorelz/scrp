#!/bin/bash

EXCLUDE=`/bin/mktemp`
INCLUDE=`/bin/mktemp`
RET_CODE1=0
RET_CODE2=0
HOST_NAME=`hostname --fqdn`
ROT=`date "+%u"`
LOGNAME="/var/log/${HOST_NAME}.${ROT}"

cat /dev/null > "${LOGNAME}"

touch "$EXCLUDE"
touch "$INCLUDE"

if [ -f "/root/scripts/exclude.${HOST_NAME}" ]; then
	cat "/root/scripts/exclude.${HOST_NAME}" >> "$EXCLUDE"
fi

if [ -f "/root/scripts/include.${HOST_NAME}" ]; then
	cat "/root/scripts/include.${HOST_NAME}" >> "$INCLUDE"
fi

echo $LOGNAME
#echo "/usr/bin/rsync -avz --stats --exclude-from=$EXCLUDE /var/www root@ns409763.ip-37-187-139.eu:/var/www/" >> $LOGNAME
echo "/usr/bin/rsync -avz --stats /var/www root@ns409763.ip-37-187-139.eu:/var/www/" >> $LOGNAME
cat $EXCLUDE >> $LOGNAME
/usr/bin/rsync -avz --stats /var/www root@ns409763.ip-37-187-139.eu:/var/www/ >> "$LOGNAME"
RET_CODE1=$?
if [ $RET_CODE1 -gt 0 ]
then
	echo "Log is:  ${LOGNAME}" | mail -s "ERROR: backup ${HOST_NAME}" root@localhost
else
	rm -f $EXCLUDE
	rm -f $INCLUDE
fi

