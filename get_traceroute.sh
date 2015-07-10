#!/bin/sh
cd /usr/local/etc
if [ ! -d traceroute.out ] ; then
	echo "Can not find /usr/local/etc/traceroute.out, exiting now"
	exit
fi


for ip in `awk '{print $1}' ip-to-country` ; do
echo $ip
if [ -e traceroute.out/$ip ] ; then
	echo "Found"
else
	echo "NOT found"
	echo "Trying to get it now"
	timeout 20 traceroute $ip > traceroute.out/$ip
fi
done
