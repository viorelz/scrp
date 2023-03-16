#!/bin/bash

res=`whoami | grep root`
myuser=$?
if [ ! $myuser -eq 0 ]; then
	echo "Error checking your user... exiting!"
	exit 1
fi

egrep -io 'centos.*[56]' /etc/redhat-release
if [ ! $? -eq 0 ]; then
	echo "Is this not CentOS 5 or 6? Exiting!"
	exit 2
fi

rel=6
egrep -io '(centos[ a-zA-Z]+5)' /etc/redhat-release
retval=$?
if [ $retval -eq 0 ]; then
	rel=5
elif [ $retval -gt 1 ]; then
	echo "Something went wrong with the release check... exiting!"
	exit 3
fi

yum install wget -y
yum update yum -y


if [ $rel -eq 5 ]; then
	rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
	wget -o /dev/null http://apt.sw.be/redhat/el5/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm

	rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL
	wget -o /dev/null http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm

	if [ ! -f /etc/yum.repos.d/epel.repo ]; then
		yum localinstall epel-release-5-4.noarch.rpm -y
	fi
	if [ ! -f /etc/yum.repos.d/rpmforge.repo ]; then
		yum localinstall rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm -y
	fi
elif [ $rel -eq 6 ]; then
	wget -o /dev/null --user=mirror --password=CK8ZzqwW http://mirror.cust20.domain.tld/epel-release-6-8.noarch.rpm
	wget -o /dev/null --user=mirror --password=CK8ZzqwW http://mirror.cust20.domain.tld/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

	if [ ! -f /etc/yum.repos.d/epel.repo ]; then
		yum localinstall epel-release-6-8.noarch.rpm -y
	fi
	if [ ! -f /etc/yum.repos.d/rpmforge.repo ]; then
		yum localinstall rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm -y
	fi
fi

alias cp='cp'
cp /root/scripts/templates/bashrc /root/.bashrc

yum install tree bind-utils screen lynx vim-enhanced mailx\
 dstat iotop tcpdump iptraf ntp telnet nc lftp man pwgen rsync jwhois\
  smem openssh-clients mc strace lsof wget git subversion hdparm parted -y

#yum install nrpe nagios-plugins-disk nagios-plugins-load nagios-plugins-swap nagios-plugins-users nagios-plugins-mailq -y
#cp -f /root/scripts/templates/nrpe.cfg_cent6 /etc/nagios/nrpe.cfg
#cp -f /root/scripts/templates/nrpe_check_automysqlbackup.sh /usr/lib64/nagios/plugins/check_automysqlbackup.sh
#cp -f /root/scripts/templates/nrpe_check_collectd.sh /usr/lib64/nagios/plugins/check_collectd.sh
#chkconfig nrpe on
#/etc/init.d/nrpe start


