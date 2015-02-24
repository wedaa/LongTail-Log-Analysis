#!/bin/sh 

############################################################################
# This is my crontab entry
# 59 * * * * /usr/local/etc/LongTail.sh >> /tmp/LongTail.sh.out 2>> /tmp/LongTail.sh.out
#
# You need to have /usr/local/etc/whois.pl installed also.  Sure, I could 
# have a faster mysql backend, but I don't NEED it.
#
# I am assuming your /var/log/messages file is really called messages, or 
# messages<something>.  .gz files are ok too.
#
# I am assuming your /var/log/httpd/access_file file is really called 
# access_file, or access_file<something>.  .gz files are ok too.
#
############################################################################
# This reads /usr/local/etc/LongTail.config.  If your file isn't there,
# then this is the only place you need to edit.

function read_local_config_file {
	if [ -e "/usr/local/etc/LongTail.config" ] ; then
		. /usr/local/etc/LongTail.config
	fi
}

############################################################################
# Assorted Variables, you should probably edit /usr/local/etc/LongTail.config
# though...  Otherwise when you install a new version you'll lose your
# configuration
#
function init_variables {
	# Do you want Pretty graphs using jpgraph?  Set this to 1
	# http://jpgraph.net/  JpGraph - Most powerful PHP-driven charts
	GRAPHS=1

	# Do you want debug output?  Set this to 1
	DEBUG=1
	
	# Do you want ssh analysis?  Set this to 1
	DO_SSH=1
	
	# Do you want httpd analysis?  Set this to 1
	DO_HTTPD=1
	
	# Do we obfuscate/rename the IP addresses?  You might want to do this if
	# you are copying your reports to a public site.
	# OBFUSCATE_IP_ADDRESSES=1 will hide addresses
	# OBFUSCATE_IP_ADDRESSES=0 will NOT hide addresses
	OBFUSCATE_IP_ADDRESSES=0
	
	# OBFUSCATE_URLS=1 will hide URLs in the http report
	# OBFUSCATE_URLS=0 will NOT hide URLs in the http report
	# This may not work properly yet.
	OBFUSCATE_URLS=0
	
	# These are the search strings from the "LogIt" function in auth-passwd.c
	# and are used to figure out which ports are being brute-forced.
	# The code for PASSLOG2222 has not yet been written.
	PASSLOG="PassLog"
	PASSLOG2222="Pass2222Log"
	
	# Where are the scripts we need to run?
	SCRIPT_DIR="/usr/local/etc/"
	
	# Where do we put the reports?
	HTML_DIR="/var/www/html/honey/"
	
	#Where is the messages file?
	PATH_TO_VAR_LOG="/var/log/"
	
	#Where is the apache access_log file?
	PATH_TO_VAR_LOG_HTTPD="/var/log/httpd/"
	
	# This is for my personal debugging, just leave them
	# commented out if you aren't me.
	#PATH_TO_VAR_LOG="/home/wedaa/source/LongTail/var/log/"
	#PATH_TO_VAR_LOG_HTTPD="/home/wedaa/source/LongTail/var/log/httpd/"
	
	############################################################################
	# You don't need to edit after this.
	#
	TODAY_AT_START_OF_RUNTIME=`date`
	YEAR=`date +%Y`
	HOUR=`date +%H` # This is used at the end of the program but we want to know it NOW
	YEAR_AT_START_OF_RUNTIME=`date +%Y`
	MONTH_AT_START_OF_RUNTIME=`date +%m`
	DAY_AT_START_OF_RUNTIME=`date +%d`
}

############################################################################
# Lets make sure we can write to the directory
#
function is_directory_good {
	if [ ! -d $1  ] ; then
        	echo "$1 is not a directory, exiting now "
		exit
	fi
	if [ ! -w $1  ] ; then
        	echo "I can't write to /tmp", exiting now
		exit
	fi
}
############################################################################
# Change the date in index.html
#
function change_date_date_in_index {
	DATE=`date`
	sed -i "s/updated on..*$/updated on $DATE/" $1/index.html
	sed -i "s/updated on..*$/updated on $DATE/" $1/index-long.html
	sed -i "s/updated on..*$/updated on $DATE/" $1/graphics.html
}
	
############################################################################
# Make a proper HTML header for assorted columns
#
function make_header {
	# first argument, the full path including the filename you want to write to
	# second argument, the title of the web page
	# Third argument, text for description
	# Other arguments are the column headers
	# NOTE: This destroys $MAKE_HEADER_FILENAME before adding to it.
	MAKE_HEADER_DATE=`date`
	if [ "$#" == "0" ]; then
		echo "You forgot to pass arguments, exiting now"
		exit 1
	fi
	MAKE_HEADER_FILENAME=$1
	#echo "filename is $MAKE_HEADER_FILENAME"
	touch $MAKE_HEADER_FILENAME
	if [ ! -w $MAKE_HEADER_FILENAME ] ; then
		echo "Can't write to $MAKE_HEADER_FILENAME, exiting now"
		exit
	fi
	shift
	
	TITLE=$1
	shift
	
	DESCRIPTION=$1
	shift

	echo "<HTML><!--HEADERLINE -->" > $MAKE_HEADER_FILENAME
	echo "<HEAD><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<META http-equiv=\"pragma\" content=\"no-cache\"><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<TITLE>LongTail Log Analysis $TITLE</TITLE> <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<style> /* HEADERLINE */ " >> $MAKE_HEADER_FILENAME
	echo ".td-some-name /* HEADERLINE */ " >> $MAKE_HEADER_FILENAME
	echo "{ /* HEADERLINE */ " >> $MAKE_HEADER_FILENAME
	echo "  white-space:nowrap; /* HEADERLINE */ " >> $MAKE_HEADER_FILENAME
	echo "  vertical-align:top; /* HEADERLINE */ " >> $MAKE_HEADER_FILENAME
	echo "} /* HEADERLINE */ " >> $MAKE_HEADER_FILENAME
	echo "</style> <!--HEADERLINE --> " >> $MAKE_HEADER_FILENAME

	echo "</HEAD><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<BODY BGCOLOR=#00f0FF><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<H1>LongTail Log Analysis</H1><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<H3>$TITLE</H3><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<P>$DESCRIPTION <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<P>Created on $MAKE_HEADER_DATE<!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	
	if [ $OBFUSCATE_IP_ADDRESSES -gt 0 ] ; then
		echo "<P>IP Addresses have been obfuscated to hide the guilty. <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
		echo "ALL IP addresses have been reset to end in .127. <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	fi

#	echo "<BR><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
#	echo "<BR><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<TABLE border=1><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<TR><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	while (( "$#" )); do
		echo "<TH>$1</TH><!--HEADERLINE -->" >>$MAKE_HEADER_FILENAME
		shift
	done
	echo "</TR><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
}

