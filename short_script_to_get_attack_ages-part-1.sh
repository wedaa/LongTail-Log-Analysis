#!/bin/bash
# This is an Eric Wedaa mess-around-script, please leave it be.
# 2015-02-21
for host in `find . -maxdepth 1 -type d |grep ...|egrep -v OLD\|RCS\|messages.old\|netezza\|148`; do
	echo "host is $host"
	z=`basename $host`
	
	IP=`host $z |grep -v IPv6|grep address |awk '{print $NF}'`
	echo "IP is $IP"
	if [[ $IP == "148"* ]]
	then
		echo "hostname is $z"
		echo "On the 148 network"
		cp /dev/null /tmp/$z.sshd_log_entries.txt
		for file in $host/*gz; do
			date=`echo $file |sed 's/.*log-//' |sed 's/.gz//'`
			#echo -n "date is $date,"
			echo "file is $file"
			zcat $file |grep -i sshd  |\
			egrep -v Received\ disconnect\|\
Accepted\ keyboard-interactive/pam\|\
Accepted\ publickey\ for\|\
o=marist\|\
from\ 10\.\|\
from\ 148.100\.\|\
rhost=10\|\
rhost=148.100\|\
closed\ by\ 148.100\|\
closed\ by\ 10\|\
check\ pass\;\ user\ unknown\|\
maps\ to\ cms.it.marist.edu\|\
SUDO-SUCCESS\|\
for\ 148-100\|\
facstaff.ddns.marist.edu\|\
Server\ listening\ on\|\
error\:\ ssh_msg_send\:\ write\|\
Did\ not\ receive\ identification\ string\|\
kernel\|\
subsystem\ request\ for\ sftp    >> /tmp/$z.sshd_log_entries.txt
		done
	fi
done
