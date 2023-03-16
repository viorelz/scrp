#!/bin/bash

cd /var/www

ls -1d *domain* | while read line; do
    cd /var/www
    if [ -d "$line" ]; then
        cd "/var/www/${line}"
        if [ -f "wp-config.php" ]; then
            chmod -R go-w *
            chmod -R g+w wp-content
            chmod -R g-w wp-content/themes
            chmod -R g-w wp-content/plugins
            chmod go-rwx xmlrpc.php
            ls -l xmlrpc.php
        fi
    fi
done

