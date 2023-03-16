#!/bin/bash

cd /var/spool/postfix
for d in incoming active maildrop deferred bounce; do
	chgrp -R postdrop "$d"
	find "$d" -type d -exec chmod g+x {} \;
	chmod -R g+r "$d"
done
usermod -G postdrop nrpe
/usr/bin/systemctl restart nrpe.service
#/etc/init.d/nrpe restart

