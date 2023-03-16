#!/bin/bash

USER="develh"
USR_TOKEN="default_user"
PWD_TOKEN="default_password"
TEMPLATE="templates/ftp_passwd.tpl"
PW_LENGTH=6

cd /root/scripts

#generate the new password
PWD=`pwgen --ambiguous --secure $PW_LENGTH 1`
#encrypt the password
E_PWD=`perl -e "print crypt('$PWD', 're');"`
#change the user password
#set the new password on the Web page 
echo $PWD | passwd $USER --stdin
#echo "echo $PWD | passwd $USER --stdin"
#set the new password on the Web page 
cp $TEMPLATE index.html
sed -i "s/$USR_TOKEN/$USER/g" index.html
sed -i "s/$PWD_TOKEN/$PWD/g" index.html

mv index.html /var/www/pp9r.cust20.domain.tld/index.html