############################################################################
# Make a proper HTML footer for assorted columns
#
function make_footer {
	# One argument, the full path including the filename you want to write to
	if [ "$#" == "0" ]; then
		echo "You forgot to pass arguments, exiting now"
		exit 1
	fi
	MAKE_FOOTER_FILENAME=$1
	#echo "filename is $MAKE_FOOTER_FILENAME"
	touch $MAKE_FOOTER_FILENAME
	if [ ! -w $MAKE_FOOTER_FILENAME ] ; then
		echo "Can't write to $MAKE_FOOTER_FILENAME, exiting now"
		exit
	fi
	echo "" >> $MAKE_FOOTER_FILENAME
	echo "</TABLE><!--HEADERLINE -->" >> $MAKE_FOOTER_FILENAME
	echo "</BODY><!--HEADERLINE -->" >> $MAKE_FOOTER_FILENAME
	echo "</HTML><!--HEADERLINE -->" >> $MAKE_FOOTER_FILENAME
	if [ $OBFUSCATE_IP_ADDRESSES -gt 0 ] ; then
		hide_ip $1
	fi
}


############################################################################
# Obfuscate any IP addresses found by setting the last octet to 128
# I am assuming that any address in a class C address is controlled
# or owned by whoever owns the Class C
#
# This way the report doesn't name any single user, but blames the
# owner of the Class C range.
#
function hide_ip {
	# One argument, the full path including the filename you want to write to
	if [ "$#" == "0" ]; then
		echo "You forgot to pass arguments, exiting now"
		exit 1
	fi
	sed -i -r 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)[0-9]{1,3}/\1127/g' $1
}


