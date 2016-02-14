#!/bin/sh
cd /usr/local/etc/tor_exit_notes/
if [ -e exit-addresses ] ; then
	/bin/rm exit-addresses
fi
wget https://check.torproject.org/exit-addresses
date=`date +%Y-%m-%d`
mv exit-addresses exit-addresses-$date

awk '$1 == "ExitAddress"{print $2}' exit-addresses-$date  >exit-addresses-$date-ip-only


