#!/bin/bash

if [ ! $# -eq 2 ] && [ ! $# -eq 3 ]; then
	echo "Usage $0 domainFQDN localsysuser [repo]"
	exit
fi

domainFQDN=$1
localsysuser=$2
biggestport=`egrep -wo "(3[0-9]+{3})" /etc/bluepill/bluepill.conf | sort -nr | head -n 1`; let "port = $biggestport + 10"; echo "Chosen port is $port";
if [ ! -z $3 ]; then
	gitrepo=$3
else
	gitrepo="EMPTY"
fi
localsysuserpass=`pwgen --secure --ambiguous 12 1`
localsysuserpassenc=`perl -e "print crypt('$localsysuserpass', 're');"`

errcode=0

#check if named database exists
DBNAMES="`/usr/bin/mysql -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${localsysuser}'\G"`"
echo "$DBNAMES"

fgrep --quiet -w $localsysuser /etc/passwd
if [ ! $? -eq 1 ]; then
	echo "User $localsysuser already exists or grep error, exiting!"
	errcode=1
fi

if [[ "$DBNAMES" =~ "$localsysuser" ]]; then
	echo "Database already exists... this is probably because a DB $localsysuser already exists, exiting!"
	echo
	errcode=2
fi

if [ -d "/home/${localsysuser}/${domainFQDN}" ]; then
	echo "Directory /home/${localsysuser}/${domainFQDN} already exists, exiting!"
	errcode=3
fi

if [ ! $errcode -eq 0 ]; then
	exit $errcode
fi

#echo "gata"; exit

useradd -g nginx -p "$localsysuserpassenc" "$localsysuser"
cp /root/scripts/create_ruby_hosting_helper.sh "/home/${localsysuser}/"
su -c "/home/${localsysuser}/create_ruby_hosting_helper.sh" "$localsysuser"


echo "Enabling git access and cloning repo"
cp /root/scripts/templates/netrc_template "/home/${localsysuser}/.netrc"
if [[ ! "$gitrepo" = "EMPTY" ]]; then
	git clone "$gitrepo" "/home/${localsysuser}/${domainFQDN}"
else
	mkdir "/home/${localsysuser}/${domainFQDN}"
fi
chown -R "${localsysuser}:nginx" "/home/${localsysuser}/"
chmod g+rx "/home/${localsysuser}/"

echo "Creating /etc/nginx/vhosts.d/${domainFQDN}.conf"
cp -f /root/scripts/templates/nginx_vhost_template.conf "/etc/nginx/vhosts.d/${domainFQDN}.conf"
chown "${localsysuser}:nginx" "/home/${localsysuser}/${localsysuser}app.yml"
sed -i "s/localsysuser/${localsysuser}/" "/etc/nginx/vhosts.d/${domainFQDN}.conf"
sed -i "s/domainFQDN/${domainFQDN}/" "/etc/nginx/vhosts.d/${domainFQDN}.conf"
sed -i "s/PORT/${port}/" "/etc/nginx/vhosts.d/${domainFQDN}.conf"
/usr/sbin/service nginx reload

echo "Creating thin yml config file /home/${localsysuser}/${localsysuser}app.yml"
cp -f /root/scripts/templates/thinapp.yml "/home/${localsysuser}/${localsysuser}app.yml"
sed -i "s/localsysuser/${localsysuser}/" "/home/${localsysuser}/${localsysuser}app.yml"
sed -i "s/domainFQDN/${domainFQDN}/" "/home/${localsysuser}/${localsysuser}app.yml"
sed -i "s/PORT/${port}/" "/home/${localsysuser}/${localsysuser}app.yml"

echo "Adding bluepill job in /etc/bluepill/bluepill.conf"
bluepjob="job(app, \"${localsysuser}\", \"${domainFQDN}\", \"${port}\", \"${localsysuser}\")"
sedregex="s/end \#LAST LINE/${bluepjob}\nend #LAST LINE/"
sed -i "$sedregex" /etc/bluepill/bluepill.conf
echo "Adding bluepill job in /etc/sysconfig/bluepill"
sedregex="s/SERVICE_NAME=\"/SERVICE_NAME=\"${localsysuser} /"
sed -i "$sedregex" /etc/sysconfig/bluepill


#/etc/init.d/nginx restart
#/etc/init.d/bluepill restart

echo
echo "http://${domainFQDN}"
echo
echo "ftp/ssh:  ${domainFQDN}"
echo "u/p:  $localsysuser / $localsysuserpass"
echo "docroot:  /home/${localsysuser}/${domainFQDN}"
echo
echo "http://${localsysuser}.cust20.domain.tld/phpmyadmin/"
/root/scripts/mysql_create_db.sh $localsysuser