############################################################################
# Count ssh attacks and modify $HTML_DIR/index.html
#
# Called as count_ssh_attacks $HTML_DIR $PATH_TO_VAR_LOG "messages*"
#
function count_ssh_attacks {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks now" ; fi
	TMP_HTML_DIR=$1
	PATH_TO_VAR_LOG=$2
	MESSAGES=$3

	ORIGINAL_DIRECTORY=`pwd`

	TMP_DATE=`date +"%b %e"|sed 's/ /\\ /g'`
echo "DEBUG count_ssh_attacks, tmp_date used to be $TMP_DATE"
	TMP_DATE=`date +"%Y-%m-%e"`
echo "DEBUG count_ssh_attacks, tmp_date now is $TMP_DATE"
	TMP_YEAR=`date +%Y`
	TMP_MONTH=`date +%m`

	#
	# TODAY
	#
	cd $PATH_TO_VAR_LOG
	TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`
	echo $TODAY > $TMP_HTML_DIR/current-attack-count.data
echo "DEBUG TODAY = $TODAY"
#exit;

	#
	# THIS MONTH
	#
	cd $TMP_HTML_DIR/historical/
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_MONTH=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo "DEBUG this month statistics" ; fi
	TMPFILE=$(mktemp /tmp/output.XXXXXXXXXX)
	cat $TMP_YEAR/$TMP_MONTH/*/current-attack-count.data|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "MONTH_COUNT=$n\nMONTH_SUM=$s\nMONTH_AVERAGE=$a\nMONTH_STD=$std\nMONTH_MEDIAN=$med\nMONTH_MAX=$m\nMONTH_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	MONTH_AVERAGE=`printf '%.2f' $MONTH_AVERAGE`
	MONTH_STD=`printf '%.2f' $MONTH_STD`


	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR=`expr $TMP + $TODAY`
	if [ $DEBUG  == 1 ] ; then echo "DEBUG this year statistics" ; fi
	# OK, this may not be 100% secure, but it's close enough for now
	TMPFILE=$(mktemp /tmp/output.XXXXXXXXXX)
	for FILE in  `find $TMP_YEAR/ -name current-attack-count.data` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "YEAR_COUNT=$n\nYEAR_SUM=$s\nYEAR_AVERAGE=$a\nYEAR_STD=$std\nYEAR_MEDIAN=$med\nYEAR_MAX=$m\nYEAR_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	YEAR_AVERAGE=`printf '%.2f' $YEAR_AVERAGE`
	YEAR_STD=`printf '%.2f' $YEAR_STD`


	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
	TMP=0
	for FILE in  `find . -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo "DEBUG ALL  statistics" ; fi
	TMPFILE=$(mktemp /tmp/output.XXXXXXXXXX)
	for FILE in  `find . -name current-attack-count.data` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "EVERYTHING_COUNT=$n\nEVERYTHING_SUM=$s\nEVERYTHING_AVERAGE=$a\nEVERYTHING_STD=$std\nEVERYTHING_MEDIAN=$med\nEVERYTHING_MAX=$m\nEVERYTHING_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	EVERYTHING_AVERAGE=`printf '%.2f' $EVERYTHING_AVERAGE`
	EVERYTHING_STD=`printf '%.2f' $EVERYTHING_STD`
	
	sed -i "s/SSH Activity Today.*$/SSH Activity Today: $TODAY/" $1/index.html
	sed -i "s/SSH Activity This Month.*$/SSH Activity This Month: $THIS_MONTH/" $1/index.html
	sed -i "s/SSH Activity This Year.*$/SSH Activity This Year: $THIS_YEAR/" $1/index.html
	sed -i "s/SSH Activity Since Logging Started.*$/SSH Activity Since Logging Started: $TOTAL/" $1/index.html


	# Real Statistics here
	make_header "$1/statistics.html" "Assorted Statistics" "Analysis does not include today's numbers. Numbers rounded to two decimal places" "Time<BR>Frame" "Number<BR>of Days" "Total<BR>SSH attempts" "Average" "Std. Dev." "Median" "Max" "Min"
	echo "<TR><TD>So Far Today</TD><TD>1</TD><TD>$TODAY</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD></TR>" >>$1/statistics.html
	echo "<TR><TD>This Month</TD><TD> $MONTH_COUNT</TD><TD> $MONTH_SUM</TD><TD> $MONTH_AVERAGE</TD><TD> $MONTH_STD</TD><TD> $MONTH_MEDIAN</TD><TD> $MONTH_MAX</TD><TD> $MONTH_MIN" >>$1/statistics.html
	echo "<TR><TD>This Year</TD><TD> $YEAR_COUNT</TD><TD> $YEAR_SUM</TD><TD> $YEAR_AVERAGE</TD><TD> $YEAR_STD</TD><TD> $YEAR_MEDIAN</TD><TD> $YEAR_MAX</TD><TD> $YEAR_MIN" >>$1/statistics.html
	echo "<TR><TD>Since Logging Started</TD><TD> $EVERYTHING_COUNT</TD><TD> $EVERYTHING_SUM</TD><TD> $EVERYTHING_AVERAGE</TD><TD> $EVERYTHING_STD</TD><TD> $EVERYTHING_MEDIAN</TD><TD> $EVERYTHING_MAX</TD><TD> $EVERYTHING_MIN" >>$1/statistics.html
	make_footer "$1/statistics.html"

	sed -i "s/SSH Activity Today.*$/SSH Activity Today: $TODAY/" $1/index-long.html
	sed -i "s/SSH Activity This Month.*$/SSH Activity This Month: $THIS_MONTH/" $1/index-long.html
	sed -i "s/SSH Activity This Year.*$/SSH Activity This Year: $THIS_YEAR/" $1/index-long.html
	sed -i "s/SSH Activity Since Logging Started.*$/SSH Activity Since Logging Started: $TOTAL/" $1/index-long.html

	cd $ORIGINAL_DIRECTORY
}
	
