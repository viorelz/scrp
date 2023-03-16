#! /bin/bash

notok=0
for host in host19 host21 host23 host25 host28 host29 host31 hostch1 vcs mail pmtool;
do
        i=`find /bkp/$host/var/log/ -type f -mtime -1 | wc -l`;
        if [ $i -eq 0 ]; then list+=" "$host notok=1
            else    ok=0
        fi;
done


mesage=${list[*]}

if [ $notok -ne 0 ]; then
        echo "NO bakups for: "$mesage 
        exit 1
else
        echo "Ok - Files have been modified at least 1 day ago!"
        exit 0
fi

