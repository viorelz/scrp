#!/bin/bash

if [ -f /tmp/postfixSuicide ]; then
        echo "Already running"
            exit
        fi
        touch /tmp/postfixSuicide

/usr/lib64/nagios/plugins/check_postfix_queue -c 200 | grep CRITICAL
if [ $? -eq 0 ]; then
    /sbin/service postfix stop
fi

rm -f /tmp/postfixSuicide

