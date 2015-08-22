#!/bin/sh
#########################################################################
#
# Written by Eric Wedaa
# Released under GPLV2
# Creation Date: June 15th, 2015
# Last Edit: June 16th, 2015
# Last Edit: August 13th, 2015
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

function print_footer {
	file=$1;
	echo "</TABLE>" >> $file
	echo "<BR>" >> $file
	echo "<!--#include virtual=\"/honey/footer.html\" -->" >> $file
}

function print_header {
	file=$1;
	cat << EOFF > $file
<HTML>
<link rel="stylesheet" type="text/css" href="/honey/LongTail.css">
<!--#include virtual="/honey/header.html" -->

<H3>LongTail Log Analysis @ <!--#include virtual="/honey/institution.html" -->
/ IP Addresses Looking For Password Files Only</H3>
<P>This page is updated daily.
Last updated on 
EOFF
date >> $file

cat << EOFF >> $file
<BR>
<BR>
<P>Please see the notes in <A href="https://github.com/wedaa/LongTail-Log-Analysis/blob/master/LongTail_find_badguys_looking_for_passwords.sh">the source code for this script</a> for details on how this analysis is done.
<BR>
<BR>
<TABLE border=1>
<TR>
<TH><a href="/honey/IPs_looking_for_passwords.shtml">IP Address</a></TH>
<TH><a href="/honey/IPs_looking_for_passwords-country.shtml">Country</a></TH>
<TH><a href="/honey/IPs_looking_for_passwords-login-attempts.shtml">Number of ssh<BR>login attempts<BR>from this IP address</a></TH>
<TH><a href="/honey/IPs_looking_for_passwords-pages-requested.shtml">Number Of<BR>Password Pages Requested</a></TH>
<TH><a href="/honey/IPs_looking_for_passwords-non-403.shtml">Count of all<BR>non-403 pages requested</a></TH>
<TH><a href="/honey/IPs_looking_for_passwords-last-seen.shtml">Last date seen</a></TH></TR>
EOFF
}

print_header "/var/www/html/honey/IPs_looking_for_passwords.shtml" ;
print_header "/var/www/html/honey/IPs_looking_for_passwords-country.shtml" ;
print_header "/var/www/html/honey/IPs_looking_for_passwords-login-attempts.shtml" ;
print_header "/var/www/html/honey/IPs_looking_for_passwords-pages-requested.shtml" ;
print_header "/var/www/html/honey/IPs_looking_for_passwords-non-403.shtml" ;
print_header "/var/www/html/honey/IPs_looking_for_passwords-last-seen.shtml" ;

/usr/local/etc/catall.sh  /var/log/httpd/access_log*  /var/log/httpd/access_log|\
egrep -v ~148.100\|^10\. |\
egrep -v 'GET /honey/LongTail.css'\|'GET /honey/buttons.css'\|'GET /favicon.ico'\|'GET / HTTP'\|'dict\-'\|'GET /robots.txt'\|'GET /honey/ HTTP'\|'GET // '\|^148\|^10\|^173\|71.107.60.174\|74.120.64.243\|70.209.143\|70.209.129\|74.105.128\|70.209\|70.193.209\|google\|bing\|crawl\|bot\|baidu.com  > /data/tmp/access_log_combined 

cat /data/tmp/access_log_combined |\
	grep \ 403\  |\
	grep password |\
        awk '{print $1}' |sort  > /data/tmp/badguys.txt


#cat << EOFF
#<HTML>
#<link rel="stylesheet" type="text/css" href="/honey/LongTail.css">
#<!--#include virtual="/honey/header.html" -->
#
#<H3>LongTail Log Analysis @ <!--#include virtual="/honey/institution.html" -->
#/ IP Addresses Looking For Password Files Only</H3>
#<P>This page is updated daily.
#Last updated on 
#EOFF
#date
#cat << EOFF
#<BR>
#<BR>
#<P>Please see the notes in <A href="https://github.com/wedaa/LongTail-Log-Analysis/blob/master/LongTail_find_badguys_looking_for_passwords.sh">the source code for this script</a> for details on how this analysis is done.
#<BR>
#<BR>
#<TABLE border=1>
#
#EOFF
#
#echo "<TR><TH>IP Address</TH><TH>Country</TH><TH>Number of ssh<BR>login attempts<BR>from this IP address</TH><TH>Number Of<BR>Password Pages Requested</TH><TH>Count of all<BR>non-403 pages requested</TH><TH>Last date seen</TH></TR>"
#
echo "" > /data/tmp/bad_actors
/bin/rm /data/tmp/bad_actors

