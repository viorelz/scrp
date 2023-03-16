#use ";" as separator in accountlist file, like: Cristi Toganel;cristian.toganel@domain.ro
#
#! /bin/bash
line=$(head -n 1 /root/macko/accountlist);
domain=`echo $line | awk -F "@" '{print $2}'`;

cat /root/macko/accountlist | while read poz; 
do 
	pass=$(mkpasswd -l 12 -d 3 -C 3 -c 4 -s 0); 
	/var/www/pfa.host23.domain.tld/scripts/postfixadmin-cli mailbox add `echo $poz | awk -F ";" '{print $2}'` --name `echo $poz | awk -F ";" '{print $1}'` --quota 0 --active 1 --password $pass --password2 $pass ; 
	echo 'u/p:' `echo $poz | awk -F ";" '{print $2}'`' /' $pass ; 
done;
