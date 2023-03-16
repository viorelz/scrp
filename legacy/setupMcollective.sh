#!/bin/bash

if [ ! $# -eq 1 ]; then
        echo "Usage $0 'colectives '"
		echo "ir. $0 'mcollective,de,hetzner,ispcfg'"
        exit
fi

mycollectives=$1

if [ -f /etc/yum.repos.d/puppetlabs.repo ]; then
	yum install mcollective* -y
	facter -y > /etc/mcollective/facts.yaml
	cp -f /root/scripts/templates/mcollective/{client,server}.cfg /etc/mcollective/
	sed -i "s/collectives/collectives=${mycollectives}/" /etc/mcollective/server.cfg
	chkconfig mcollective on
	/etc/init.d/mcollective start
else
	echo "No puppet repo, exiting"
	exit 1
fi