# Look for password page requests AND regular page requests here

for ip in `cat /data/tmp/badguys.txt |uniq ` ; do
	attacks_recorded=`grep $ip /var/www/html/honey/attacks/sum2.data |wc -l `
	password_pages_requested=`grep $ip /data/tmp/badguys.txt |wc -l `
	pages_requested=`grep $ip /data/tmp/access_log_combined |grep -v \ 403\  |wc -l `
	last_date_seen=`grep $ip /data/tmp/access_log_combined |tail -1 |awk '{print $4}' |sed 's/\[//'`
	country=`/usr/local/etc/whois.pl $ip |grep -i country|head -1|sed 's/:/: /g'|awk '{print $2}' `
	last_date_seen=`echo $last_date_seen |awk -F'/|:' '{printf "%s/%s/%s %s:%s:%s\n", $3,$2,$1,$4,$5,$6}'`

	if [ "$pages_requested" -lt 3 ]; then
		echo  "$ip : $country : $attacks_recorded : $password_pages_requested : $pages_requested : $last_date_seen" >>/data/tmp/bad_actors
	fi
done


# Sort by IP address

sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n /data/tmp/bad_actors |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed >> /var/www/html/honey/IPs_looking_for_passwords.shtml

sort -t : -k2 /data/tmp/bad_actors |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed >> /var/www/html/honey/IPs_looking_for_passwords-country.shtml
sort -t : -nrk3  /data/tmp/bad_actors |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed >> /var/www/html/honey/IPs_looking_for_passwords-login-attempts.shtml
sort -t : -nrk4  /data/tmp/bad_actors |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed >> /var/www/html/honey/IPs_looking_for_passwords-pages-requested.shtml
sort -t : -nrk5  /data/tmp/bad_actors |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed >> /var/www/html/honey/IPs_looking_for_passwords-non-403.shtml 

cat /data/tmp/bad_actors | sed -e 's/\/Jan\//\/01\//' \
	-e 's/\/Feb\//\/02\//' \
	-e 's/\/Mar\//\/03\//' \
	-e 's/\/Apr\//\/04\//' \
	-e 's/\/May\//\/05\//' \
	-e 's/\/Jun\//\/06\//' \
	-e 's/\/Jul\//\/07\//' \
	-e 's/\/Aug\//\/08\//' \
	-e 's/\/Sep\//\/09\//' \
	-e 's/\/Oct\//\/10\//' \
	-e 's/\/Nov\//\/11\//' \
	-e 's/\/Dev\//\/12\//'  |\
	sort -t : -rk6  |sed 's/^/<TR><TD>/' |sed 's/ : /<\/TD><TD>/g'|sed 's/$/<\/TD><\/TR>/' |sed -f /usr/local/etc/translate_country_codes.sed >> /var/www/html/honey/IPs_looking_for_passwords-last-seen.shtml

#echo "</TABLE>"
#echo "<BR>"
#echo "<!--#include virtual=\"/honey/footer.html\" -->"

print_footer "/var/www/html/honey/IPs_looking_for_passwords.shtml" ;
print_footer "/var/www/html/honey/IPs_looking_for_passwords-country.shtml" ;
print_footer "/var/www/html/honey/IPs_looking_for_passwords-login-attempts.shtml" ;
print_footer "/var/www/html/honey/IPs_looking_for_passwords-pages-requested.shtml" ;
print_footer "/var/www/html/honey/IPs_looking_for_passwords-non-403.shtml" ;
print_footer "/var/www/html/honey/IPs_looking_for_passwords-last-seen.shtml" ;

/bin/rm /data/tmp/bad_actors
/bin/rm /data/tmp/access_log_combined
/bin/rm /data/tmp/badguys.txt
