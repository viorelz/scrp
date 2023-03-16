#!/bin/bash

if [ -f /tmp/bkpWWW ]; then
    echo "Already running"
    exit 1
fi
touch /tmp/bkpWWW

APP_ROOT=`dirname "$0"`
ROT=$((($(date +%-d)-1)/7+1))
SNAME="bkpWWW.${ROT}"
isISPC=$2
LOGNAME="/var/log/bkp/${SNAME}"

rm -fr "/opt/bkp/$SNAME"
mkdir -p /var/log/bkp /opt/bkp "/opt/bkp/$SNAME"

if [ ! -f "${APP_ROOT}/excludePaths" ]; then
	echo "missing include/exclude files?"
	rm -f /tmp/bkpWWW
	exit 2
fi

echo "$LOGNAME -- ${APP_ROOT}/excludePaths"

#/usr/bin/rsync -aqz --stats /var/www/vinothek-brancaia.ch/pub/media/ "/opt/bkp/${SNAME}/" >> $LOGNAME 2>&1

mkdir -p "/opt/bkp/${SNAME}/catalog/category/"
/usr/bin/rsync -aqz --stats /var/www/vinothek-brancaia.ch/pub/media/catalog/category/ "/opt/bkp/${SNAME}/catalog/category/" >> $LOGNAME 2>&1
RET_CODE=$?
mkdir -p "/opt/bkp/${SNAME}/catalog/product/"
/usr/bin/rsync -aqz --stats --exclude-from="${APP_ROOT}/excludePaths" /var/www/vinothek-brancaia.ch/pub/media/catalog/product/ "/opt/bkp/${SNAME}/catalog/product/" >> $LOGNAME 2>&1
RET_CODE=$?
RET_CODEF=$(( RET_CODE + RET_CODE ))
mkdir -p "/opt/bkp/${SNAME}/domain/producer/image/"
/usr/bin/rsync -aqz --stats /var/www/vinothek-brancaia.ch/pub/media/domain/producer/image/ "/opt/bkp/${SNAME}/domain/producer/image/" >> $LOGNAME 2>&1
RET_CODE=$?
RET_CODEF=$(( RET_CODE + RET_CODE ))
mkdir -p "/opt/bkp/${SNAME}/weltpixel/owlcarouselslider/images/"
/usr/bin/rsync -aqz --stats /var/www/vinothek-brancaia.ch/pub/media/weltpixel/owlcarouselslider/images/ "/opt/bkp/${SNAME}/weltpixel/owlcarouselslider/images/" >> $LOGNAME 2>&1
RET_CODE=$?
RET_CODEF=$(( RET_CODE + RET_CODE ))

/usr/bin/du -hs "/opt/bkp/${SNAME}/" >> $LOGNAME 2>&1
echo "" >> $LOGNAME
echo "" >> $LOGNAME
echo "" >> $LOGNAME

if [ $RET_CODEF -gt 0 ]
then
    echo "Log is:  ${LOGNAME}" | mail -s "ERROR: backup ${SNAME}" root@localhost
fi

rm -f /tmp/bkpWWW