############################################################################
# Current ssh attacks
#
# Called as ssh_attacks             $TMP_HTML_DIR $YEAR $PATH_TO_VAR_LOG DATE "messages*"
#
function ssh_attacks {
	TMP_HTML_DIR=$1
	is_directory_good $TMP_HTML_DIR
	YEAR=$2
	PATH_TO_VAR_LOG=$3
	DATE=$4
	MESSAGES=$5
	FILE_PREFIX=$6
	if [ $DEBUG  == 1 ] ; then echo "DEBUG $TMP_HTML_DIR, $YEAR, $PATH_TO_VAR_LOG, $DATE, $MESSAGES, $FILE_PREFIX" ; fi

	#
	# I do a cd tp $PATH_TO_VAR_LOG to reduce the commandline length.  If the 
	# commandline is too long and breaks on your system due to there being 
	# way too many files in the directory, then you should probably be using
	# some other tool.
	ORIGINAL_DIRECTORY=`pwd`
	cd $PATH_TO_VAR_LOG

	#
	# I hate making temporary files, but I have to so this doesn't take forever to run
	#
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Making temp file now" ; fi
	$SCRIPT_DIR/catall.sh $MESSAGES |grep ssh |grep "$DATE"|grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep | grep Password > /tmp/LongTail-messages.$$

	#-------------------------------------------------------------------------
	# Root
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 1" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-root-passwords" "Root Passwords" " " "Count" "Password"

	# WAS cat /tmp/LongTail-messages.$$ |grep Username\:\ root |awk '{print $NF}' |sort |uniq -c|sort -nr |\
	cat /tmp/LongTail-messages.$$ |grep Username\:\ root |\
	awk -F'Username: ' '/Username/{print $2}' | awk '{print $3} ' |\
	sort |uniq -c|sort -nr |\
	awk '{printf("<TR><TD>%d</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">%s</a> </TD></TR>\n",$1,$2,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-root-passwords

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords" "Top 20 Root Passwords" "" "Count" "Password"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-root-passwords | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-root-passwords"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.data



	#-------------------------------------------------------------------------
	# admin
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 2" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords" "Admin Passwords" " " "Count" "Password"
	cat /tmp/LongTail-messages.$$ |grep Username\:\ admin |\
	awk -F'Username: ' '/Username/{print $2}' | awk '{print $3} ' |\
	sort |uniq -c|sort -nr |\
	awk '{printf("<TR><TD>%d</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">%s</a> </TD></TR>\n",$1,$2,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords" "Top 20 Admin Passwords" " " "Count" "Password"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.data


	#-------------------------------------------------------------------------
	# Not root or admin PASSWORDS
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 3" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords" "Non Root Passwords" " " "Count" "Password"
	cat /tmp/LongTail-messages.$$ |egrep -v Username\:\ root\ \|Username\:\ admin\  |\
	awk -F'Username: ' '/Username/{print $2}' | awk '{print $3} '  |\
	sort |uniq -c|sort -nr |\
	awk '{printf("<TR><TD>%d</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">%s</a> </TD></TR>\n",$1,$2,$2)}'  >> $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords" "Top 20 Non Root Passwords" " " "Count" "Password"
	#tail -20 $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords | head -20  >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.data
	
	#-------------------------------------------------------------------------
	# Not root or admin ACCOUNTS
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 4" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts" "Accounts Tried" " " "Count" "Account"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts" "Top 20 Accounts Tried" "" "Count" "Account"
	cat /tmp/LongTail-messages.$$ |\
	awk -F'Username: ' '/Username/{print $2}' | awk '{print $1}'|\
	sort |uniq -c|sort -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts
# NEED tac HERE
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts
	#tail -20 $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD>/ /'|sed 's/<.TD><.TR>//' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.data
	
	#-------------------------------------------------------------------------
	# This works but gives only IP addresses
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 5" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses" "IP Addresses" " " "Count" "IP Address" "WhoIS" "Blacklisted"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses" "Top 20 IP Addresses" " " "Count" "IP Address" "WhoIS" "Blacklisted"
	# I need to make a temp file for this
	$SCRIPT_DIR/catall.sh $MESSAGES | grep Fail |grep "$DATE"|grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | sed 's/^.*from //'|sed 's/ port..*$//'|sort |uniq -c |sort -n |awk '{printf("<TR><TD>%d</TD><TD>%s</TD><TD><a href=\"http://whois.urih.com/record/%s\">Whois lookup</A></TD><TD><a href=\"http://www.dnsbl-check.info/?checkip=%s\">Blacklisted?</A></TR>\n",$1,$2,$2,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses"
	
	#-------------------------------------------------------------------------
	# This translates IPs to countries
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 6, doing whois.pl lookups" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country" "Attacks by Country" " " "Count" "Country"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country" "Top 20 Countries" " " "Count" "Country"
	# I need to make a temp file for this
	for IP in `$SCRIPT_DIR/catall.sh $MESSAGES |grep Fail |grep "$DATE"|grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | sed 's/^.*from //'|sed 's/ port..*$//'|sort |uniq |grep -v \:\:1`; do   $SCRIPT_DIR/whois.pl $IP |grep -i country|head -1|sed 's/:/: /g' ; done | awk '{print $NF}' |sort |uniq -c |sort -n | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country
	sed -i -f $SCRIPT_DIR/translate_country_codes.sed  $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country"
	
	#-------------------------------------------------------------------------
	# Figuring out most common non-root pairs
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 7 Figuring out most common non-root pairs" ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs" "Non Root Pairs" " " "Count" "Account:Password"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs" "Top 20 Non Root Pairs" " " "Count" "Account:Password"
	cat /tmp/LongTail-messages.$$ |egrep -v Username\:\ root\ \|Username\:\ admin\  |\
	awk -F'Username: ' '/Username/{print $2}' | sed 's/ Password: /:/'|\
	sort |uniq -c|sort -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}'>> $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs
	cat  $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs |grep -v HEADERLINE |head -20 >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs"

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day" "Historical Ssh Attacks By Time Of Day" "" "Count" "Hour of Day"
	grep ssh messages*| grep -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |grep Password | awk '{print $3}'|awk -F: '{print $1}' |sort |uniq -c| awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day"

	#-------------------------------------------------------------------------
	# raw data compressed 
	# This only prints the account and the password
	# This is different from the temp file I make earlier as it does
	# a grep for both Password AND password (Note the capitalization differences).
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-ssh_attack 8, gathering data for raw-data.gz" ; fi
	if [ $OBFUSCATE_IP_ADDRESSES -gt 0 ] ; then
		$SCRIPT_DIR/catall.sh $MESSAGES |grep ssh |grep "$DATE"|grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password\|password |sed -r 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)[0-9]{1,3}/\1127/g'  |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
	else
		$SCRIPT_DIR/catall.sh $MESSAGES |grep ssh |grep "$DATE"|grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password\|password |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
	fi
	if [ $DEBUG ] ; then echo "Wrote to $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz"; fi

	#
	# read and run any LOCALLY WRITTEN reports
	#
	if [ $DEBUG ] ; then echo "Running ssh-local-reports"; fi
	. $SCRIPT_DIR/Longtail-ssh-local-reports

	# cd back to the original directory.  this should be the last command in 
	# the function.
	cd $ORIGINAL_DIRECTORY
	rm /tmp/LongTail-messages.$$
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Done with ssh_attack " ; fi
}

