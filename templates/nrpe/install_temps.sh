#!/bin/bash

echo "Copying plugin files"
cp check_core_temp.sh /usr/lib64/nagios/plugins
cp check_hdd_temp.sh /usr/lib64/nagios/plugins

echo "Copying temps.cfg"
cp temps.cfg /etc/nrpe.d

echo "Adding line to /etc/sudoers"
# Take a backup of sudoers file and change the backup file.
cp /etc/sudoers /tmp/sudoers.bak
echo "
nrpe ALL=(root)  NOPASSWD: /usr/lib64/nagios/plugins/check_hdd_temp.sh
" >> /tmp/sudoers.bak
# Check syntax of the backup file to make sure it is correct.
visudo -cf /tmp/sudoers.bak
if [ $? -eq 0 ]; then
  # Replace the sudoers file with the new only if syntax is correct.
  sudo cp /tmp/sudoers.bak /etc/sudoers
else
  echo "Could not modify /etc/sudoers file. Please do this manually."
fi

echo "Restarting nrpe service"
systemctl restart nrpe.service

echo "Done"
