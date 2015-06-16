#!/bin/sh
#########################################################################
#
# Written by Eric Wedaa
# Released under GPLV2
# Creation Date: June 15th, 2015
# Last Edit: June 16th, 2015
#
#########################################################################
#
# NOTES:
#    This script goes through the Apache webserver access logs and 
# filters out some "boring" webpages (such as buttons.css, etc).  It
# then searches for GET requests that had a 403 response code AND were
# trying to GET a page containing passwords.
#
# It then calculates :
#	attacks_recorded=`grep $ip /var/www/html/honey/attacks/sum2.data |wc -l `
#	password_pages_requested=`grep $ip /data/tmp/badguys.txt |wc -l `
#	pages_requested=`grep $ip /data/tmp/access_log_combined |grep -v \ 403\  |wc -l `
#	last_date_seen=`grep $ip /data/tmp/access_log_combined |tail -1 |awk '{print $4}' |sed 's/\[//'`
#	country=`/usr/local/etc/whois.pl $ip |grep -i country|head -1|sed 's/:/: /g'|awk '{print $2}' `
#
#   If the number of $pages_requested < 3, it then prints the results as 
# these are probably "bad actors" looking for passwords to try against 
# servers.
#
#   Yes, there are more bad actors than this script find as it ignores
# page requests for passwords (ie "Top 20" lists) in an attempt to
# only show the bad actors, and not show legitimate traffic looking 
# at non 403 page requests or legitmate requests to see a webpage.  
#
#   Even so, there may be legitimate traffic so no conclusions should be
# drawn from single IPs requesting only a single page, and the timing of
# the page request does not correlate to any other GET requests.
#
#   Interestingly enough, there are plenty of hits from class C addresses
# that seems to show that those hosts are owned by the bad actors".
#
#   I am showing the number of ssh login attempts from these hosts to 
# show that they seem to be scanning for password pages only, and are 
# not using those results against LongTail honeypots.  Any host scanning
# and then attempting ssh logins is most likely a bad actor.
#########################################################################
/usr/local/etc/catall.sh  /var/log/httpd/access_log*  /var/log/httpd/access_log|\
egrep -v ~148.100\|^10\. |\
egrep -v 'GET /honey/LongTail.css'\|'GET /honey/buttons.css'\|'GET /favicon.ico'\|'GET / HTTP'\|'dict\-'\|'GET /robots.txt'\|'GET /honey/ HTTP'\|'GET // '\|^148\|^10\|^173\|71.107.60.174\|74.120.64.243\|70.209.143\|70.209.129\|74.105.128\|70.209\|70.193.209\|google\|bing\|crawl\|bot  > /data/tmp/access_log_combined 

cat /data/tmp/access_log_combined |\
	grep \ 403\  |\
	grep password |\
        awk '{print $1}' |sort  > /data/tmp/badguys.txt

cat << EOFF
<HTML>
<link rel="stylesheet" type="text/css" href="/honey/LongTail.css">
<!--#include virtual="/honey/header.html" -->

<H3>LongTail Log Analysis @ <!--#include virtual="/honey/institution.html" -->
/ IP Addresses Looking For Password Files Only</H3>
<P>This page is updated daily.
Last updated on 
EOFF
date
cat << EOFF
<BR>
<BR>
<P>Please see the notes in <A href="https://github.com/wedaa/LongTail-Log-Analysis/blob/master/LongTail_find_badguys_looking_for_passwords.sh">the source code for this script</a> for details on how this analysis is done.
<BR>
<BR>
<TABLE border=1>

EOFF
echo "<TR><TH>IP Address</TH><TH>Country</TH><TH>Number of ssh<BR>login attempts<BR>from this IP address</TH><TH>Number Of<BR>Password Pages Requested</TH><TH>Count of all<BR>non-403 pages requested</TH><TH>Last date seen</TH></TR>"

echo "" > /data/tmp/bad_actors
/bin/rm /data/tmp/bad_actors

# Look for password page requests AND regular page requests here

for ip in `cat /tmp/badguys.txt |uniq ` ; do
	attacks_recorded=`grep $ip /var/www/html/honey/attacks/sum2.data |wc -l `
	password_pages_requested=`grep $ip /data/tmp/badguys.txt |wc -l `
	pages_requested=`grep $ip /data/tmp/access_log_combined |grep -v \ 403\  |wc -l `
	last_date_seen=`grep $ip /data/tmp/access_log_combined |tail -1 |awk '{print $4}' |sed 's/\[//'`
	country=`/usr/local/etc/whois.pl $ip |grep -i country|head -1|sed 's/:/: /g'|awk '{print $2}' `
	if [ "$pages_requested" -lt 3 ]; then
		echo  "$ip : $country : $attacks_recorded : $password_pages_requested : $pages_requested : $last_date_seen" >>/data/tmp/bad_actors
	fi
done

# Sort by IP address

sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n /data/tmp/bad_actors |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed


echo "</TABLE>"
echo "<BR>"
echo "<!--#include virtual=\"/honey/footer.html\" -->"


/bin/rm /data/tmp/bad_actors
/bin/rm /data/tmp/access_log_combined
/bin/rm /data/tmp/badguys.txt