#########################################################################################################
# HTTP STUFF HERE
# http_attacks $TMP_HTML_DIR $YEAR $PATH_TO_VAR_LOG_HTTPD "$DATE"  "access_log"  "current"
#
function http_attacks {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Starting http_attacks now" ; fi
	TMP_HTML_DIR=$1
	is_directory_good $TMP_HTML_DIR
	YEAR=$2
	PATH_TO_VAR_LOG_HTTPD=$3
	DATE=$4
	ACCESS_LOG=$5
	FILE_PREFIX=$6
	
	#	Date format should be like this --> DATE=`date +%d/%b/%Y`
	#
	# I do a cd tp $PATH_TO_VAR_LOG to reduce the commandline length.  If the 
	# commandline is too long and breaks on your system due to there being 
	# way too many files in the directory, then you should probably be using
	# some other tool.
	ORIGINAL_DIRECTORY=`pwd`
	cd $PATH_TO_VAR_LOG_HTTPD

	
	#####################################################################################################
	# Access logs here
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-access-log" "Webpages" ""  
	echo "</TABLE><!--HEADERLINE -->" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log
	echo "<PRE><!--HEADERLINE -->" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log
	$SCRIPT_DIR/catall.sh $ACCESS_LOG | grep -hvf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep|grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep |grep $DATE  >> $TMP_HTML_DIR/$FILE_PREFIX-access-log
	echo "</PRE><!--HEADERLINE -->" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-access-log"
	
	
	#####################################################################################################
	#echo "What webpages are they looking for?"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-shellshock-webpages" "Shellshock Requests"  "" "Count" "Webpage"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock-webpages" "Top 20 Shellshock Requests"  "" "Count" "Webpage"
	$SCRIPT_DIR/catall.sh $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \:\; |sed 's/^..*\"GET\ //'| sed 's/^..*\"HEAD\ //' |sed 's/ ..*$//'|sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-shellshock-webpages
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-shellshock-webpages |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock-webpages
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock-webpages"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-shellshock-webpages"

	
	#####################################################################################################
	#echo "What are the actual attacks they are trying to run?"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-attacks" "Attacks"   "" "Count" "Attack"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks" "Top 20 Attacks"   "" "Count" "Attack"
	$SCRIPT_DIR/catall.sh $ACCESS_LOG  |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \:\; |sed 's/^..*\"GET\ //'| sed 's/^..*\"HEAD\ //' | sed 's/^..*:;//' |sed 's/\}\;//'|sort |uniq -c|sort -n  | sed -r 's/^ +/<TR><TD>/'|sed 's/ /<\/TD><TD>/'|sed 's/$/<\/TD><\/TR>/' >> $TMP_HTML_DIR/$FILE_PREFIX-attacks
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-attacks  |grep -v HEADERLINE>> $TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-attacks"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks"
	
	#####################################################################################################
	#echo "Where are they getting their payloads from or trying to connect to with bash?"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-payloads" "Payloads"   "" "Count" "Attack"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-payloads" "Top 20 Payloads"   "" "Count" "Attack"
	$SCRIPT_DIR/catall.sh $ACCESS_LOG  |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \:\; |sed 's/^..*\"GET\ //'| sed 's/^..*\"HEAD\ //' | sed 's/^..*:;//' |sed 's/\}\;//' |sed 's/^..*http/http/'|sed 's/^..*ftp/ftp/' |sed 's/;..*//'| sed 's/^..*\/dev\/tcp/\/dev\/tcp/' |sed 's/0>.*//' |sed 's/>.*//' |sort |uniq -c |sort -n  |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-payloads
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-payloads  |grep -v HEADERLINE>> $TMP_HTML_DIR/$FILE_PREFIX-top-20-payloads
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-payloads"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-payloads"
	
	#####################################################################################################
	#echo "What are they trying to rm?"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-rm-attempts" "rm Attempts"   "" "Count" "Attack"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-rm-attempts" "Top 20 rm Attempts"   "" "Count" "Attack"
	grep -h \:\; $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep perl|sed 's/..*perl/perl/'|sed 's/^..*rm/rm/' |sort |uniq -c|sort -n |grep rm |sed 's/;.*//' |sort -n |sed 's/^/<TR><TD>/'|sed 's/$/<\/TD><\/TR>/'|sed 's/ rm/<\/TD><TD>rm/' >> $TMP_HTML_DIR/$FILE_PREFIX-rm-attempts
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-rm-attempts  |grep -v HEADERLINE>> $TMP_HTML_DIR/$FILE_PREFIX-top-20-rm-attempts
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-rm-attempts"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-rm-attempts"
	
	#####################################################################################################
	#echo "Shellshock attacks not explitly using perl"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-shellshock-not-using-perl" "shellshock-not-using-perl"   "" "Count" "Attack"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock-not-using-perl" "Top 20 shellshock-not-using-perl"   "" "Count" "Attack"
	grep -h \:\; $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep  -v perl |sed 's/^..*\"GET\ //'| sed 's/^..*\"HEAD\ //' | sed 's/^..*:;//' |sed 's/\}\;//' |sort |uniq -c |sort -n |sed 's/^ *//' |sed 's/^/<TR><TD>/' |sed 's/$/<\/TD><\/TR>/' |sed 's/ /<\/TD><TD>/'   >> $TMP_HTML_DIR/$FILE_PREFIX-shellshock-not-using-perl

	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-shellshock-not-using-perl  |grep -v HEADERLINE>> $TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock-not-using-perl
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-shellshock-not-using-perl"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock-not-using-perl"
	
	#####################################################################################################
	# Shellshock here
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-access-log-shell-shock" "access-log-shell-shock" ""  
	echo "</TABLE><PRE>" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log-shell-shock
	grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep |grep $DATE |grep \:\; >> $TMP_HTML_DIR/$FILE_PREFIX-access-log-shell-shock
	echo "</PRE>" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log-shell-shock
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-access-log-shell-shock"

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-shell-shock" "ip-access-log-shell-shock"   "" "Count" "Attack"
	grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -v $SCRIPT_DIR/LongTail-exclude-webpages.grep |grep $DATE |grep \:\; | awk '{print $1}' |sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}'>> $TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-shell-shock
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-shell-shock"

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-country-access-log-shell-shock" "country-access-log-shell-shock"   "" "Count" "Country"
	for IP in `grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \:\; | awk '{print $1}' |sort |uniq` ;do $SCRIPT_DIR/whois.pl $IP |grep -i country|head -1|sed 's/:/: /g' ; done | awk '{print $NF}' |sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-country-access-log-shell-shock
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-country-access-log-shell-shock"
	sed -i -f $SCRIPT_DIR/translate_country_codes.sed.orig  $TMP_HTML_DIR/$FILE_PREFIX-country-access-log-shell-shock
	
	#####################################################################################################
	# 404 probes here
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-access-log-404" "access-log-404"  ""  
	echo "</TABLE><PRE>" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log-404
	grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -v \:\; |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \ 404\  >> $TMP_HTML_DIR/$FILE_PREFIX-access-log-404
	echo "</PRE>" >> $TMP_HTML_DIR/$FILE_PREFIX-access-log-404
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-access-log-404"

