#!/bin/bash

if [ -f /tmp/bkpWWW ]; then
    echo "Already running" | mail -s "ERROR: backup ${SNAME}" root@localhost
    exit 1
fi
touch /tmp/bkpWWW

APP_ROOT=`dirname "$0"`

if [ ! -f "${APP_ROOT}/rotationCounter" ]; then
	echo "missing rotationCounter file, creating with counter set to 0"
	echo 0 > "${APP_ROOT}/rotationCounter"
  rotationCounter=0
else
  rotationCounter=$(head -n1 "${APP_ROOT}/rotationCounter")
  rotationCounter=$((rotationCounter + 1))
  if [ $rotationCounter -gt 10 ]; then
    rotationCounter=0
  fi
  echo $rotationCounter > "${APP_ROOT}/rotationCounter"
fi
SNAME="bkpWWW.${rotationCounter}"
LOGNAME="/var/log/bkp/${SNAME}"

mkdir -p /var/log/bkp "/opt/bkp/$SNAME"

if [ ! -f "${APP_ROOT}/includePaths" ]; then
	echo "missing includes file?"
	rm -f /tmp/bkpWWW
	exit 2
fi

echo "$LOGNAME -- ${APP_ROOT}/includePaths"


mkdir -p "/opt/bkp/db_backups/"
/usr/bin/rsync -aqz --stats /var/lib/db_backups/ "/opt/bkp/db_backups/" >> $LOGNAME 2>&1
RET_CODE=$?

mkdir -p "/opt/bkp/${SNAME}/www/"
/usr/bin/rsync -aqz --stats --include-from="${APP_ROOT}/includePaths" --exclude '*'\
                /var/www/ "/opt/bkp/${SNAME}/www/" >> $LOGNAME 2>&1
RET_CODE=$?
RET_CODEF=$(( RET_CODE + RET_CODE ))

# /usr/bin/rsync -e 'ssh -p23' --recursive \
#                 /opt/bkp/ u287197@u287197.your-storagebox.de:/www/ >> $LOGNAME 2>&1
# RET_CODE=$?
# RET_CODEF=$(( RET_CODE + RET_CODE ))

/usr/bin/du -hs "/opt/bkp/${SNAME}/" >> $LOGNAME 2>&1
echo "" >> $LOGNAME
echo "" >> $LOGNAME
echo "" >> $LOGNAME

if [ $RET_CODEF -gt 0 ]
then
    echo "Log is:  ${LOGNAME}"
    # echo "Log is:  ${LOGNAME}" | mail -s "ERROR: backup ${SNAME}" root@localhost
fi

rm -f /tmp/bkpWWW

