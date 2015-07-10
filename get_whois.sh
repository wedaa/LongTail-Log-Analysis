#!/bin/sh
cd /usr/local/etc
if [ ! -d whois.out ] ; then
	echo "Can not find /usr/local/etc/whois.out, exiting now"
	exit
fi

for ip in `awk '{print $1}' ip-to-country` ; do
echo $ip
if [ -e whois.out/$ip ] ; then
	echo "Found"
else
	echo "NOT found"
	echo "Trying to get it now"
	timeout 10 whois $ip > whois.out/$ip
fi
done