#-------------------------------------------------------------------------
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-open-proxy-log-404" "open-proxy-log-404"  ""  
	echo "</TABLE><PRE>" >> $TMP_HTML_DIR/$FILE_PREFIX-open-proxy-log-404
	grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -v \:\; |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \ 404\ |grep 'GET http:' >> $TMP_HTML_DIR/$FILE_PREFIX-open-proxy-log-404
	echo "</PRE>" >> $TMP_HTML_DIR/$FILE_PREFIX-open-proxy-log-404
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-open-proxy-log-404"

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ip-open-proxy-404" "ip-open-proxy-404"   "" "Count" "IP Address"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-open-proxy-404" "Top 20 ip-open-proxy-404"   "" "Count" "IP Address"
	grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -v \:\; |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |grep $DATE |grep \ 404\ |grep 'GET http:' | awk '{print $1}' |sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ip-open-proxy-404
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-ip-open-proxy-404  |grep -v HEADERLINE>> $TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-open-proxy-404
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ip-open-proxy-404"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-open-proxy-404"

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-country-open-proxy-log-404" "country-open-proxy-log-404"   "" "Count" "Country"
	for IP in `grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep |grep -v \:\; |grep $DATE |grep \ 404\ |grep 'GET http:'  | awk '{print $1}' |sort |uniq` ;do $SCRIPT_DIR/whois.pl $IP |grep -i country|head -1|sed 's/:/: /g' ; done | awk '{print $NF}' |sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-country-open-proxy-log-404
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-country-open-proxy-log-404"
	sed -i -f $SCRIPT_DIR/translate_country_codes.sed.orig  $TMP_HTML_DIR/$FILE_PREFIX-country-open-proxy-log-404

#-------------------------------------------------------------------------

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-404" "ip-access-log-404"   "" "Count" "IP Address"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-access-log-404" "Top 20 ip-access-log-404"   "" "Count" "IP Address"

	grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -v \:\; |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep |grep $DATE |grep \ 404\  | awk '{print $1}' |sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-404
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-404  |grep -v HEADERLINE>> $TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-access-log-404
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ip-access-log-404"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-access-log-404"

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-country-access-log-404" "country-access-log-404"   "" "Count" "Country"
	for IP in `grep -vhf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep |grep -v \:\; |grep $DATE |grep \ 404\  | awk '{print $1}' |sort |uniq` ;do $SCRIPT_DIR/whois.pl $IP |grep -i country|head -1|sed 's/:/: /g' ; done | awk '{print $NF}' |sort |uniq -c |sort -n |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-country-access-log-404
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-country-access-log-404"
	sed -i -f $SCRIPT_DIR/translate_country_codes.sed.orig  $TMP_HTML_DIR/$FILE_PREFIX-country-access-log-404


	make_header "$TMP_HTML_DIR/$FILE_PREFIX-shellshock-by-time-of-day" "shellshock-by-time-of-day"   "" "Count" "Time"
	$SCRIPT_DIR/catall.sh $ACCESS_LOG |grep -vf $SCRIPT_DIR/LongTail-exclude-IPs-httpd.grep  |grep -v \/honey\/ | grep \:\; |awk -F: '{print $2}' |sort|uniq -c |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-shellshock-by-time-of-day
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-shellshock-by-time-of-day"

	#
	# read and run any LOCALLY WRITTEN reports
	#
	. $SCRIPT_DIR/Longtail-httpd-local-reports


	# cd back to the original directory.  this should be the last command in 
	# the function.
	cd $ORIGINAL_DIRECTORY

}


