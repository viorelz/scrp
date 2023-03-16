#!/bin/bash
cd /etc/postfix/ssl
umask 022
for legth in 512 1024 2048
do
    openssl dhparam -out dh_$legth.tmp $legth
    mv dh_$legth.tmp dh_$legth.pem
    chmod 644 dh_$legth.pem
done

