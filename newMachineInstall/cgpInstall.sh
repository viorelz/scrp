#!/bin/bash

cd /root/scripts || exit 10

if [ ! $# -eq 1 ] && [ ! $# -eq 2 ]; then
        echo "Usage $0 fqdn [IP]"
        exit
fi

vhostIP='*'
vhostName="${1}"

echo $vhostName | egrep -o '^[a-z0-9]+([-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}?$'
if [ $? -gt 0 ]; then
        echo "Domain name error, exiting!"
        exit 4
fi

if [ ! -z $2 ]; then
	vhostIP="${2}"
fi

svn --quiet co http://svnout.domain.tld:11000/cgp/trunk/ "/var/www/${vhostName}/"
cp "/var/www/${vhostName}/conf/common_sample.inc.php" "/var/www/${vhostName}/conf/common.inc.php"
sed -i "s/local\.com\/cgp/${vhostName}/" "/var/www/${vhostName}/conf/common.inc.php"

cp "templates/vhost_cgp_template.conf" "/etc/httpd/conf.d/${vhostName}.conf"
sed -i "s/vhostIP/${vhostIP}/" "/etc/httpd/conf.d/${vhostName}.conf"
sed -i "s/domainname/${vhostName}/" "/etc/httpd/conf.d/${vhostName}.conf"


