#!/bin/sh
# This runs every hour through cron


########################################################################
#
# Get Today's IPs
#
echo -n "Starting at: "
date;

if [ -e "/var/tmp/LongTail_nmap_hosts.pid" ] ; then
	echo "LongTail_nmap_hosts is still running, aborting out now"
else
	echo "$$" > /var/tmp/LongTail_nmap_hosts.pid
fi

touch current-ip-addresses.txt
rm current-ip-addresses.txt
wget http://longtail.it.marist.edu/honey/current-ip-addresses.txt
grep -v \# current-ip-addresses.txt > current-ip-addresses-munged.txt
rm current-ip-addresses.txt
cd /var/www/html/nmap


DATE=`date +%Y-%m-%d`
for ip in `awk '{print $2}' current-ip-addresses-munged.txt ` ; do
	if [ ! -e $ip.$DATE.txt ] ; then
		echo "Scanning $ip now"
		timeout 600 nmap --host-timeout 15m -v -A -Pn $ip > $ip.$DATE.txt
	else
		echo "Already have $ip"
	fi
done
rm /var/tmp/LongTail_nmap_hosts.pid
echo -n "Done with TODAY at: "
date

########################################################################
#
# Double check we got all of yesterday's IPs
#

echo "Getting yesterday's IPs"

HOUR=`date +%H`

#if [ $HOUR -eq 1 ] ; then
	YESTERDAY=`date +%Y-%m-%d --date="1 day ago"`
	YESTERDAY_DIR=`date +%Y/%m/%d --date="1 day ago"`

	touch todays_ips # Just to make sure it exists before I remove it
	rm todays_ips
	wget http://longtail.it.marist.edu/honey/historical/$YESTERDAY_DIR/todays_ips
	grep -v \# todays_ips > todays_ips-munged.txt
	touch todays_ips # Just to make sure it exists before I remove it
	rm todays_ips

ls -l todays_ips-munged.txt
#cat todays_ips-munged.txt

	for ip in `awk '{print $1}' todays_ips-munged.txt ` ; do
		echo "ip is $ip"
		if [ ! -e $ip.$YESTERDAY.txt ] ; then
			echo "Scanning $ip now"
			nmap -v -A -Pn $ip > $ip.$YESTERDAY.txt 2>&1
		else
			echo "$ip.$YESTERDAY.txt exists"
			ls -l $ip.$YESTERDAY.txt
		fi
	done
#fi
echo -n "Done YESTERDAY at: "
date

