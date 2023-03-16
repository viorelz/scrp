#!/bin/bash

mv /etc/postfix/transport /etc/postfix/transport.old
cat /dev/null > /etc/postfix/transport

mysql -Be 'select domain from domain where active=1 and domain!="ALL"' mta | grep -v 'domain' > /etc/postfix/transport.ALL
cp /etc/postfix/transport.ALL /etc/postfix/transport.NONEXT
cat /etc/postfix/transportExternalForwards | while read -r extFwdLine; do
    #echo "----${extFwdLine}----"
    grep -v "$extFwdLine" /etc/postfix/transport.NONEXT > /etc/postfix/transport.TMP
    cp /etc/postfix/transport.TMP /etc/postfix/transport.NONEXT
    echo "@${extFwdLine}      extfwd:" >> /etc/postfix/transport
    #cat /etc/postfix/transport.TMP
done
cat /etc/postfix/transport.NONEXT | while read -r nonExternal; do
    echo "@${nonExternal}      extpfa:" >> /etc/postfix/transport
done
rm -f /etc/postfix/transport.NONEXT /etc/postfix/transport.TMP

cat /etc/postfix/transport

/usr/sbin/postmap /etc/postfix/transport
/usr/bin/systemctl reload postfix

