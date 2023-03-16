#!/bin/bash


if [ ! $# -eq 1 ]; then
    echo "Usage $0 site_prefix (ie. web82)"
    exit 1
fi

siteprefix=$1

if [ ! -d "/var/www/$siteprefix" ]; then
	echo "No such docroot:  /var/www/$siteprefix, exiting!"
	exit 2
fi

cd /var/www/$siteprefix
pwd

#wget --user=mirror --password=CK8ZzqwW -o /dev/null http://mirror.cust20.domain.tld/typo3.tgz
tar zxf typo3.tgz
mv web web.ispconfig
mv blankpackage-* web
chown -R "${siteprefix}_admin:${siteprefix}" "/var/www/${siteprefix}/web"
cd "/var/www/${siteprefix}/web"
chmod g+w  typo3temp/ typo3temp/pics/ typo3temp/temp/ typo3temp/llxml/ typo3temp/cs/ typo3temp/GB/ typo3conf/ typo3conf/localconf.php typo3conf/ext/ typo3conf/l10n/ typo3/ext/ uploads/ uploads/pics/ uploads/media/ uploads/tf/ fileadmin/ fileadmin/_temp_
mysql -Be "ALTER DATABASE ${siteprefix}db1 DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"

