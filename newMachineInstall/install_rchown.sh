#!/bin/bash

ME=$(whoami)
if [ $ME != "root" ]; then
	echo "You must be root to run this."
	echo "Bye, bye motherfucker"
	exit
fi

echo "copying the rchmod file to /usr/bin"
cp -f ./rchown /usr/bin

echo "modifying sudoers file"
cp /etc/sudoers /tmp/sudoers.bak
sed -i 's|/bin/chown,/bin/chmod|/usr/bin/rchown|g' /tmp/sudoers.bak
# check the syntax of the new sudoers file
visudo -cf /tmp/sudoers.bak
if [ $? -eq 0 ]; then
	# the file is OK, so put it back
	cp -f /tmp/sudoers.bak /etc/sudoers
else
	echo "Could not modify the /etc/sudoers file. Please do it manually."
fi
rm /tmp/sudoers.bak
if [ -f /usr/bin/cowsay ]; then
	echo "Done." | cowsay
else
	echo "Done."
fi