function do_ssh {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in do_ssh now" ; fi
	#-----------------------------------------------------------------
	# Lets count the ssh attacks
	count_ssh_attacks $HTML_DIR $PATH_TO_VAR_LOG "messages*"
	
	#----------------------------------------------------------------
	# Lets check the ssh logs
	ssh_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG "$DATE"  "messages" "current"
	ssh_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG "."      "messages*" "historical"
	
	#----------------------------------------------------------------
	# Lets check the ssh logs for the last 7 days
	LAST_WEEK=""
	for i in 1 2 3 4 5 6 7 ; do
		TMP_DATE=`date "+%Y-%m-%e" --date="$i day ago"`
		if [ "$LAST_WEEK" == "" ] ; then
			LAST_WEEK="$TMP_DATE"
		else
			LAST_WEEK="$LAST_WEEK\\|$TMP_DATE"
		fi
	done
	ssh_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG "$LAST_WEEK"      "messages*" "last-7-days"
	
	
	#----------------------------------------------------------------
	# Lets check the ssh logs for the last 30 days
	LAST_MONTH=""
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
		TMP_DATE=`date "+%Y-%m-%e" --date="$i day ago"`
		if [ "$LAST_MONTH" == "" ] ; then
			LAST_MONTH="$TMP_DATE"
		else
			LAST_MONTH="$LAST_MONTH\\|$TMP_DATE"
		fi
	done
	ssh_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG "$LAST_MONTH"      "messages*" "last-30-days"
	
	
	# This is an example of how to call ssh_attacks for past dates and 
	# put the reports in the $HTML_DIR/historical/Year/month/date directory
	# Please remember that single digit dates have two leading spaces
	# while double digit dates only have one leading space
	#
#	#for LOOP in 1 2 3 4 5 6 7 8 9 ; do
#	for LOOP in 4 5 6 7 8 9 ; do
#		mkdir -p $HTML_DIR/historical/2015/01/0$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/01/0$LOOP $YEAR $PATH_TO_VAR_LOG "Jan  $LOOP"      "messages*" "current"
#	done
#	##for LOOP in 24 ; do
#	for LOOP in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
#		mkdir -p $HTML_DIR/historical/2015/01/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/01/$LOOP $YEAR $PATH_TO_VAR_LOG "Jan $LOOP"      "messages*" "current"
#	done
#	for LOOP in 1 2 3 4 5 6 7 8 9 ; do
#		mkdir -p $HTML_DIR/historical/2015/02/0$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/02/0$LOOP $YEAR $PATH_TO_VAR_LOG "Feb  $LOOP"      "messages*" "current"
#	done
#	for LOOP in 10 11 12 13 14 15 16 17 18 19 ; do
#		mkdir -p $HTML_DIR/historical/2015/02/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/02/$LOOP $YEAR $PATH_TO_VAR_LOG "Feb $LOOP"      "messages*" "current"
#	done
#	#exit
	
	
	#-----------------------------------------------------------------
	# Now lets do some long term ssh reports....  Lets do a comparison of 
	# top 20 non-root-passwords and top 20 root passwords
	#-----------------------------------------------------------------
	cd $HTML_DIR/historical 
	make_header "$HTML_DIR/trends-in-non-root-passwords" "Trends in Non Root Passwords From Most Common to 20th"  "Format is Number of Tries :  Password tried." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
	
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-non-root-passwords" ; fi
	for FILE in `find . -name 'current-top-20-non-root-passwords'|sort -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
		echo -n "$FILE $FILE"  |\
		sed 's/current-top-20-non-root-passwords//g' |\
		sed 's/\.\///g' |\
		sed 's/^/<A HREF=\"historical\//' |\
		sed 's/\/ /\/\">/' |\
		sed 's/$/ <\/a>/' ; \
		echo -n "</TD>"; grep TR $FILE |\
		grep -v HEADERLINE | \
		sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done >> $HTML_DIR/trends-in-non-root-passwords
	
	make_footer "$HTML_DIR/trends-in-non-root-passwords"
	sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-non-root-passwords
	

	#-----------------------------------------------------------------
	cd $HTML_DIR/historical 
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-root-passwords" ; fi
	make_header "$HTML_DIR/trends-in-root-passwords" "Trends in Root Passwords From Most Common to 20th"  "Format is Number of Tries : Password Tried." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"

	for FILE in `find . -name 'current-top-20-root-passwords'|sort -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
		echo -n "$FILE $FILE" |\
		sed 's/current-top-20-root-passwords//g'|\
		sed 's/\.\///g' |\
		sed 's/^/<A HREF=\"historical\//' |\
		sed 's/\/ /\/\">/' |\
		sed 's/$/ <\/a>/' ; \
		echo -n "</TD>"; grep TR $FILE |\
		grep -v HEADERLINE   |\
		sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done >> $HTML_DIR/trends-in-root-passwords
	
	make_footer "$HTML_DIR/trends-in-root-passwords"
	sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-root-passwords
	cd $HTML_DIR/historical 
	
	#-----------------------------------------------------------------
	cd $HTML_DIR/historical 
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-admin-passwords" ; fi

	make_header "$HTML_DIR/trends-in-admin-passwords" "Trends in Admin Passwords From Most Common to 20th"  "Format is Number of Tries : Password Tried." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
	
	for FILE in `find . -name 'current-top-20-admin-passwords'|sort -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
		echo -n "$FILE $FILE" |\
		sed 's/current-top-20-admin-passwords//g'|\
		sed 's/\.\///g' |\
		sed 's/^/<A HREF=\"historical\//' |\
		sed 's/\/ /\/\">/' |\
		sed 's/$/ <\/a>/' ; \
		echo -n "</TD>"; grep TR $FILE |\
		grep -v HEADERLINE   |\
		sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done  >> $HTML_DIR/trends-in-admin-passwords
	
	make_footer "$HTML_DIR/trends-in-admin-passwords"
	sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-admin-passwords
	cd $HTML_DIR/historical 

	#-----------------------------------------------------------------
	cd $HTML_DIR/historical 
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-Accounts" ; fi

	make_header "$HTML_DIR/trends-in-accounts" "Trends in Accounts Tried From Most Common to 20th"  "Format is Number of Tries : Password Tried." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
	
	for FILE in `find . -name 'current-top-20-non-root-accounts'|sort -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
		echo -n "$FILE $FILE" |\
		sed 's/current-top-20-non-root-accounts//g'|\
		sed 's/\.\///g' |\
		sed 's/^/<A HREF=\"historical\//' |\
		sed 's/\/ /\/\">/' |\
		sed 's/$/ <\/a>/' ; \
		echo -n "</TD>"; grep TR $FILE |\
		grep -v HEADERLINE   |\
		sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done  >> $HTML_DIR/trends-in-accounts
	
	make_footer "$HTML_DIR/trends-in-accounts"
	sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-accounts
	cd $HTML_DIR/historical 

	#-----------------------------------------------------------------
	cd $HTML_DIR/
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Making Graphics now" ; fi
	if [ $GRAPHS == 1 ] ; then
		for FILE in *.data ; do 
			if [ ! "$FILE" == "current-attack-count.data" ] ; then
				GRAPHIC_FILE=`echo $FILE | sed 's/.data/.png/'`
				TITLE=`echo $FILE | sed 's/-/ /g' |sed 's/.data//'`
				if [ -s "$FILE" ] ; then
					if [[ $FILE == *"accounts"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Accounts" "Number of Tries"> $GRAPHIC_FILE
					fi
					if [[ $FILE == *"password"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Passwords" "Number of Tries"> $GRAPHIC_FILE
					fi
				else #We have an empty file, deal with it here
					echo "0 0" >/tmp/LongTail.data.$$
					if [[ $FILE == *"accounts"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php /tmp/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Accounts" "Number of Tries"> $GRAPHIC_FILE
					fi
					if [[ $FILE == *"password"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php /tmp/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Passwords" "Number of Tries"> $GRAPHIC_FILE
					fi
					rm /tmp/LongTail.data.$$
				fi
			fi
		done        
	fi    


}

function do_httpd {
	#-----------------------------------------------------------------
	# Lets check the httpd access_logs logs
	# Reset the date to an access_log format
	DATE=`date +%d/%b/%Y`
	#DATE=`date +%Y-%m-%e`
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in do_httpd now" ; fi
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-YEAR is $YEAR, PATH_TO_VAR_LOG_HTTPD is $PATH_TO_VAR_LOG_HTTPD " ; fi
	
	http_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG_HTTPD "$DATE"  "access_log"  "current"
	http_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG_HTTPD "."      "access_log*" "historical"
	
	LAST_WEEK=""
	for i in 1 2 3 4 5 6 7 ; do
	  TMP_DATE=`date +"%d/%b/%Y" --date="$i day ago"`
	  #TMP_DATE=`date +"%Y-%m-%e" --date="$i day ago"`
	  if [ "$LAST_WEEK" == "" ] ; then
	    LAST_WEEK="$TMP_DATE"
	  else
	    LAST_WEEK="$LAST_WEEK\\|$TMP_DATE"
	  fi
	done
	
	http_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG_HTTPD "$LAST_WEEK"      "access_log*" "last-7-days"
	
	
	LAST_MONTH=""
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
	  TMP_DATE=`date +"%d/%b/%Y" --date="$i day ago"`
	  #TMP_DATE=`date +"%Y-%m-%e" --date="$i day ago"`
	  if [ "$LAST_MONTH" == "" ] ; then
	    LAST_MONTH="$TMP_DATE"
	  else
	    LAST_MONTH="$LAST_MONTH\\|$TMP_DATE"
	  fi
	done
	
	http_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG_HTTPD "$LAST_MONTH"      "access_log*" "last-30-days"
}

############################################################################
# Set permissions so everybody can read the files
#
function set_permissions {
	TMP_HTML_DIR=$1
	chmod a+r $TMP_HTML_DIR/*
}

############################################################################
# Create historical copies of the data
#
function create_historical_copies {
	TMP_HTML_DIR=$1
	if [ $HOUR -eq 23 ]; then
		cd  $TMP_HTML_DIR
		mkdir -p $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME
		cp $TMP_HTML_DIR/index-historical.html $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/index.html
		for FILE in `ls |grep -v historical|egrep -v index.html\|index-long.html\last-30\|last-7` ; do
			if [ $DEBUG  == 1 ] ; then echo "DEBUG-Copying $FILE to historical" ; fi
			cp $FILE $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME
		done
		chmod a+rx $TMP_HTML_DIR/historical
		chmod a+rx $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME
		chmod a+rx $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME
		chmod a+rx $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME
		chmod a+r  $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/*
	fi
}


############################################################################
# Main 
#

init_variables
read_local_config_file

change_date_date_in_index $HTML_DIR $YEAR

DATE=`date +"%b %e"` # THIS IS TODAY
DATE=`date +"%Y-%m-%e"` # THIS IS TODAY

if [ $DO_SSH  == 1 ] ; then do_ssh ; fi
if [ $DO_HTTPD  == 1 ] ; then do_httpd ; fi

set_permissions  $HTML_DIR 
create_historical_copies  $HTML_DIR

# Calling a separate perl script to analyze the attack patterns
# This really should be the last thing run, as gosh knows what
# directory it may leave you in....
echo "Trying to run SCRIPT_DIR/LongTail_analyze_attacks.pl now"
$SCRIPT_DIR/LongTail_analyze_attacks.pl 2> /dev/null

exit
