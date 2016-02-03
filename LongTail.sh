#!/bin/sh 

############################################################################
#
# Design note: I am PERFECTLY willing to trade using more disk space in 
# order to speed things up.
#
# This is my crontab entry
# 05 * * * * /usr/local/etc/LongTail.sh >> /tmp/LongTail.sh.out 2>> /tmp/LongTail.sh.out
#
# You need to have /usr/local/etc/whois.pl installed also.  Sure, I could 
# have a faster mysql backend, but I don't NEED it.
#
# I am assuming your /var/log/messages file is really called messages, or 
# messages<something>.  .gz files are ok too.
#
# you can also call this program with a hostname (from the messages files)
# so that you can analyze different hosts separately, each in 
# /honey/<HOSTNAME>/ directories.
#
# Examples:
# gets all hosts and looks for all ssh activity
#	/usr/local/etc/LongTail.sh 
#
# gets all hosts and looks for all ssh activity
#	/usr/local/etc/LongTail.sh ssh
#
# gets all hosts and looks for all ssh only on port 22 activity
#	/usr/local/etc/LongTail.sh 22
#
# gets all hosts and looks for all ssh only on port 2222 activity
#	/usr/local/etc/LongTail.sh 2222
#
# gets all hosts and looks for telnet activity
#	/usr/local/etc/LongTail.sh telnet
#
# If you are looking for a specific host, you MUST include the protocol
# to search for
# gets all hosts and looks for all ssh activity
#	/usr/local/etc/LongTail.sh ssh HOSTNAME
#
# gets all hosts and looks for all ssh only on port 22 activity
#	/usr/local/etc/LongTail.sh 22 HOSTNAME
#
# gets all hosts and looks for all ssh only on port 2222 activity
#	/usr/local/etc/LongTail.sh 2222 HOSTNAME
#
# gets all hosts and looks for telnet activity
#	/usr/local/etc/LongTail.sh telnet HOSTNAME
#
#
# LongTail.sh is not fully tested yet :-)
#
############################################################################
# This reads /usr/local/etc/LongTail.config.  If your file isn't there,
# then this is the only place you need to edit.

function read_local_config_file {
	if [ -e "/usr/local/etc/LongTail.config" ] ; then
		. /usr/local/etc/LongTail.config
	fi
}

# This function is called as 
# NEW_STRING=$(convert_kippo_to_longtail "$STRING")
# STRING should look like
# 2015-05-10 18:05:31-0400 [SSHService ssh-userauth on HoneyPotTransport,16534,58.218.204.52] login attempt [root/skata1] failed
function convert_kippo_to_longtail {
  STRING=`echo $STRING |sed -e 's/ /T/' \
  -e 's/.SSHService ssh-userauth on HoneyPotTransport,.*,//' \
  -e 's/\]/ /' \
  -e 's/\] failed$//' \
  -e 's/\[//' \
  -e 's/ / LOCALHOST sshd-22[9999]: IP: /' \
  -e 's/login attempt/PassLog: Username:/' \
  -e 's/\// Password: /'`
  echo $STRING
}


function lock_down_files {
	if [ "x$HOSTNAME" == "x/" ] ;then
		if [ -d $HTML_DIR ] ; then 
		cd $HTML_DIR

		echo "Expect to see chmod warnings until you have run LongTail for at least 24 hours"
			find . -name last-7-days-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA  \
			-o -name last-7-days-non-root-pairs.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name last-30-days-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name last-30-days-non-root-pairs.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name historical-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name historical-non-root-pairs.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA |\
			xargs chmod go-r

			find . -name todays_password -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name current-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name current-non-root-passwords.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name current-account-password-pairs.data.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA \
			-o -name current-admin-passwords.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA |\
			xargs chmod go-r
		fi
	fi

}
############################################################################
#
# Make sure paths really exist
function check_config {
	if [ ! -d $PATH_TO_VAR_LOG ] ; then
		echo "$PATH_TO_VAR_LOG does not exist, exiting now"
		exit
	fi
	if [ ! -e $PATH_TO_VAR_LOG/$LOGFILE ] ; then
		echo "$PATH_TO_VAR_LOG/$LOGFILE does not exist, exiting now"
		exit
	fi
	if [ ! -d $PATH_TO_VAR_LOG_HTTPD ] ; then
		echo "$PATH_TO_VAR_LOG_HTTPD does not exist, exiting now"
		exit
	fi
	if [ ! -d $SCRIPT_DIR ] ; then
		echo "Can not find SCRIPT_DIR: $SCRIPT_DIR, exiting now"
		exit
	fi
	if [ ! -d $HTML_DIR ] ; then
		echo "Can not find HTML_DIR: $HTML_DIR, exiting now"
		exit
	fi

	rsyslog_format_check=`tail -1 $PATH_TO_VAR_LOG/$LOGFILE |awk '{print $1}'`
	rsyslog_format_check_exit=0
	if [ $rsyslog_format_check = "Jan" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Feb" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Mar" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Apr" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "May" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Jun" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Jul" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Aug" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Sep" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Oct" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Nov" ] ; then rsyslog_format_check_exit=1 ; fi
	if [ $rsyslog_format_check = "Dec" ] ; then rsyslog_format_check_exit=1 ; fi
	
	if [ $rsyslog_format_check_exit -eq 1 ] ; then
		echo "$PATH_TO_VAR_LOG/$LOGFILE file appears to have the wrong style data stamp (monthName vs YYYY-MM-DD format) Please see the README again."
		echo "rsyslog format line should be \"\$ActionFileDefaultTemplate RSYSLOG_FileFormat\""
		echo "You will have to edit $PATH_TO_VAR_LOG/$LOGFILE by hand to fix the formating or start with a fresh $PATH_TO_VAR_LOG/$LOGFILE file"
		exit
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

	# Which honeypot are you running?  Uncomment only ONE of the following
	#KIPPO=1 ; LONGTAIL=0 # This is for the Kippo honeypot
	KIPPO=0 ; LONGTAIL=1 # This is for the LongTail honeypot
	
	#Where is the messages file?  Uncomment only ONE of the following
	PATH_TO_VAR_LOG="/var/log/" # Typically for messages file from ryslog
	#PATH_TO_VAR_LOG="/usr/local/kippo-master/log/" # One place for kippo
	#PATH_TO_VAR_LOG="/var/log/kippo/" # another place for kippo


	# What is the name of the default log file
	LOGFILE="messages"
	#LOGFILE="kippo.log"
	
	
	#Where is the apache access_log file?
	PATH_TO_VAR_LOG_HTTPD="/var/log/httpd/"

	# Do you want debug output?  Set this to 1
	DEBUG=0
	
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

	# Where do we put the temporary files
	TMP_DIRECTORY="/data/tmp"
	
	# Where are the scripts we need to run?
	SCRIPT_DIR="/usr/local/etc/"
	
	# Where do we put the reports?
	HTML_DIR="/var/www/html"
	# What's the top level directory?
	SSH_HTML_TOP_DIR="honey" #NO slashes please, it breaks sed
	SSH22_HTML_TOP_DIR="honey-22" #NO slashes please, it breaks sed
	SSH2222_HTML_TOP_DIR="honey-2222" #NO slashes please, it breaks sed
	TELNET_HTML_TOP_DIR="telnet" #NO slashes please, it breaks sed
	RLOGIN_HTML_TOP_DIR="rlogin" #NO slashes please, it breaks sed
	FTP_HTML_TOP_DIR="ftp" #NO slashes please, it breaks sed
	HTTP_HTML_TOP_DIR="http" #NO slashes please, it breaks sed
	
	# This is for my personal debugging, just leave them
	# commented out if you aren't me.
	#PATH_TO_VAR_LOG="/home/wedaa/source/LongTail/var/log/"
	#PATH_TO_VAR_LOG_HTTPD="/home/wedaa/source/LongTail/var/log/httpd/"

 	# Is this a consolidation server?  (A server that
 	# processes many servers results AND makes individual
 	# reports for each server).
 	CONSOLIDATION=0
	
	# What hosts are protected by a firewall or Intrusion Detection System?
	# This is used to set the current-attack-count.data.notfullday flag 
	# in those directories to help "normalize" the data
	if [ `hostname` == "longtail.it.marist.edu" ] ; then
		HOSTS_PROTECTED="erhp erhp2"
		BLACKRIDGE="blackridge"
		RESIDENTIAL_SITES="shepherd"
		EDUCATIONAL_SITES="syrtest edub edu_c"
		CLOUD_SITES="AWS cloud_v cloud_c"
		BUSINESS_SITES=""
	else
		HOSTS_PROTECTED=""
		BLACKRIDGE=""
		RESIDENTIAL_SITES=""
		EDUCATIONAL_SITES=""
		CLOUD_SITES=""
		BUSINESS_SITES=""
	fi
 
	
	# Do we protect the raw data, and for how long?
	# PROTECT_RAW_DATA=1 will protect raw data
	# PROTECT_RAW_DATA=0 will NOT protect raw data
	PROTECT_RAW_DATA=1
	NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA=90;

	
	############################################################################
	# You don't need to edit after this.
	#
	TODAY_AT_START_OF_RUNTIME=`date`
	YEAR=`date +%Y`
	HOUR=`date +%H` # This is used at the end of the program but we want to know it NOW
	START_HOUR=`date +%H` # This is used at the end of the program but we want to know it NOW
	YEAR_AT_START_OF_RUNTIME=`date +%Y`
	MONTH_AT_START_OF_RUNTIME=`date +%m`
	DAY_AT_START_OF_RUNTIME=`date +%d`
	REBUILD=0
	MIDNIGHT=0
	ONE_AM=1
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
        	echo "I can't write to $1", exiting now
		exit
	fi
}

############################################################################
# Lets make sure we can write to the directory
#
function is_file_good {
	if [ ! -e $1  ] ; then
		echo "DANGER DANGER DANGER"
        	echo "$1 does not exist, exiting now "
		exit
	fi
	if [ ! -w $1  ] ; then
		echo "DANGER DANGER DANGER"
        	echo "I can't write to $1", exiting now
		exit
	fi
}


############################################################################
# Change the date in index.shtml
#
function change_date_in_index {
	local DATE=`date`

	is_file_good $1/index.shtml
	is_file_good $1/index-long.shtml
	is_file_good $1/graphics.shtml
	sed -i "s/updated on..*$/updated on $DATE/" $1/index.shtml
	sed -i "s/updated on..*$/updated on $DATE/" $1/index-map.shtml
	sed -i "s/updated on..*$/updated on $DATE/" $1/index-long.shtml
	sed -i "s/updated on..*$/updated on $DATE/" $1/index-long-map.shtml
	sed -i "s/updated on..*$/updated on $DATE/" $1/graphics.shtml
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
		echo "Can not write to $MAKE_HEADER_FILENAME, exiting now"
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
	echo "<!--#include virtual="/$HTML_TOP_DIR/header.html" --> <!--HEADERLINE --> " >> $MAKE_HEADER_FILENAME
	echo "<H1>LongTail Log Analysis</H1><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<H3>$TITLE</H3><!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<P>$DESCRIPTION <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
#	echo "<P><font color="red">SPACECHAR</font> Indicates a space in the incoming data <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	echo "<P>Created on $MAKE_HEADER_DATE<!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	
	if [ $OBFUSCATE_IP_ADDRESSES -gt 0 ] ; then
		echo "<P>IP Addresses have been obfuscated to hide the guilty. <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
		echo "ALL IP addresses have been reset to end in .127. <!--HEADERLINE -->" >> $MAKE_HEADER_FILENAME
	fi

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
		echo "Can not write to $MAKE_FOOTER_FILENAME, exiting now"
		exit
	fi
	echo "" >> $MAKE_FOOTER_FILENAME
	echo "</TABLE><!--HEADERLINE -->" >> $MAKE_FOOTER_FILENAME
	echo "<!--#include virtual="/$HTML_TOP_DIR/footer.html" --> <!--HEADERLINE --> " >> $MAKE_FOOTER_FILENAME
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
# This way the report does not name any single user, but blames the
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
function count_http_attacks {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_http_attacks now" ; fi
	TMP_HTML_DIR=$1
	PATH_TO_VAR_LOG=$2
	MESSAGES=$3

	ORIGINAL_DIRECTORY=`pwd`

	TMP_DATE=`date +"%Y-%m-%d"`
	TMP_YEAR=`date +%Y`
	TMP_MONTH=`date +%m`
	TMP_DAY=`date +%d`
	#
	# Lets make sure we have one for today and this month and this year
	TMP_DIR="$TMP_HTML"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	for dir in $HOSTS_PROTECTED $BLACKRIDGE ; do
		if [ "x$HOSTNAME" == "x$dir" ] ; then
			touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
			echo $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
		fi
	done
	#
	# Why did I add this line?
	# This makes sure the current day exists and is set to no data ?
        # But why am I creating this file later?
        # So I commented out the if statement so I ALWAYS clear the current data.
	#if [ ! -e $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz ] ; then
		echo "" |gzip -c > $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
		chmod a+r $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
	#fi


	####################################################################################
	#
	# 404 Webpages requested
	#
	# TODAY
	#
	FILE_TO_SEARCH_FOR="todays_uniq_404_webpages.count"
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_404 requests/TODAY now" ; date; fi
	cd $PATH_TO_VAR_LOG
	if [ "x$HOSTNAME" == "x/" ] ;then
		echo "$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $TMP_DATE " 
		TODAY_404=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep ' 404 '|grep -iv xymon |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep |uniq | wc -l`
		#$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep ' 404 '|grep -iv xymon |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep |uniq 
	else
echo "foo-3"
		TODAY_404=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL  |grep ' 404 ' |grep -iv xymon|awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |uniq |wc -l`
	fi
	echo $TODAY_404 > $TMP_HTML_DIR/$FILE_TO_SEARCH_FOR 
echo "TODAY'S 404 uniq count is is $TODAY_404"
	#
	# THIS MONTH
	#
	cd $TMP_HTML_DIR/historical/
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_404 requests/This Month now" ;date;  fi
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
echo "DEBUG file $FILE found"
ls -l $FILE
		(( TMP += $COUNT ))
	done
	THIS_MONTH_404=`expr $TMP + $TODAY_404`
echo ""
echo ""
echo "this month is $TMP , today is $TODAY_404 "
echo ""
echo ""
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# This fails on the first of the month
	#

	#
	# LAST MONTH
	#
	cd $TMP_HTML_DIR/historical/
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in 404 requests/Last Month now" ; date ; fi
#
# Gotta fix this for the year boundary
#
	TMP_LAST_MONTH=`date "+%m" --date="last month"`
	TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`
	TMP=0
	for FILE in  `find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	LAST_MONTH_404=$TMP
	# OK, this may not be 100% secure, but it's close enough for now
	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_404 requests/This Year now" ; date; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR_404=`expr $TMP + $TODAY_404`

	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
	TMP=0
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_404 requests/everything" ;  date;fi
	for FILE in  `find . -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL_404=`expr $TMP + $TODAY_404`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL  statistics" ; date;  fi
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)

	sed -i "s/Unique 404 Requests Today:.*$/Unique 404 Requests Today:--> $TODAY_404/" $1/index.shtml
	sed -i "s/Unique 404 Requests Today:.*$/Unique 404 Requests Today:--> $TODAY_404/" $1/index-long.shtml

	sed -i "s/Unique 404 Requests This Month:.*$/Unique 404 Requests This Month:--> $THIS_MONTH_404/" $1/index.shtml
	sed -i "s/Unique 404 Requests This Month:.*$/Unique 404 Requests This Month:--> $THIS_MONTH_404/" $1/index-long.shtml

	sed -i "s/Unique 404 Requests This Year:.*$/Unique 404 Requests This Year:--> $THIS_YEAR_404/" $1/index.shtml
	sed -i "s/Unique 404 Requests This Year:.*$/Unique 404 Requests This Year:--> $THIS_YEAR_404/" $1/index-long.shtml

	sed -i "s/Unique 404 Requests Since Logging Started:.*$/Unique 404 Requests Since Logging Started:--> $TOTAL_404/" $1/index.shtml
	sed -i "s/Unique 404 Requests Since Logging Started:.*$/Unique 404 Requests Since Logging Started:--> $TOTAL_404/" $1/index-long.shtml


	####################################################################################
	#
	# shellshock Webpages requested
	#
	# TODAY
	#
	FILE_TO_SEARCH_FOR="todays_uniq_shellshock_webpages.count"
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_shellshock requests/TODAY now" ; date; fi
	cd $PATH_TO_VAR_LOG
	if [ "x$HOSTNAME" == "x/" ] ;then
		echo "$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $TMP_DATE " 
		TODAY_shellshock=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep '\:\;'|grep -iv xymon |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep |uniq | wc -l`
		#$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep '\:\;'|grep -iv xymon |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep |uniq 
	else
echo "foo-3"
		TODAY_shellshock=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL  |grep '\:\;' |grep -iv xymon|awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |uniq |wc -l`
	fi
	echo $TODAY_shellshock > $TMP_HTML_DIR/$FILE_TO_SEARCH_FOR 
echo "TODAY'S shellshock uniq count is is $TODAY_shellshock"
	#
	# THIS MONTH
	#
	cd $TMP_HTML_DIR/historical/
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_shellshock requests/This Month now" ;date;  fi
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
echo "DEBUG file $FILE found"
ls -l $FILE
		(( TMP += $COUNT ))
	done
	THIS_MONTH_shellshock=`expr $TMP + $TODAY_shellshock`
echo ""
echo ""
echo "this month is $TMP , today is $TODAY_shellshock "
echo ""
echo ""
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# This fails on the first of the month
	#

	#
	# LAST MONTH
	#
	cd $TMP_HTML_DIR/historical/
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in shellshock requests/Last Month now" ; date ; fi
#
# Gotta fix this for the year boundary
#
	TMP_LAST_MONTH=`date "+%m" --date="last month"`
	TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`
	TMP=0
	for FILE in  `find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	LAST_MONTH_shellshock=$TMP
	# OK, this may not be 100% secure, but it's close enough for now
	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_shellshock requests/This Year now" ; date; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR_shellshock=`expr $TMP + $TODAY_shellshock`

	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
	TMP=0
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_shellshock requests/everything" ;  date;fi
	for FILE in  `find . -name $FILE_TO_SEARCH_FOR` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL_shellshock=`expr $TMP + $TODAY_shellshock`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL  statistics" ; date;  fi
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)

	sed -i "s/Unique ShellShock Today:.*$/Unique ShellShock Today:--> $TODAY_shellshock/" $1/index.shtml
	sed -i "s/Unique ShellShock Today:.*$/Unique ShellShock Today:--> $TODAY_shellshock/" $1/index-long.shtml

	sed -i "s/Unique ShellShock This Month:.*$/Unique ShellShock This Month:--> $THIS_MONTH_shellshock/" $1/index.shtml
	sed -i "s/Unique ShellShock This Month:.*$/Unique ShellShock This Month:--> $THIS_MONTH_shellshock/" $1/index-long.shtml

	sed -i "s/Unique ShellShock This Year:.*$/Unique ShellShock This Year:--> $THIS_YEAR_shellshock/" $1/index.shtml
	sed -i "s/Unique ShellShock This Year:.*$/Unique ShellShock This Year:--> $THIS_YEAR_shellshock/" $1/index-long.shtml

	sed -i "s/Unique ShellShock Since Logging Started:.*$/Unique ShellShock Since Logging Started:--> $TOTAL_shellshock/" $1/index.shtml
	sed -i "s/Unique ShellShock Since Logging Started:.*$/Unique ShellShock Since Logging Started:--> $TOTAL_shellshock/" $1/index-long.shtml


	####################################################################################
	#
	# Webpages requested
	#
	# TODAY
	#
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_http_attacks/TODAY now" ; date; fi
	cd $PATH_TO_VAR_LOG
	if [ "x$HOSTNAME" == "x/" ] ;then
		echo "$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $TMP_DATE " 
		TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep -iv xymon |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | wc -l`
	else
		TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL  |grep -iv xymon|awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |wc -l`
	fi
	echo $TODAY > $TMP_HTML_DIR/current-attack-count.data

	#
	# THIS MONTH
	#
	cd $TMP_HTML_DIR/historical/
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_http_attacks/This Month now" ;date;  fi
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_MONTH=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG this month statistics" ;date; fi
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# This fails on the first of the month
	#
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ -e $TMP_YEAR/$TMP_MONTH ] ; then 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_http_attacks/This Month/Statistics now" ; fi
echo ""
echo "=============================================================================="
echo ""
echo "DEBUG MONTH webpages"
echo "$TMP_YEAR/$TMP_MONTH/*/current-attack-count.data"
ls -l $TMP_YEAR/$TMP_MONTH/*/current-attack-count.data
		cat $TMP_YEAR/$TMP_MONTH/*/current-attack-count.data|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}; $n; print "MONTH_COUNT=$n\nMONTH_SUM=$s\nMONTH_AVERAGE=$a\nMONTH_STD=$std\nMONTH_MEDIAN=$med\nMONTH_MAX=$m\nMONTH_MIN=$mm";'  > $TMPFILE
		# Now we "source" the script to set environment varaibles we use later
		. $TMPFILE
		# Now we "clean up" the average and STD deviation
		MONTH_AVERAGE=`printf '%.2f' $MONTH_AVERAGE`
		MONTH_STD=`printf '%.2f' $MONTH_STD`
	else
		MONTH_COUNT=1
		MONTH_SUM=$TODAY
		MONTH_AVERAGE=$TODAY
		MONTH_STD=0
		MONTH_MEDIAN=$TODAY
		MONTH_MAX=$TODAY
		MONTH_MIN=$TODAY
		#MONTH_AVERAGE=`printf '%.2f' 0`
		MONTH_STD=`printf '%.2f' 0`
	fi
	rm $TMPFILE

	MONTH_COUNT=`echo $MONTH_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_SUM=`echo $MONTH_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_AVERAGE=`echo $MONTH_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_STD=`echo $MONTH_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MEDIAN=`echo $MONTH_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MAX=`echo $MONTH_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MIN=`echo $MONTH_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

echo "MONTH_SUM is $MONTH_SUM"
#exit

	#
	# LAST MONTH
	#
	cd $TMP_HTML_DIR/historical/
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_http_attacks/Last Month now" ; date ; fi
#
# Gotta fix this for the year boundary
#
	TMP_LAST_MONTH=`date "+%m" --date="last month"`
	TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`
	TMP=0
	for FILE in  `find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	LAST_MONTH=$TMP
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG Last month statistics" ;date ;  fi
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	#
	# Gotta do the date calculation to figure out "When" is last month
	#
	if [ -d $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/ ] ; then 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_http_attacks/Last Month/statistics now" ; fi
		cat $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/*/current-attack-count.data|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "LAST_MONTH_COUNT=$n\nLAST_MONTH_SUM=$s\nLAST_MONTH_AVERAGE=$a\nLAST_MONTH_STD=$std\nLAST_MONTH_MEDIAN=$med\nLAST_MONTH_MAX=$m\nLAST_MONTH_MIN=$mm";'  > $TMPFILE
		# Now we "source" the script to set environment varaibles we use later
		. $TMPFILE
		# Now we "clean up" the average and STD deviation
		LAST_MONTH_AVERAGE=`printf '%.2f' $LAST_MONTH_AVERAGE`
		LAST_MONTH_STD=`printf '%.2f' $LAST_MONTH_STD`
	else
		LAST_MONTH_COUNT="N/A"
		LAST_MONTH_SUM="N/A"
		LAST_MONTH_AVERAGE="N/A"
		LAST_MONTH_STD="N/A"
		LAST_MONTH_MEDIAN="N/A"
		LAST_MONTH_MAX="N/A"
		LAST_MONTH_MIN="N/A"
		LAST_MONTH_STD="N/A"
	fi
	rm $TMPFILE

	LAST_MONTH_COUNT=`echo $LAST_MONTH_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_SUM=`echo $LAST_MONTH_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_AVERAGE=`echo $LAST_MONTH_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_STD=`echo $LAST_MONTH_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MEDIAN=`echo $LAST_MONTH_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MAX=`echo $LAST_MONTH_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MIN=`echo $LAST_MONTH_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

echo "DEBUG - EEE"
	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_http_attacks/This Year now" ; date; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR=`expr $TMP + $TODAY`
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG this year statistics" ; date; fi
	# OK, this may not be 100% secure, but it's close enough for now
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_http_attacks/This Year now/statistics" ; fi
	for FILE in  `find $TMP_YEAR/ -name current-attack-count.data` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "YEAR_COUNT=$n\nYEAR_SUM=$s\nYEAR_AVERAGE=$a\nYEAR_STD=$std\nYEAR_MEDIAN=$med\nYEAR_MAX=$m\nYEAR_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	YEAR_AVERAGE=`printf '%.2f' $YEAR_AVERAGE`
	YEAR_STD=`printf '%.2f' $YEAR_STD`


	YEAR_COUNT=`echo $YEAR_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_SUM=`echo $YEAR_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_AVERAGE=`echo $YEAR_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_STD=`echo $YEAR_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MEDIAN=`echo $YEAR_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MAX=`echo $YEAR_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MIN=`echo $YEAR_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
	TMP=0
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_http_attacks/everything" ;  date;fi
	for FILE in  `find . -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL  statistics" ; date;  fi
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_http_attacks/everything/statistics" ; fi
	for FILE in  `find . -name current-attack-count.data` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "EVERYTHING_COUNT=$n\nEVERYTHING_SUM=$s\nEVERYTHING_AVERAGE=$a\nEVERYTHING_STD=$std\nEVERYTHING_MEDIAN=$med\nEVERYTHING_MAX=$m\nEVERYTHING_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	EVERYTHING_AVERAGE=`printf '%.2f' $EVERYTHING_AVERAGE`
	EVERYTHING_STD=`printf '%.2f' $EVERYTHING_STD`

	EVERYTHING_COUNT=`echo $EVERYTHING_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_SUM=`echo $EVERYTHING_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_AVERAGE=`echo $EVERYTHING_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_STD=`echo $EVERYTHING_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MEDIAN=`echo $EVERYTHING_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MAX=`echo $EVERYTHING_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MIN=`echo $EVERYTHING_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	#
	# Normalized data
	#
	if [ "x$HOSTNAME" == "x/" ] ;then
		# I have no idea where this breaks, but it's a big-ass number of files
		cd $HTML_DIR
		# OK, this may not be 100% secure, but it's close enough for now
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL Normalized statistics" ; date ; fi
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in  `find */historical -name current-attack-count.data ` ; do if [ ! -e $FILE.notfullday ] ; then cat $FILE ; fi ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
		. $TMPFILE
		rm $TMPFILE
		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
	else
		# I have no idea where this breaks, but it's a big-ass number of files
		cd $HTML_DIR
		# OK, this may not be 100% secure, but it's close enough for now
		if [ $DEBUG  == 1 ] ; then echo "DEBUG Hostname only ALL  statistics" ; fi
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in  `find ./historical -name current-attack-count.data ` ; do if [ ! -e $FILE.notfullday ] ; then cat $FILE ; fi ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
		. $TMPFILE
		rm $TMPFILE
		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
	fi

	NORMALIZED_COUNT=`echo $NORMALIZED_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_SUM=`echo $NORMALIZED_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_AVERAGE=`echo $NORMALIZED_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_STD=`echo $NORMALIZED_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MEDIAN=`echo $NORMALIZED_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MAX=`echo $NORMALIZED_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MIN=`echo $NORMALIZED_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	sed -i "s/Hack Attempts Today:.*$/Hack Attempts Today:--> $TODAY/" $1/index.shtml
	sed -i "s/Hack Attempts Today:.*$/Hack Attempts Today:--> $TODAY/" $1/index-long.shtml

	sed -i "s/Hack Attempts This Month:.*$/Hack Attempts This Month:--> $THIS_MONTH/" $1/index.shtml
	sed -i "s/Hack Attempts This Month:.*$/Hack Attempts This Month:--> $THIS_MONTH/" $1/index-long.shtml

	sed -i "s/Hack Attempts This Year:.*$/Hack Attempts This Year:--> $THIS_YEAR/" $1/index.shtml
	sed -i "s/Hack Attempts This Year:.*$/Hack Attempts This Year:--> $THIS_YEAR/" $1/index-long.shtml

	sed -i "s/Hack Attempts Since Logging Started:.*$/Hack Attempts Since Logging Started:--> $TOTAL/" $1/index.shtml
	sed -i "s/Hack Attempts Since Logging Started:.*$/Hack Attempts Since Logging Started:--> $TOTAL/" $1/index-long.shtml

	#
	# This really needs to be sped up somehow
	#
	# Couting honeypots here
	if [ $START_HOUR -eq $MIDNIGHT ]; then
	if [ "x$HOSTNAME" == "x/" ] ;then
	if [ $SEARCH_FOR == "http" ] ; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all http honeypots now"; date ; fi

		honey_file="todays-honeypots.txt"
		TMP=0
		touch /$TMP_DIRECTORY/honeypots.$$
		rm /$TMP_DIRECTORY/honeypots.$$
		for FILE in  `find historical/$TMP_YEAR/$TMP_MONTH -name $honey_file` ; do
			awk '{print $2}' $FILE |grep -v ^$  >> /$TMP_DIRECTORY/honeypots.$$
		done
		THISMONTHUNIQUEHONEYPOTS=`sort -u /$TMP_DIRECTORY/honeypots.$$|grep -v ^$ | wc -l `
		rm /$TMP_DIRECTORY/honeypots.$$

		TMP=0
		touch /$TMP_DIRECTORY/honeypots.$$
		rm /$TMP_DIRECTORY/honeypots.$$
		for FILE in  `find historical/$TMP_YEAR/ -name $honey_file` ; do
			awk '{print $2}' $FILE |grep -v ^$  >> /$TMP_DIRECTORY/honeypots.$$
		done
		THISYEARUNIQUEHONEYPOTS=`sort -u /$TMP_DIRECTORY/honeypots.$$|grep -v ^$ | wc -l `
		rm /$TMP_DIRECTORY/honeypots.$$
		TMP=0

		touch /$TMP_DIRECTORY/honeypots.$$
		rm /$TMP_DIRECTORY/honeypots.$$
		for FILE in  `find historical/  -name $honey_file` ; do
			awk '{print $2}' $FILE |grep -v ^$  >> /$TMP_DIRECTORY/honeypots.$$
		done
		ALLUNIQUEHONEYPOTS=`sort -u /$TMP_DIRECTORY/honeypots.$$|grep -v ^$ | wc -l `
		rm /$TMP_DIRECTORY/honeypots.$$

		THISMONTHUNIQUEHONEYPOTS=`echo $THISMONTHUNIQUEHONEYPOTS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THISYEARUNIQUEHONEYPOTS=`echo $THISYEARUNIQUEHONEYPOTS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		ALLUNIQUEHONEYPOTS=`echo $ALLUNIQUEHONEYPOTS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		sed -i "s/Number of Honeypots This Month.*$/Number of Honeypots This Month:--> $THISMONTHUNIQUEHONEYPOTS/" $1/index.shtml
		sed -i "s/Number of Honeypots This Year.*$/Number of Honeypots This Year:--> $THISYEARUNIQUEHONEYPOTS/" $1/index.shtml
		sed -i "s/Number of Honeypots Since Logging Started.*$/Number of Honeypots Since Logging Started:--> $ALLUNIQUEHONEYPOTS/" $1/index.shtml
		sed -i "s/Number of Honeypots This Month.*$/Number of Honeypots This Month:--> $THISMONTHUNIQUEHONEYPOTS/" $1/index-long.shtml
		sed -i "s/Number of Honeypots This Year.*$/Number of Honeypots This Year:--> $THISYEARUNIQUEHONEYPOTS/" $1/index-long.shtml
		sed -i "s/Number of Honeypots Since Logging Started.*$/Number of Honeypots Since Logging Started:--> $ALLUNIQUEHONEYPOTS/" $1/index-long.shtml

	fi
	fi
	fi

	#
	# This really needs to be sped up somehow
	#
#2015-03-29T03:07:36-04:00 shepherd sshd-22[2766]: IP: 103.41.124.140 PassLog: Username: root Password: tommy007
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all Honeypots now"; date ; fi

			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |awk '{print $2}' |grep -v longtail| sort -T $TMP_DIRECTORY |uniq -c > todays-honeypots.txt
			cat $1/todays-honeypots.txt |wc -l  > todays-honeypots.txt.count
	fi
echo ""
echo ""
echo "http Getting all-ips now"
echo ""
echo ""
	if [ ! -e all-ips ] ; then
		touch all-ips
	fi
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all IPs now"; date ; fi
		cat historical/*/*/*/todays_ips |sort -T $TMP_DIRECTORY -u > all-ips
		THISYEARUNIQUEIPSS=`cat historical/$TMP_YEAR/*/*/todays_ips |sort -T $TMP_DIRECTORY -u |wc -l `
		THISMONTHUNIQUEIPSS=`cat historical/$TMP_YEAR/$TMP_MONTH/*/todays_ips |sort -T $TMP_DIRECTORY -u |wc -l `
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Done Getting all ips now"; date ; fi

		ALLUNIQUEIPSS=`cat all-ips |wc -l`
echo "ALLUNIQUEIPSS=$ALLUNIQUEIPSS"
#exit

		THISMONTHUNIQUEIPSS=`echo $THISMONTHUNIQUEIPSS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THISYEARUNIQUEIPSS=`echo $THISYEARUNIQUEIPSS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		ALLUNIQUEIPSS=`echo $ALLUNIQUEIPSS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

		sed -i "s/Unique IPs This Month.*$/Unique IPs This Month:--> $THISMONTHUNIQUEIPSS/" $1/index.shtml
		sed -i "s/Unique IPs This Year.*$/Unique IPs This Year:--> $THISYEARUNIQUEIPSS/" $1/index.shtml
		sed -i "s/Unique IPs Since Logging Started.*$/Unique IPs Since Logging Started:--> $ALLUNIQUEIPSS/" $1/index.shtml

		sed -i "s/Unique IPs This Month.*$/Unique IPs This Month:--> $THISMONTHUNIQUEIPSS/" $1/index-long.shtml
		sed -i "s/Unique IPs This Year.*$/Unique IPs This Year:--> $THISYEARUNIQUEIPSS/" $1/index-long.shtml
		sed -i "s/Unique IPs Since Logging Started.*$/Unique IPs Since Logging Started:--> $ALLUNIQUEIPSS/" $1/index-long.shtml
	fi
	if [ "x$HOSTNAME" == "x/" ] ;then
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |awk '{print $4}'|sort -T $TMP_DIRECTORY -u > todays_ips
	else
		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |awk '{print $4}' |sort -T $TMP_DIRECTORY -u > todays_ips
	fi
	TODAYSUNIQUEIPS=`cat todays_ips |wc -l`
	echo $TODAYSUNIQUEIPS  >todays_ips.count
	awk 'FNR==NR{a[$0]++;next}(!($0 in a))' all-ips todays_ips >todays-uniq-ips.txt
	IPSNEWTODAY=`cat todays-uniq-ips.txt |wc -l`

	make_header "$1/todays-uniq-ips.shtml" "IP Addresses Never Seen Before Today" " " "Count" "IP Address" "Country" "WhoIS" "Blacklisted" "Attack Patterns"

	for IP in `cat todays-uniq-ips.txt` ; do grep .TD.$IP..TD. current-ip-addresses.shtml >> $1/todays-uniq-ips.shtml; done

	make_footer "$1/todays-uniq-ips.shtml"
	sed -i s/HONEY/$HTML_TOP_DIR/g $1/todays-uniq-ips.shtml

	
	TODAY=`echo $TODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_MONTH=`echo $THIS_MONTH|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_YEAR=`echo $THIS_YEAR|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TOTAL=`echo $TOTAL|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	TODAYSUNIQUEPASSWORDS=`echo $TODAYSUNIQUEPASSWORDS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	PASSWORDSNEWTODAY=`echo $PASSWORDSNEWTODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TODAYSUNIQUEUSERNAMES=`echo $TODAYSUNIQUEUSERNAMES|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	USERNAMESNEWTODAY=`echo $USERNAMESNEWTODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TODAYSUNIQUEIPS=`echo $TODAYSUNIQUEIPS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	IPSNEWTODAY=`echo $IPSNEWTODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	sed -i "s/Unique IPs Today.*$/Unique IPs Today:--> $TODAYSUNIQUEIPS/" $1/index.shtml
	sed -i "s/New IPs Today.*$/New IPs Today:--> $IPSNEWTODAY/" $1/index.shtml


	#
	# Count honeypots here
	#
	if [ "x$HOSTNAME" == "x/" ] ;then
		make_header "$1/todays_honeypots.shtml" "Today's honeypots" "Count reflects log entries, not actual login attempts" "Entries in syslog" "Hostname" 

		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |grep LongTail_apache |awk '{print $2}' | sort -T $TMP_DIRECTORY |uniq -c > $1/todays-honeypots.txt
		cat $1/todays-honeypots.txt |wc -l  > $1/todays-honeypots.txt.count

		HONEYPOTSTODAY=`cat $1/todays-honeypots.txt.count`
		
		cat $1/todays-honeypots.txt | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $1/todays_honeypots.shtml


		make_footer "$1/todays_honeypots.shtml" 

	else
		HONEYPOTSTODAY=1	
	fi

	sed -i "s/Number of Honeypots Today:.*$/Number of Honeypots Today:--> $HONEYPOTSTODAY/" $1/index.shtml
	sed -i "s/Number of Honeypots Today:.*$/Number of Honeypots Today:--> $HONEYPOTSTODAY/" $1/index-long.shtml
	
	########################################################################################
	# Make statistics.shtml webpage here
	#
	make_header "$1/statistics.shtml" "Assorted Statistics" "Analysis does not include today's numbers. Numbers rounded to two decimal places" "Time<BR>Frame" "Number<BR>of Days" "Total<BR>SSH attempts" "Average<BR>Per Day" "Std. Dev." "Median" "Max" "Min"

	echo "<TR><TD>So Far Today</TD><TD>1</TD><TD>$TODAY</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD></TR>" >>$1/statistics.shtml
	echo "<TR><TD>This Month</TD><TD> $MONTH_COUNT</TD><TD> $MONTH_SUM</TD><TD> $MONTH_AVERAGE</TD><TD> $MONTH_STD</TD><TD> $MONTH_MEDIAN</TD><TD> $MONTH_MAX</TD><TD> $MONTH_MIN" >>$1/statistics.shtml
	echo "<TR><TD>Last Month</TD><TD> $LAST_MONTH_COUNT</TD><TD> $LAST_MONTH_SUM</TD><TD> $LAST_MONTH_AVERAGE</TD><TD> $LAST_MONTH_STD</TD><TD> $LAST_MONTH_MEDIAN</TD><TD> $LAST_MONTH_MAX</TD><TD> $LAST_MONTH_MIN" >>$1/statistics.shtml
	echo "<TR><TD>This Year</TD><TD> $YEAR_COUNT</TD><TD> $YEAR_SUM</TD><TD> $YEAR_AVERAGE</TD><TD> $YEAR_STD</TD><TD> $YEAR_MEDIAN</TD><TD> $YEAR_MAX</TD><TD> $YEAR_MIN" >>$1/statistics.shtml
	echo "<TR><TD>Since Logging Started</TD><TD> $EVERYTHING_COUNT</TD><TD> $EVERYTHING_SUM</TD><TD> $EVERYTHING_AVERAGE</TD><TD> $EVERYTHING_STD</TD><TD> $EVERYTHING_MEDIAN</TD><TD> $EVERYTHING_MAX</TD><TD> $EVERYTHING_MIN" >>$1/statistics.shtml
	echo "<TR><TD>Normalized Since Logging Started</TD><TD> $NORMALIZED_COUNT</TD><TD> $NORMALIZED_SUM</TD><TD> $NORMALIZED_AVERAGE</TD><TD> $NORMALIZED_STD</TD><TD> $NORMALIZED_MEDIAN</TD><TD> $NORMALIZED_MAX</TD><TD> $NORMALIZED_MIN" >>$1/statistics.shtml
	echo "" >> $1/statistics.shtml
	echo "</TABLE><!--HEADERLINE -->" >> $1/statistics.shtml

	cat $1/statistics.shtml > $1/more_statistics.shtml
	todays_assorted_stats "todays_ips.count" $1/more_statistics.shtml
	todays_assorted_stats "todays_password.count" $1/more_statistics.shtml
	todays_assorted_stats "todays_username.count" $1/more_statistics.shtml

	echo "<P>Normalized data is data that consists of only full days of attacks,<!--HEADERLINE --> " >> $1/more_statistics.shtml
	echo "AND to servers that are NOT protected by firewalls or other kinds of <!--HEADERLINE -->" >> $1/more_statistics.shtml
	echo "intrusion protection systems.<!--HEADERLINE -->"  >> $1/more_statistics.shtml

	echo "<P>Normalized data is data that consists of only full days of attacks,<!--HEADERLINE --> " >> $1/statistics.shtml
	echo "AND to servers that are NOT protected by firewalls or other kinds of <!--HEADERLINE -->" >> $1/statistics.shtml
	echo "intrusion protection systems.<!--HEADERLINE -->"  >> $1/statistics.shtml

	make_footer "$1/statistics.shtml"
	make_footer "$1/more_statistics.shtml"


	# Make statistics_all.shtml and more_statistics_all.shtml webpage here
	if [ "x$HOSTNAME" == "x/" ] ;then
		cd $HTML_DIR
		table_header="<TR><TH>Time<BR>Frame</TH><TH>Number<BR>of Days</TH><TH>Total<BR>SSH attempts</TH><TH>Average<br>Per Day</TH><TH>Std. Dev.</TH><TH>Median</TH><TH>Max</TH><TH>Min</TH>"
		grep HEADERLINE statistics.shtml |egrep -v footer.html\|'</BODY'\|'</HTML'\|'</TABLE'\|'</TR' > statistics_all.shtml
		echo "<TR><TH colspan=8>All Hosts Combined</TH></TR>" >> statistics_all.shtml
		grep '<TR>' $HTML_DIR/statistics.shtml |grep -v HEADERLINE |sed 's/<TD>/<TD>ALL Hosts /' >> statistics_all.shtml

		grep HEADERLINE statistics.shtml |egrep -v footer.html\|'</BODY'\|'</HTML'\|'</TABLE'\|'</TR' > more_statistics_all.shtml
		echo "<TR><TH colspan=8>All Hosts Combined</TH></TR>" >> more_statistics_all.shtml
		egrep '<TR>'\|'<TH>' $HTML_DIR/more_statistics.shtml |sed 's/<TD>/<TD>ALL Hosts /' >> more_statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by BlackRidge Technologies</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by BlackRidge Technologies</TH></TR>" >> more_statistics_all.shtml
		for dir in $BLACKRIDGE ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done
		
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by an Intrusion Protection System</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by an Intrusion Protection System</TH></TR>" >> more_statistics_all.shtml
		for dir in $HOSTS_PROTECTED ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Educational Sites</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Educational Sites</TH></TR>" >> more_statistics_all.shtml
		for dir in $EDUCATIONAL_SITES ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Residential Sites</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Residential Sites</TH></TR>" >> more_statistics_all.shtml
		for dir in $RESIDENTIAL_SITES ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Cloud Provider Sites</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Cloud Provider Sites</TH></TR>" >> more_statistics_all.shtml
		for dir in $CLOUD_SITES ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		#echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Commercial Sites</TH></TR>" >> statistics_all.shtml
		#echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Commercial Sites</TH></TR>" >> more_statistics_all.shtml
		#for dir in $BUSINESS_SITES ; do
			#if [ -e $dir/statistics.shtml ] ; then
				#DESCRIPTION=`cat $dir/description.html`
				#echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
#		echo $table_header >>statistics_all.shtml
		#echo $table_header >>more_statistics_all.shtml
				#grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				#echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				#egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			#fi
		#done

		echo "</TABLE>" >> statistics_all.shtml
		echo "</TABLE>" >> more_statistics_all.shtml

		echo "<P>Total SSH attempts for all hosts may be LARGER than the sum <!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "of SSH attempts of each host.  This is because each host's attacks <!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "are counted before totalling all the SSH attacks, and if attacks are<!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "ongoing, then more attacks will have come in between counting for a host<!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "and counting all the SSH attacks.<!--HEADERLINE -->"  >> $1/statistics_all.shtml


		echo "<P>Total SSH attempts for all hosts may be LARGER than the sum <!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "of SSH attempts of each host.  This is because each host's attacks <!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "are counted before totalling all the SSH attacks, and if attacks are<!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "ongoing, then more attacks will have come in between counting for a host<!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "and counting all the SSH attacks.<!--HEADERLINE -->"  >> $1/more_statistics_all.shtml

		echo "<!--#include virtual=/$HTML_TOP_DIR/footer.html --> <!--HEADERLINE --> " >> statistics_all.shtml
		echo "</BODY><!--HEADERLINE -->" >> statistics_all.shtml
		echo "</HTML><!--HEADERLINE -->" >> statistics_all.shtml

		echo "<!--#include virtual=/$HTML_TOP_DIR/footer.html --> <!--HEADERLINE --> " >> more_statistics_all.shtml
		echo "</BODY><!--HEADERLINE -->" >> more_statistics_all.shtml
		echo "</HTML><!--HEADERLINE -->" >> more_statistics_all.shtml
	fi

	cd $ORIGINAL_DIRECTORY
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

	TMP_DATE=`date +"%Y-%m-%d"`
	TMP_YEAR=`date +%Y`
	TMP_MONTH=`date +%m`
	TMP_DAY=`date +%d`
	#
	# Lets make sure we have one for today and this month and this year
	TMP_DIR="$TMP_HTML"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY"
	if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
	for dir in $HOSTS_PROTECTED $BLACKRIDGE ; do
		if [ "x$HOSTNAME" == "x$dir" ] ; then
			touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
			echo $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
		fi
	done
	#
	# Why did I add this line?
	# This makes sure the current day exists and is set to no data ?
        # But why am I creating this file later?
        # So I commented out the if statement so I ALWAYS clear the current data.
	#if [ ! -e $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz ] ; then
		echo "" |gzip -c > $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
		chmod a+r $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
	#fi


	#
	# TODAY
	#
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/TODAY now" ; date; fi
	cd $PATH_TO_VAR_LOG
	if [ "x$HOSTNAME" == "x/" ] ;then
		if [ $LONGTAIL -eq 1 ] ; then
				TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`
		fi
		if [ $KIPPO -eq 1 ] ; then
			TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt|wc -l`
		fi
	else # We were passed a hostname.  This should never happen with Kippo
		if [ $KIPPO -eq 1 ] ; then
			echo "LongTail is only for single instances of Kippo.  You passed a hostname to LongTail.sh"
			echo "Exiting now"
			exit
		fi
		TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`
	fi
	echo $TODAY > $TMP_HTML_DIR/current-attack-count.data

	#
	# THIS MONTH
	#
	cd $TMP_HTML_DIR/historical/
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/This Month now" ;date;  fi
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_MONTH=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG this month statistics" ;date; fi
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# This fails on the first of the month
	#
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ -e $TMP_YEAR/$TMP_MONTH ] ; then 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/This Month/Statistics now" ; fi
		cat $TMP_YEAR/$TMP_MONTH/*/current-attack-count.data|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}; $n; print "MONTH_COUNT=$n\nMONTH_SUM=$s\nMONTH_AVERAGE=$a\nMONTH_STD=$std\nMONTH_MEDIAN=$med\nMONTH_MAX=$m\nMONTH_MIN=$mm";'  > $TMPFILE
		# Now we "source" the script to set environment varaibles we use later
		. $TMPFILE
		# Now we "clean up" the average and STD deviation
		MONTH_AVERAGE=`printf '%.2f' $MONTH_AVERAGE`
		MONTH_STD=`printf '%.2f' $MONTH_STD`
	else
		MONTH_COUNT=1
		MONTH_SUM=$TODAY
		MONTH_AVERAGE=$TODAY
		MONTH_STD=0
		MONTH_MEDIAN=$TODAY
		MONTH_MAX=$TODAY
		MONTH_MIN=$TODAY
		#MONTH_AVERAGE=`printf '%.2f' 0`
		MONTH_STD=`printf '%.2f' 0`
	fi
	rm $TMPFILE

	MONTH_COUNT=`echo $MONTH_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_SUM=`echo $MONTH_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_AVERAGE=`echo $MONTH_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_STD=`echo $MONTH_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MEDIAN=`echo $MONTH_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MAX=`echo $MONTH_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MIN=`echo $MONTH_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# LAST MONTH
	#
	cd $TMP_HTML_DIR/historical/
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/Last Month now" ; date ; fi
#
# Gotta fix this for the year boundary
#
	TMP_LAST_MONTH=`date "+%m" --date="last month"`
	TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`
	TMP=0
	for FILE in  `find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	LAST_MONTH=$TMP
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG Last month statistics" ;date ;  fi
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	#
	# Gotta do the date calculation to figure out "When" is last month
	#
	if [ -d $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/ ] ; then 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/Last Month/statistics now" ; fi
		cat $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/*/current-attack-count.data|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "LAST_MONTH_COUNT=$n\nLAST_MONTH_SUM=$s\nLAST_MONTH_AVERAGE=$a\nLAST_MONTH_STD=$std\nLAST_MONTH_MEDIAN=$med\nLAST_MONTH_MAX=$m\nLAST_MONTH_MIN=$mm";'  > $TMPFILE
		# Now we "source" the script to set environment varaibles we use later
		. $TMPFILE
		# Now we "clean up" the average and STD deviation
		LAST_MONTH_AVERAGE=`printf '%.2f' $LAST_MONTH_AVERAGE`
		LAST_MONTH_STD=`printf '%.2f' $LAST_MONTH_STD`
	else
		LAST_MONTH_COUNT="N/A"
		LAST_MONTH_SUM="N/A"
		LAST_MONTH_AVERAGE="N/A"
		LAST_MONTH_STD="N/A"
		LAST_MONTH_MEDIAN="N/A"
		LAST_MONTH_MAX="N/A"
		LAST_MONTH_MIN="N/A"
		LAST_MONTH_STD="N/A"
	fi
	rm $TMPFILE

	LAST_MONTH_COUNT=`echo $LAST_MONTH_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_SUM=`echo $LAST_MONTH_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_AVERAGE=`echo $LAST_MONTH_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_STD=`echo $LAST_MONTH_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MEDIAN=`echo $LAST_MONTH_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MAX=`echo $LAST_MONTH_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MIN=`echo $LAST_MONTH_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/This Year now" ; date; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR=`expr $TMP + $TODAY`
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG this year statistics" ; date; fi
	# OK, this may not be 100% secure, but it's close enough for now
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/This Year now/statistics" ; fi
	for FILE in  `find $TMP_YEAR/ -name current-attack-count.data` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "YEAR_COUNT=$n\nYEAR_SUM=$s\nYEAR_AVERAGE=$a\nYEAR_STD=$std\nYEAR_MEDIAN=$med\nYEAR_MAX=$m\nYEAR_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	YEAR_AVERAGE=`printf '%.2f' $YEAR_AVERAGE`
	YEAR_STD=`printf '%.2f' $YEAR_STD`


	YEAR_COUNT=`echo $YEAR_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_SUM=`echo $YEAR_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_AVERAGE=`echo $YEAR_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_STD=`echo $YEAR_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MEDIAN=`echo $YEAR_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MAX=`echo $YEAR_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MIN=`echo $YEAR_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
	TMP=0
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/everything" ;  date;fi
	for FILE in  `find . -name current-attack-count.data` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL  statistics" ; date;  fi
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/everything/statistics" ; fi
	for FILE in  `find . -name current-attack-count.data` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "EVERYTHING_COUNT=$n\nEVERYTHING_SUM=$s\nEVERYTHING_AVERAGE=$a\nEVERYTHING_STD=$std\nEVERYTHING_MEDIAN=$med\nEVERYTHING_MAX=$m\nEVERYTHING_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	EVERYTHING_AVERAGE=`printf '%.2f' $EVERYTHING_AVERAGE`
	EVERYTHING_STD=`printf '%.2f' $EVERYTHING_STD`

	EVERYTHING_COUNT=`echo $EVERYTHING_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_SUM=`echo $EVERYTHING_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_AVERAGE=`echo $EVERYTHING_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_STD=`echo $EVERYTHING_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MEDIAN=`echo $EVERYTHING_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MAX=`echo $EVERYTHING_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MIN=`echo $EVERYTHING_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# Normalized data
	#
	if [ "x$HOSTNAME" == "x/" ] ;then
		# I have no idea where this breaks, but it's a big-ass number of files
		cd $HTML_DIR
		# OK, this may not be 100% secure, but it's close enough for now
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL Normalized statistics" ; date ; fi
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in  `find */historical -name current-attack-count.data ` ; do if [ ! -e $FILE.notfullday ] ; then cat $FILE ; fi ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
		. $TMPFILE
		rm $TMPFILE
		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
	else
		# I have no idea where this breaks, but it's a big-ass number of files
		cd $HTML_DIR
		# OK, this may not be 100% secure, but it's close enough for now
		if [ $DEBUG  == 1 ] ; then echo "DEBUG Hostname only ALL  statistics" ; fi
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in  `find ./historical -name current-attack-count.data ` ; do if [ ! -e $FILE.notfullday ] ; then cat $FILE ; fi ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
		. $TMPFILE
		rm $TMPFILE
		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
	fi

	NORMALIZED_COUNT=`echo $NORMALIZED_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_SUM=`echo $NORMALIZED_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_AVERAGE=`echo $NORMALIZED_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_STD=`echo $NORMALIZED_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MEDIAN=`echo $NORMALIZED_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MAX=`echo $NORMALIZED_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MIN=`echo $NORMALIZED_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# This really needs to be sped up somehow
	#
	# Couting honeypots here
	if [ $START_HOUR -eq $MIDNIGHT ]; then
	if [ "x$HOSTNAME" == "x/" ] ;then
	if [ $SEARCH_FOR == "sshd" ] ; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all honeypots now"; date ; fi

		#ALLUNIQUEHONEYPOTS=`zcat historical/*/*/*/current-raw-data.gz |egrep IP:\|sshd | awk '{print $2}' |sort -T $TMP_DIRECTORY -u  |wc -l`
		#THISYEARUNIQUEHONEYPOTS=`zcat historical/$TMP_YEAR/*/*/current-raw-data.gz |egrep IP:\|sshd |awk '{print $2}'|sort -T $TMP_DIRECTORY -u |wc -l `
		#THISMONTHUNIQUEHONEYPOTS=`zcat historical/$TMP_YEAR/$TMP_MONTH/*/all_messages.gz |grep ssh |awk '{print $2}'|sort -T $TMP_DIRECTORY -u |wc -l `

		honey_file="todays-honeypots.txt"
		TMP=0
		touch /$TMP_DIRECTORY/honeypots.$$
		rm /$TMP_DIRECTORY/honeypots.$$
		for FILE in  `find historical/$TMP_YEAR/$TMP_MONTH -name $honey_file` ; do
			awk '{print $2}' $FILE |grep -v ^$  >> /$TMP_DIRECTORY/honeypots.$$
		done
		THISMONTHUNIQUEHONEYPOTS=`sort -u /$TMP_DIRECTORY/honeypots.$$|grep -v ^$ | wc -l `
		rm /$TMP_DIRECTORY/honeypots.$$

		TMP=0
		touch /$TMP_DIRECTORY/honeypots.$$
		rm /$TMP_DIRECTORY/honeypots.$$
		for FILE in  `find historical/$TMP_YEAR/ -name $honey_file` ; do
			awk '{print $2}' $FILE |grep -v ^$  >> /$TMP_DIRECTORY/honeypots.$$
		done
		THISYEARUNIQUEHONEYPOTS=`sort -u /$TMP_DIRECTORY/honeypots.$$|grep -v ^$ | wc -l `
		rm /$TMP_DIRECTORY/honeypots.$$
		TMP=0

		touch /$TMP_DIRECTORY/honeypots.$$
		rm /$TMP_DIRECTORY/honeypots.$$
		for FILE in  `find historical/  -name $honey_file` ; do
			awk '{print $2}' $FILE |grep -v ^$  >> /$TMP_DIRECTORY/honeypots.$$
		done
		ALLUNIQUEHONEYPOTS=`sort -u /$TMP_DIRECTORY/honeypots.$$|grep -v ^$ | wc -l `
		rm /$TMP_DIRECTORY/honeypots.$$

		THISMONTHUNIQUEHONEYPOTS=`echo $THISMONTHUNIQUEHONEYPOTS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THISYEARUNIQUEHONEYPOTS=`echo $THISYEARUNIQUEHONEYPOTS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		ALLUNIQUEHONEYPOTS=`echo $ALLUNIQUEHONEYPOTS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		sed -i "s/Number of Honeypots This Month.*$/Number of Honeypots This Month:--> $THISMONTHUNIQUEHONEYPOTS/" $1/index.shtml
		sed -i "s/Number of Honeypots This Year.*$/Number of Honeypots This Year:--> $THISYEARUNIQUEHONEYPOTS/" $1/index.shtml
		sed -i "s/Number of Honeypots Since Logging Started.*$/Number of Honeypots Since Logging Started:--> $ALLUNIQUEHONEYPOTS/" $1/index.shtml
		sed -i "s/Number of Honeypots This Month.*$/Number of Honeypots This Month:--> $THISMONTHUNIQUEHONEYPOTS/" $1/index-long.shtml
		sed -i "s/Number of Honeypots This Year.*$/Number of Honeypots This Year:--> $THISYEARUNIQUEHONEYPOTS/" $1/index-long.shtml
		sed -i "s/Number of Honeypots Since Logging Started.*$/Number of Honeypots Since Logging Started:--> $ALLUNIQUEHONEYPOTS/" $1/index-long.shtml

	fi
	fi
	fi


	# SOMEWHERE there is a bug which if the password is empty, that the
	# line sent to syslog is "...Password:$", instead of "...Password: $"
	# Please note the missing space at the end of the line is the bug
	# and now I need to code around it everyplace :-(
	if [ ! -e all-password ] ; then
		touch all-password
	fi
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all passwords now"; date ; fi
		zcat historical/*/*/*/current-raw-data.gz |grep IP: |sed 's/^..*Password:\ //' |sed 's/^..*Password:$/ /' |sort -T $TMP_DIRECTORY -u > all-password
		THISYEARUNIQUEPASSWORDS=`zcat historical/$TMP_YEAR/*/*/current-raw-data.gz |grep IP: |sed 's/^..*Password:\ //'  |sed 's/^..*Password:$/ /'|sort -T $TMP_DIRECTORY -u |wc -l `
		THISMONTHUNIQUEPASSWORDS=`zcat historical/$TMP_YEAR/$TMP_MONTH/*/current-raw-data.gz |grep IP: |sed 's/^..*Password:\ //'  |sed 's/^..*Password:$/ /'|sort -T $TMP_DIRECTORY -u |wc -l `
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Done Getting all passwords now"; date ; fi
		ALLUNIQUEPASSWORDS=`cat all-password |wc -l`

		THISMONTHUNIQUEPASSWORDS=`echo $THISMONTHUNIQUEPASSWORDS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THISYEARUNIQUEPASSWORDS=`echo $THISYEARUNIQUEPASSWORDS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		ALLUNIQUEPASSWORDS=`echo $ALLUNIQUEPASSWORDS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

		sed -i "s/Unique Passwords This Month.*$/Unique Passwords This Month:--> $THISMONTHUNIQUEPASSWORDS/" $1/index.shtml
		sed -i "s/Unique Passwords This Year.*$/Unique Passwords This Year:--> $THISYEARUNIQUEPASSWORDS/" $1/index.shtml
		sed -i "s/Unique Passwords Since Logging Started.*$/Unique Passwords Since Logging Started:--> $ALLUNIQUEPASSWORDS/" $1/index.shtml
		sed -i "s/Unique Passwords This Month.*$/Unique Passwords This Month:--> $THISMONTHUNIQUEPASSWORDS/" $1/index-long.shtml
		sed -i "s/Unique Passwords This Year.*$/Unique Passwords This Year:--> $THISYEARUNIQUEPASSWORDS/" $1/index-long.shtml
		sed -i "s/Unique Passwords Since Logging Started.*$/Unique Passwords Since Logging Started:--> $ALLUNIQUEPASSWORDS/" $1/index-long.shtml
	fi
	if [ "x$HOSTNAME" == "x/" ] ;then
		if [ $KIPPO -eq 1 ] ; then
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt| sed 's/^..*\///' | sed 's/\].*$//'|sort -T $TMP_DIRECTORY -u |sed 's/^$/NO-PASSWORD-GIVEN/'> todays_passwords
		else
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|sed 's/^..*Password:\ //'  |sed 's/^..*Password:$/ /'|sort -T $TMP_DIRECTORY -u > todays_passwords
		fi
	else
		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|sed 's/^..*Password:\ //'  |sed 's/^..*Password:$/ /'|sort -T $TMP_DIRECTORY -u > todays_passwords
	fi
	TODAYSUNIQUEPASSWORDS=`cat todays_passwords |wc -l`
	echo $TODAYSUNIQUEPASSWORDS  >todays_password.count
	awk 'FNR==NR{a[$0]++;next}(!($0 in a))' all-password todays_passwords >todays-uniq-passwords.txt
	PASSWORDSNEWTODAY=`cat todays-uniq-passwords.txt |wc -l`

	make_header "$1/todays-uniq-passwords.shtml" "Passwords Never Seen Before Today"
	echo "</TABLE>" >> $1/todays-uniq-passwords.shtml
	echo "<HR>" >> $1/todays-uniq-passwords.shtml
	cat todays-uniq-passwords.txt |\
	awk '{printf("<BR><a href=\"https://www.google.com/search?q=&#34password+%s&#34\">%s</a> \n",$1,$1)}' >> $1/todays-uniq-passwords.shtml
	make_footer "$1/todays-uniq-passwords.shtml"



	#
	# This really needs to be sped up somehow
	#
#2015-03-29T03:07:36-04:00 shepherd sshd-22[2766]: IP: 103.41.124.140 PassLog: Username: root Password: tommy007

	if [ ! -e all-username ] ; then
		touch all-username
	fi
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all Usernames now"; date ; fi
		zcat historical/*/*/*/current-raw-data.gz |grep IP: |sed 's/^..*Username:\ //' |sed 's/ Password:$/ /' |sed 's/ Password:.*$/ /' |sort -T $TMP_DIRECTORY -u > all-username
		THISYEARUNIQUEUSERNAMES=`zcat historical/$TMP_YEAR/*/*/current-raw-data.gz |grep IP: |sed 's/^..*Username:\ //' |sed 's/ Password:$/ /' |sed 's/ Password:.*$/ /'|sort -T $TMP_DIRECTORY -u |wc -l `
		THISMONTHUNIQUEUSERNAMES=`zcat historical/$TMP_YEAR/$TMP_MONTH/*/current-raw-data.gz |grep IP: |sed 's/^..*Username:\ //' |sed 's/ Password:$/ /' |sed 's/ Password:.*$/ /'|sort -T $TMP_DIRECTORY -u |wc -l `
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Done Getting all username now"; date ; fi
		ALLUNIQUEUSERNAMES=`cat all-username |wc -l`

		THISMONTHUNIQUEUSERNAMES=`echo $THISMONTHUNIQUEUSERNAMES|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THISYEARUNIQUEUSERNAMES=`echo $THISYEARUNIQUEUSERNAMES|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		ALLUNIQUEUSERNAMES=`echo $ALLUNIQUEUSERNAMES|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

		sed -i "s/Unique Usernames This Month.*$/Unique Usernames This Month:--> $THISMONTHUNIQUEUSERNAMES/" $1/index.shtml
		sed -i "s/Unique Usernames This Year.*$/Unique Usernames This Year:--> $THISYEARUNIQUEUSERNAMES/" $1/index.shtml
		sed -i "s/Unique Usernames Since Logging Started.*$/Unique Usernames Since Logging Started:--> $ALLUNIQUEUSERNAMES/" $1/index.shtml

		sed -i "s/Unique Usernames This Month.*$/Unique Usernames This Month:--> $THISMONTHUNIQUEUSERNAMES/" $1/index-long.shtml
		sed -i "s/Unique Usernames This Year.*$/Unique Usernames This Year:--> $THISYEARUNIQUEUSERNAMES/" $1/index-long.shtml
		sed -i "s/Unique Usernames Since Logging Started.*$/Unique Usernames Since Logging Started:--> $ALLUNIQUEUSERNAMES/" $1/index-long.shtml
	fi
	if [ "x$HOSTNAME" == "x/" ] ;then
		if [ $KIPPO -eq 1 ] ; then
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt |sed 's/^..*\[//' | sed 's/\/..*$//' |sort -T $TMP_DIRECTORY -u > todays_username
		else
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|sed 's/^..*Username:\ //' |sed 's/ Password:$/ /' |sed 's/ Password:.*$/ /'|sort -T $TMP_DIRECTORY -u > todays_username
		fi
	else
		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|sed 's/^..*Username:\ //' |sed 's/ Password.:$/ /' |sed 's/ Password:.*$/ /'|sort -T $TMP_DIRECTORY -u > todays_username
	fi
	TODAYSUNIQUEUSERNAMES=`cat todays_username |wc -l`
	echo $TODAYSUNIQUEUSERNAMES  >todays_username.count
	awk 'FNR==NR{a[$0]++;next}(!($0 in a))' all-username todays_username >todays-uniq-username.txt
	USERNAMESNEWTODAY=`cat todays-uniq-username.txt |wc -l`

	make_header "$1/todays-uniq-username.shtml" "Usernames Never Seen Before Today"
	echo "</TABLE>" >> $1/todays-uniq-username.shtml
	echo "<HR>" >> $1/todays-uniq-username.shtml
	cat todays-uniq-username.txt |\
	awk '{printf("<BR><a href=\"https://www.google.com/search?q=&#34username+%s&#34\">%s</a> \n",$1,$1)}' >> $1/todays-uniq-username.shtml
	make_footer "$1/todays-uniq-username.shtml"



	#
	# This really needs to be sped up somehow
	#
#2015-03-29T03:07:36-04:00 shepherd sshd-22[2766]: IP: 103.41.124.140 PassLog: Username: root Password: tommy007
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all Honeypots now"; date ; fi

			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep IP:\|sshd |awk '{print $2}' |grep -v longtail| sort -T $TMP_DIRECTORY |uniq -c > todays-honeypots.txt
			cat $1/todays-honeypots.txt |wc -l  > todays-honeypots.txt.count
	fi

	if [ ! -e all-ips ] ; then
		touch all-ips
	fi
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Getting all IPs now"; date ; fi
		zcat historical/*/*/*/current-raw-data.gz                                       |grep IP: |sed 's/^..*IP: //' |sed 's/ .*$//' |sort -T $TMP_DIRECTORY -u > all-ips
		THISYEARUNIQUEIPSS=`zcat historical/$TMP_YEAR/*/*/current-raw-data.gz           |grep IP: |sed 's/^..*IP: //' |sed 's/ .*$//'|sort -T $TMP_DIRECTORY -u |wc -l `
		THISMONTHUNIQUEIPSS=`zcat historical/$TMP_YEAR/$TMP_MONTH/*/current-raw-data.gz |grep IP: |sed 's/^..*IP: //' |sed 's/ .*$//'|sort -T $TMP_DIRECTORY -u |wc -l `
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Done Getting all ips now"; date ; fi
		ALLUNIQUEIPSS=`cat all-ips |wc -l`

		THISMONTHUNIQUEIPSS=`echo $THISMONTHUNIQUEIPSS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THISYEARUNIQUEIPSS=`echo $THISYEARUNIQUEIPSS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		ALLUNIQUEIPSS=`echo $ALLUNIQUEIPSS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

		sed -i "s/Unique IPs This Month.*$/Unique IPs This Month:--> $THISMONTHUNIQUEIPSS/" $1/index.shtml
		sed -i "s/Unique IPs This Year.*$/Unique IPs This Year:--> $THISYEARUNIQUEIPSS/" $1/index.shtml
		sed -i "s/Unique IPs Since Logging Started.*$/Unique IPs Since Logging Started:--> $ALLUNIQUEIPSS/" $1/index.shtml

		sed -i "s/Unique IPs This Month.*$/Unique IPs This Month:--> $THISMONTHUNIQUEIPSS/" $1/index-long.shtml
		sed -i "s/Unique IPs This Year.*$/Unique IPs This Year:--> $THISYEARUNIQUEIPSS/" $1/index-long.shtml
		sed -i "s/Unique IPs Since Logging Started.*$/Unique IPs Since Logging Started:--> $ALLUNIQUEIPSS/" $1/index-long.shtml
	fi
	if [ "x$HOSTNAME" == "x/" ] ;then
		if [ $KIPPO -eq 1 ] ; then
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt |sed 's/^..*,.*,//' |sed 's/\]..*$//' |sort -T $TMP_DIRECTORY -u > todays_ips
		else
			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|grep IP: |sed 's/^..*IP: //' |tr -cd '\11\12\40-\176'  |sed 's/ .*$//'|sort -T $TMP_DIRECTORY -u > todays_ips
		fi
	else
		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '$2 == "'$HOSTNAME'" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |grep IP: |sed 's/^..*IP: //' |tr -cd '\11\12\40-\176'  | sed 's/ .*$//' |sort -T $TMP_DIRECTORY -u > todays_ips
	fi
	TODAYSUNIQUEIPS=`cat todays_ips |wc -l`
	echo $TODAYSUNIQUEIPS  >todays_ips.count
	awk 'FNR==NR{a[$0]++;next}(!($0 in a))' all-ips todays_ips >todays-uniq-ips.txt
	IPSNEWTODAY=`cat todays-uniq-ips.txt |wc -l`

	make_header "$1/todays-uniq-ips.shtml" "IP Addresses Never Seen Before Today" " " "Count" "IP Address" "Country" "WhoIS" "Blacklisted" "Attack Patterns"

	for IP in `cat todays-uniq-ips.txt` ; do grep .TD.$IP..TD. current-ip-addresses.shtml >> $1/todays-uniq-ips.shtml; done

	make_footer "$1/todays-uniq-ips.shtml"
	sed -i s/HONEY/$HTML_TOP_DIR/g $1/todays-uniq-ips.shtml

	
	TODAY=`echo $TODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_MONTH=`echo $THIS_MONTH|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_YEAR=`echo $THIS_YEAR|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TOTAL=`echo $TOTAL|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	TODAYSUNIQUEPASSWORDS=`echo $TODAYSUNIQUEPASSWORDS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	PASSWORDSNEWTODAY=`echo $PASSWORDSNEWTODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TODAYSUNIQUEUSERNAMES=`echo $TODAYSUNIQUEUSERNAMES|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	USERNAMESNEWTODAY=`echo $USERNAMESNEWTODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TODAYSUNIQUEIPS=`echo $TODAYSUNIQUEIPS|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	IPSNEWTODAY=`echo $IPSNEWTODAY|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	sed -i "s/Login Attempts Today.*$/Login Attempts Today:--> $TODAY/" $1/index.shtml
	sed -i "s/Login Attempts This Month.*$/Login Attempts This Month:--> $THIS_MONTH/" $1/index.shtml
	sed -i "s/Login Attempts This Year.*$/Login Attempts This Year:--> $THIS_YEAR/" $1/index.shtml
	sed -i "s/Login Attempts Since Logging Started.*$/Login Attempts Since Logging Started:--> $TOTAL/" $1/index.shtml

	sed -i "s/Unique Passwords Today.*$/Unique Passwords Today:--> $TODAYSUNIQUEPASSWORDS/" $1/index.shtml
	sed -i "s/New Passwords Today.*$/New Passwords Today:--> $PASSWORDSNEWTODAY/" $1/index.shtml

	sed -i "s/Unique Usernames Today.*$/Unique Usernames Today:--> $TODAYSUNIQUEUSERNAMES/" $1/index.shtml
	sed -i "s/New Usernames Today.*$/New Usernames Today:--> $USERNAMESNEWTODAY/" $1/index.shtml

	sed -i "s/Unique IPs Today.*$/Unique IPs Today:--> $TODAYSUNIQUEIPS/" $1/index.shtml
	sed -i "s/New IPs Today.*$/New IPs Today:--> $IPSNEWTODAY/" $1/index.shtml

	sed -i "s/Login Attempts Today.*$/Login Attempts Today:--> $TODAY/" $1/index-long.shtml
	sed -i "s/Login Attempts This Month.*$/Login Attempts This Month:--> $THIS_MONTH/" $1/index-long.shtml
	sed -i "s/Login Attempts This Year.*$/Login Attempts This Year:--> $THIS_YEAR/" $1/index-long.shtml
	sed -i "s/Login Attempts Since Logging Started.*$/Login Attempts Since Logging Started:--> $TOTAL/" $1/index-long.shtml

	sed -i "s/Unique Passwords Today.*$/Unique Passwords Today:--> $TODAYSUNIQUEPASSWORDS/" $1/index-long.shtml
	sed -i "s/New Passwords Today.*$/New Passwords Today:--> $PASSWORDSNEWTODAY/" $1/index-long.shtml

	sed -i "s/Unique Usernames Today.*$/Unique Usernames Today:--> $TODAYSUNIQUEUSERNAMES/" $1/index-long.shtml
	sed -i "s/New Usernames Today.*$/New Usernames Today:--> $USERNAMESNEWTODAY/" $1/index-long.shtml

	sed -i "s/Unique IPs Today.*$/Unique IPs Today:--> $TODAYSUNIQUEIPS/" $1/index-long.shtml
	sed -i "s/New IPs Today.*$/New IPs Today:--> $IPSNEWTODAY/" $1/index-long.shtml

	#
	# Count honeypots here
	#
	if [ "x$HOSTNAME" == "x/" ] ;then
		make_header "$1/todays_honeypots.shtml" "Today's honeypots" "Count reflects log entries, not actual login attempts" "Entries in syslog" "Hostname" 

		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep IP:\|sshd |awk '{print $2}' |grep -v longtail| sort -T $TMP_DIRECTORY |uniq -c > $1/todays-honeypots.txt
		cat $1/todays-honeypots.txt |wc -l  > $1/todays-honeypots.txt.count

		HONEYPOTSTODAY=`cat $1/todays-honeypots.txt.count`
		
		cat $1/todays-honeypots.txt | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $1/todays_honeypots.shtml


		make_footer "$1/todays_honeypots.shtml" 

	else
		HONEYPOTSTODAY=1	
	fi

	sed -i "s/Number of Honeypots Today:.*$/Number of Honeypots Today:--> $HONEYPOTSTODAY/" $1/index.shtml
	sed -i "s/Number of Honeypots Today:.*$/Number of Honeypots Today:--> $HONEYPOTSTODAY/" $1/index-long.shtml
	
	########################################################################################
	# Make statistics.shtml webpage here
	#
	make_header "$1/statistics.shtml" "Assorted Statistics" "Analysis does not include today's numbers. Numbers rounded to two decimal places" "Time<BR>Frame" "Number<BR>of Days" "Total<BR>SSH attempts" "Average<BR>Per Day" "Std. Dev." "Median" "Max" "Min"

	echo "<TR><TD>So Far Today</TD><TD>1</TD><TD>$TODAY</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD></TR>" >>$1/statistics.shtml
	echo "<TR><TD>This Month</TD><TD> $MONTH_COUNT</TD><TD> $MONTH_SUM</TD><TD> $MONTH_AVERAGE</TD><TD> $MONTH_STD</TD><TD> $MONTH_MEDIAN</TD><TD> $MONTH_MAX</TD><TD> $MONTH_MIN" >>$1/statistics.shtml
	echo "<TR><TD>Last Month</TD><TD> $LAST_MONTH_COUNT</TD><TD> $LAST_MONTH_SUM</TD><TD> $LAST_MONTH_AVERAGE</TD><TD> $LAST_MONTH_STD</TD><TD> $LAST_MONTH_MEDIAN</TD><TD> $LAST_MONTH_MAX</TD><TD> $LAST_MONTH_MIN" >>$1/statistics.shtml
	echo "<TR><TD>This Year</TD><TD> $YEAR_COUNT</TD><TD> $YEAR_SUM</TD><TD> $YEAR_AVERAGE</TD><TD> $YEAR_STD</TD><TD> $YEAR_MEDIAN</TD><TD> $YEAR_MAX</TD><TD> $YEAR_MIN" >>$1/statistics.shtml
	echo "<TR><TD>Since Logging Started</TD><TD> $EVERYTHING_COUNT</TD><TD> $EVERYTHING_SUM</TD><TD> $EVERYTHING_AVERAGE</TD><TD> $EVERYTHING_STD</TD><TD> $EVERYTHING_MEDIAN</TD><TD> $EVERYTHING_MAX</TD><TD> $EVERYTHING_MIN" >>$1/statistics.shtml
	echo "<TR><TD>Normalized Since Logging Started</TD><TD> $NORMALIZED_COUNT</TD><TD> $NORMALIZED_SUM</TD><TD> $NORMALIZED_AVERAGE</TD><TD> $NORMALIZED_STD</TD><TD> $NORMALIZED_MEDIAN</TD><TD> $NORMALIZED_MAX</TD><TD> $NORMALIZED_MIN" >>$1/statistics.shtml
	echo "" >> $1/statistics.shtml
	echo "</TABLE><!--HEADERLINE -->" >> $1/statistics.shtml

	cat $1/statistics.shtml > $1/more_statistics.shtml
	todays_assorted_stats "todays_ips.count" $1/more_statistics.shtml
	todays_assorted_stats "todays_password.count" $1/more_statistics.shtml
	todays_assorted_stats "todays_username.count" $1/more_statistics.shtml

	echo "<P>Normalized data is data that consists of only full days of attacks,<!--HEADERLINE --> " >> $1/more_statistics.shtml
	echo "AND to servers that are NOT protected by firewalls or other kinds of <!--HEADERLINE -->" >> $1/more_statistics.shtml
	echo "intrusion protection systems.<!--HEADERLINE -->"  >> $1/more_statistics.shtml

	echo "<P>Normalized data is data that consists of only full days of attacks,<!--HEADERLINE --> " >> $1/statistics.shtml
	echo "AND to servers that are NOT protected by firewalls or other kinds of <!--HEADERLINE -->" >> $1/statistics.shtml
	echo "intrusion protection systems.<!--HEADERLINE -->"  >> $1/statistics.shtml

	make_footer "$1/statistics.shtml"
	make_footer "$1/more_statistics.shtml"


	# Make statistics_all.shtml and more_statistics_all.shtml webpage here
	if [ "x$HOSTNAME" == "x/" ] ;then
		cd $HTML_DIR
		table_header="<TR><TH>Time<BR>Frame</TH><TH>Number<BR>of Days</TH><TH>Total<BR>SSH attempts</TH><TH>Average<br>Per Day</TH><TH>Std. Dev.</TH><TH>Median</TH><TH>Max</TH><TH>Min</TH>"
		grep HEADERLINE statistics.shtml |egrep -v footer.html\|'</BODY'\|'</HTML'\|'</TABLE'\|'</TR' > statistics_all.shtml
		echo "<TR><TH colspan=8>All Hosts Combined</TH></TR>" >> statistics_all.shtml
		grep '<TR>' $HTML_DIR/statistics.shtml |grep -v HEADERLINE |sed 's/<TD>/<TD>ALL Hosts /' >> statistics_all.shtml

		grep HEADERLINE statistics.shtml |egrep -v footer.html\|'</BODY'\|'</HTML'\|'</TABLE'\|'</TR' > more_statistics_all.shtml
		echo "<TR><TH colspan=8>All Hosts Combined</TH></TR>" >> more_statistics_all.shtml
		egrep '<TR>'\|'<TH>' $HTML_DIR/more_statistics.shtml |sed 's/<TD>/<TD>ALL Hosts /' >> more_statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by BlackRidge Technologies</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by BlackRidge Technologies</TH></TR>" >> more_statistics_all.shtml
		for dir in $BLACKRIDGE ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done
		
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by an Intrusion Protection System</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by an Intrusion Protection System</TH></TR>" >> more_statistics_all.shtml
		for dir in $HOSTS_PROTECTED ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Educational Sites</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Educational Sites</TH></TR>" >> more_statistics_all.shtml
		for dir in $EDUCATIONAL_SITES ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Residential Sites</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Residential Sites</TH></TR>" >> more_statistics_all.shtml
		for dir in $RESIDENTIAL_SITES ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Cloud Provider Sites</TH></TR>" >> statistics_all.shtml
		echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Cloud Provider Sites</TH></TR>" >> more_statistics_all.shtml
		for dir in $CLOUD_SITES ; do
			if [ -e $dir/statistics.shtml ] ; then
				DESCRIPTION=`cat $dir/description.html`
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
		echo $table_header >>statistics_all.shtml
		echo $table_header >>more_statistics_all.shtml
				grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			fi
		done

		#echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Commercial Sites</TH></TR>" >> statistics_all.shtml
		#echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Commercial Sites</TH></TR>" >> more_statistics_all.shtml
		#for dir in $BUSINESS_SITES ; do
			#if [ -e $dir/statistics.shtml ] ; then
				#DESCRIPTION=`cat $dir/description.html`
				#echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> statistics_all.shtml
#		echo $table_header >>statistics_all.shtml
		#echo $table_header >>more_statistics_all.shtml
				#grep '<TR>' $dir/statistics.shtml |sed "s/<TD>/<TD>$dir /" >> statistics_all.shtml
				#echo "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" >> more_statistics_all.shtml
				#egrep '<TR>'\|'<TH>' $dir/more_statistics.shtml |sed "s/<TD>/<TD>$dir /" >> more_statistics_all.shtml
			#fi
		#done

		echo "</TABLE>" >> statistics_all.shtml
		echo "</TABLE>" >> more_statistics_all.shtml

		echo "<P>Total SSH attempts for all hosts may be LARGER than the sum <!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "of SSH attempts of each host.  This is because each host's attacks <!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "are counted before totalling all the SSH attacks, and if attacks are<!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "ongoing, then more attacks will have come in between counting for a host<!--HEADERLINE -->"  >> $1/statistics_all.shtml
		echo "and counting all the SSH attacks.<!--HEADERLINE -->"  >> $1/statistics_all.shtml


		echo "<P>Total SSH attempts for all hosts may be LARGER than the sum <!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "of SSH attempts of each host.  This is because each host's attacks <!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "are counted before totalling all the SSH attacks, and if attacks are<!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "ongoing, then more attacks will have come in between counting for a host<!--HEADERLINE -->"  >> $1/more_statistics_all.shtml
		echo "and counting all the SSH attacks.<!--HEADERLINE -->"  >> $1/more_statistics_all.shtml

		echo "<!--#include virtual=/$HTML_TOP_DIR/footer.html --> <!--HEADERLINE --> " >> statistics_all.shtml
		echo "</BODY><!--HEADERLINE -->" >> statistics_all.shtml
		echo "</HTML><!--HEADERLINE -->" >> statistics_all.shtml

		echo "<!--#include virtual=/$HTML_TOP_DIR/footer.html --> <!--HEADERLINE --> " >> more_statistics_all.shtml
		echo "</BODY><!--HEADERLINE -->" >> more_statistics_all.shtml
		echo "</HTML><!--HEADERLINE -->" >> more_statistics_all.shtml
	fi

	cd $ORIGINAL_DIRECTORY
}
	
function todays_assorted_stats {
	local MONTH_COUNT=0
	local MONTH_SUM=0
	local MONTH_AVERAGE=0
	local MONTH_STD=0
	local MONTH_MEDIAN=0
	local MONTH_MAX=0
	local MONTH_MIN=0
	local MONTH_STD=0

	local LAST_MONTH_COUNT=0
	local LAST_MONTH_SUM=0
	local LAST_MONTH_AVERAGE=0
	local LAST_MONTH_STD=0
	local LAST_MONTH_MEDIAN=0
	local LAST_MONTH_MAX=0
	local LAST_MONTH_MIN=0
	local LAST_MONTH_STD=0

	local YEAR_COUNT=0
	local YEAR_SUM=0
	local YEAR_AVERAGE=0
	local YEAR_STD=0
	local YEAR_MEDIAN=0
	local YEAR_MAX=0
	local YEAR_MIN=0
	local YEAR_STD=0

	local EVERYTHING_COUNT=0
	local EVERYTHING_SUM=0
	local EVERYTHING_AVERAGE=0
	local EVERYTHING_STD=0
	local EVERYTHING_MEDIAN=0
	local EVERYTHING_MAX=0
	local EVERYTHING_MIN=0
	local EVERYTHING_STD=0

	local NORMALIZED_COUNT=0
	local NORMALIZED_SUM=0
	local NORMALIZED_AVERAGE=0
	local NORMALIZED_STD=0
	local NORMALIZED_MEDIAN=0
	local NORMALIZED_MAX=0
	local NORMALIZED_MIN=0
	local NORMALIZED_STD=0

	local file=$1
	local outputfile=$2
	if [ $DEBUG  == 1 ] ; then echo "============================================"; fi
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in todays_assorted_stats/This Month now" ; date; fi

	#
	# TODAY
	#
	#ls -l $TMP_HTML_DIR/$file
	if [ -e $TMP_HTML_DIR/$file ] ; then
		TODAY=`cat $TMP_HTML_DIR/$file`
	else
		echo "$TMP_HTML_DIR/$file does not exist yet"
		TODAY=0
	fi

	#
	# THIS MONTH
	#
	TMP_MONTH=`date "+%m"`
	TMP_YEAR=`date "+%Y"`

	cd $TMP_HTML_DIR/historical/
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/This Month now" ; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name $file` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done

	THIS_MONTH=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG this month statistics" ;date; fi
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ -e $TMP_YEAR/$TMP_MONTH ] ; then 
		if [ $DEBUG  == 1 ] ; then echo -n  "DEBUG-in count_ssh_attacks/This Month/Statistics now" ; date ;fi
		cat $TMP_YEAR/$TMP_MONTH/*/$file|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}; $n; print "MONTH_COUNT=$n\nMONTH_SUM=$s\nMONTH_AVERAGE=$a\nMONTH_STD=$std\nMONTH_MEDIAN=$med\nMONTH_MAX=$m\nMONTH_MIN=$mm";'  > $TMPFILE
		# Now we "source" the script to set environment varaibles we use later
		. $TMPFILE
		# Now we "clean up" the average and STD deviation
		MONTH_AVERAGE=`printf '%.2f' $MONTH_AVERAGE`
		MONTH_STD=`printf '%.2f' $MONTH_STD`
	else
		MONTH_COUNT=1
		MONTH_SUM=$TODAY
		MONTH_AVERAGE=$TODAY
		MONTH_STD=0
		MONTH_MEDIAN=$TODAY
		MONTH_MAX=$TODAY
		MONTH_MIN=$TODAY
		#MONTH_AVERAGE=`printf '%.2f' 0`
		MONTH_STD=`printf '%.2f' 0`
	fi
	rm $TMPFILE

	MONTH_COUNT=`echo $MONTH_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_SUM=`echo $MONTH_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_AVERAGE=`echo $MONTH_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_STD=`echo $MONTH_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MEDIAN=`echo $MONTH_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MAX=`echo $MONTH_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	MONTH_MIN=`echo $MONTH_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# LAST MONTH
	#
	cd $TMP_HTML_DIR/historical/
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/Last Month now" ; fi
#
# Gotta fix this for the year boundary
#
	TMP_LAST_MONTH=`date "+%m" --date="last month"`
	TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`
	TMP=0
	for FILE in  `find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name $file` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	LAST_MONTH=$TMP
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG Last month statistics" ;date; fi
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	#
	# Gotta do the date calculation to figure out "When" is last month
	#
	if [ -d $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/ ] ; then 
		if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/Last Month/statistics now" ; date ;fi
		cat $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/*/$file|perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "LAST_MONTH_COUNT=$n\nLAST_MONTH_SUM=$s\nLAST_MONTH_AVERAGE=$a\nLAST_MONTH_STD=$std\nLAST_MONTH_MEDIAN=$med\nLAST_MONTH_MAX=$m\nLAST_MONTH_MIN=$mm";'  > $TMPFILE
		# Now we "source" the script to set environment varaibles we use later
		. $TMPFILE
		# Now we "clean up" the average and STD deviation
		LAST_MONTH_AVERAGE=`printf '%.2f' $LAST_MONTH_AVERAGE`
		LAST_MONTH_STD=`printf '%.2f' $LAST_MONTH_STD`
	else
		LAST_MONTH_COUNT="N/A"
		LAST_MONTH_SUM="N/A"
		LAST_MONTH_AVERAGE="N/A"
		LAST_MONTH_STD="N/A"
		LAST_MONTH_MEDIAN="N/A"
		LAST_MONTH_MAX="N/A"
		LAST_MONTH_MIN="N/A"
		LAST_MONTH_STD="N/A"
	fi
	rm $TMPFILE

	LAST_MONTH_COUNT=`echo $LAST_MONTH_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_SUM=`echo $LAST_MONTH_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_AVERAGE=`echo $LAST_MONTH_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_STD=`echo $LAST_MONTH_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MEDIAN=`echo $LAST_MONTH_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MAX=`echo $LAST_MONTH_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	LAST_MONTH_MIN=`echo $LAST_MONTH_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/This Year now" ; date; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name $file` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR=`expr $TMP + $TODAY`
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG this year statistics" ; date ; fi
	# OK, this may not be 100% secure, but it's close enough for now
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/This Year now/statistics" ; date ; fi
	for FILE in  `find $TMP_YEAR/ -name $file` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "YEAR_COUNT=$n\nYEAR_SUM=$s\nYEAR_AVERAGE=$a\nYEAR_STD=$std\nYEAR_MEDIAN=$med\nYEAR_MAX=$m\nYEAR_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	YEAR_AVERAGE=`printf '%.2f' $YEAR_AVERAGE`
	YEAR_STD=`printf '%.2f' $YEAR_STD`


	YEAR_COUNT=`echo $YEAR_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_SUM=`echo $YEAR_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_AVERAGE=`echo $YEAR_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_STD=`echo $YEAR_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MEDIAN=`echo $YEAR_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MAX=`echo $YEAR_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	YEAR_MIN=`echo $YEAR_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
	TMP=0
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-in count_ssh_attacks/everything" ; date ; fi
	for FILE in  `find . -name $file` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL=`expr $TMP + $TODAY`
	# OK, this may not be 100% secure, but it's close enough for now
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG ALL  statistics" ; date; fi
	TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in count_ssh_attacks/everything/statistics" ; fi
	for FILE in  `find . -name $file` ; do cat $FILE; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "EVERYTHING_COUNT=$n\nEVERYTHING_SUM=$s\nEVERYTHING_AVERAGE=$a\nEVERYTHING_STD=$std\nEVERYTHING_MEDIAN=$med\nEVERYTHING_MAX=$m\nEVERYTHING_MIN=$mm";'  > $TMPFILE
	. $TMPFILE
	rm $TMPFILE
	EVERYTHING_AVERAGE=`printf '%.2f' $EVERYTHING_AVERAGE`
	EVERYTHING_STD=`printf '%.2f' $EVERYTHING_STD`

	EVERYTHING_COUNT=`echo $EVERYTHING_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_SUM=`echo $EVERYTHING_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_AVERAGE=`echo $EVERYTHING_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_STD=`echo $EVERYTHING_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MEDIAN=`echo $EVERYTHING_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MAX=`echo $EVERYTHING_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	EVERYTHING_MIN=`echo $EVERYTHING_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`


	#
	# Normalized data
	#
	if [ "x$HOSTNAME" == "x" ] ;then
		echo -n  "IN Normalized data, no hostname set " ; date
		# I have no idea where this breaks, but it's a big-ass number of files
		cd $HTML_DIR
		# OK, this may not be 100% secure, but it's close enough for now
		if [ $DEBUG  == 1 ] ; then echo "DEBUG ALL Normalized statistics" ; fi
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in  `find historical -name $file ` ; do if [ ! -e $FILE.notfullday ] ; then cat $FILE ; fi ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
		. $TMPFILE
		rm $TMPFILE
		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
	else
		echo -n "IN Normalized data, hostname was set " ; date
		# I have no idea where this breaks, but it's a big-ass number of files
		cd $HTML_DIR
		# OK, this may not be 100% secure, but it's close enough for now
		if [ $DEBUG  == 1 ] ; then echo "DEBUG Hostname only ALL  statistics" ; fi
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in  `find ./historical -name $file ` ; do if [ ! -e $FILE.notfullday ] ; then cat $FILE ; fi ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
		. $TMPFILE
		rm $TMPFILE
		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
	fi
	echo -n "Done with normalized data"; date

	NORMALIZED_COUNT=`echo $NORMALIZED_COUNT | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_SUM=`echo $NORMALIZED_SUM | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_AVERAGE=`echo $NORMALIZED_AVERAGE | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_STD=`echo $NORMALIZED_STD | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MEDIAN=`echo $NORMALIZED_MEDIAN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MAX=`echo $NORMALIZED_MAX | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	NORMALIZED_MIN=`echo $NORMALIZED_MIN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`

	DESCRIPTION=`echo $file |sed 's/_/ /g' |sed 's/\./ /g' |sed 's/todays//' |sed -r 's/\b(.)/\U\1/g' |sed 's/ Ips / IP Address /'`
	echo "<TABLE border=1><!--HEADERLINE --> " >> $outputfile
	echo "<TR><TH colspan=8>$DESCRIPTION</TH></TR><!--HEADERLINE --> "  >> $outputfile
	echo "<TR><TH>Time<BR>Frame</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Number<BR>of Days</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Count</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Average<BR>Per Day</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Std. Dev.</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Median</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Max</TH><!--HEADERLINE --> "  >> $outputfile
	echo "<TH>Min</TH><!--HEADERLINE --> "  >> $outputfile
	echo "</TR><!--HEADERLINE --> "  >> $outputfile

	echo "<TR><TD>So Far Today</TD><TD>1</TD><TD>$TODAY</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD></TR>"  >> $outputfile
	echo "<TR><TD>This Month</TD><TD> $MONTH_COUNT</TD><TD>N/A</TD><TD> $MONTH_AVERAGE</TD><TD> $MONTH_STD</TD><TD> $MONTH_MEDIAN</TD><TD> $MONTH_MAX</TD><TD> $MONTH_MIN"  >> $outputfile
	echo "<TR><TD>Last Month</TD><TD> $LAST_MONTH_COUNT</TD><TD>N/A</TD><TD> $LAST_MONTH_AVERAGE</TD><TD> $LAST_MONTH_STD</TD><TD> $LAST_MONTH_MEDIAN</TD><TD> $LAST_MONTH_MAX</TD><TD> $LAST_MONTH_MIN"  >> $outputfile
	echo "<TR><TD>This Year</TD><TD> $YEAR_COUNT</TD><TD>N/A</TD><TD> $YEAR_AVERAGE</TD><TD> $YEAR_STD</TD><TD> $YEAR_MEDIAN</TD><TD> $YEAR_MAX</TD><TD> $YEAR_MIN"  >> $outputfile
	echo "<TR><TD>Since Logging Started</TD><TD> $EVERYTHING_COUNT</TD><TD>N/A</TD><TD> $EVERYTHING_AVERAGE</TD><TD> $EVERYTHING_STD</TD><TD> $EVERYTHING_MEDIAN</TD><TD> $EVERYTHING_MAX</TD><TD> $EVERYTHING_MIN"  >> $outputfile
	echo "<TR><TD>Normalized Since Logging Started</TD><TD> $NORMALIZED_COUNT</TD><TD>N/A</TD><TD> $NORMALIZED_AVERAGE</TD><TD> $NORMALIZED_STD</TD><TD> $NORMALIZED_MEDIAN</TD><TD> $NORMALIZED_MAX</TD><TD> $NORMALIZED_MIN"  >> $outputfile
	echo ""  >> $outputfile
	echo "</TABLE><!--HEADERLINE -->"  >> $outputfile
}


############################################################################
# Current http attacks
#
# Called as http_attacks             $TMP_HTML_DIR $YEAR $PATH_TO_VAR_LOG DATE "messages*"
#
function http_attacks {
	local TMP_HTML_DIR=$1
	is_directory_good $TMP_HTML_DIR
	local YEAR=$2
	local PATH_TO_VAR_LOG=$3
	local DATE=$4
	local MESSAGES=$5
	local FILE_PREFIX=$6
	if [ $DEBUG  == 1 ] ; then echo "DEBUG TMP_HTML_DIR=$TMP_HTML_DIR, YEAR=$YEAR, PATH_TO_VARLOG=$PATH_TO_VAR_LOG, $DATE, MESSAGES=$MESSAGES, FILE_PREFIX=$FILE_PREFIX" ; fi

	#
	# I do a cd tp $PATH_TO_VAR_LOG to reduce the commandline length.  If the 
	# commandline is too long and breaks on your system due to there being 
	# way too many files in the directory, then you should probably be using
	# some other tool.
	local ORIGINAL_DIRECTORY=`pwd`
	cd $PATH_TO_VAR_LOG

	#
	# I hate making temporary files, but I have to so this doesn't take forever to run
	#

	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Making temp file now "  ;date; fi

	if [ "x$HOSTNAME" == "x/" ] ;then
		echo "hostname is not set"
		echo "PROTOCOL is $PROTOCOL"
		#
		# The sed expression is ugly and may not work everywhere and needs to be fixed
		#
		$SCRIPT_DIR/catall.sh $MESSAGES |grep $PROTOCOL |grep "$DATE"|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |grep -v xymonnet | sed 's/^....-..-..T.............. //' > $TMP_DIRECTORY/LongTail-messages.$$

		if [ $REBUILD  != 1 ] ; then
	 	/bin/cp $TMP_DIRECTORY/LongTail-messages.$$ $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages

			touch $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz
			/bin/rm $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz
			gzip $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages
			chmod 0000 $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz
	fi
	else
		echo "hostname IS set to $HOSTNAME."
		$SCRIPT_DIR/catall.sh $MESSAGES |grep $PROTOCOL |grep "$DATE"|awk '$1 == "'$HOSTNAME'" {print}'  | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |grep -v xymonnet | sed 's/^....-..-..T.............. //' > $TMP_DIRECTORY/LongTail-messages.$$
	fi # if [ "x$HOSTNAME" == "x/" ]

	#-------------------------------------------------------------------------
	# webpages requested
	#
	# This will get sped up when I convert this whole thing to perl in
	# Version 2.0
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-http_attack 1 " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-webpages.shtml" "Webpages Requested" " " "Count" "Webpage"

	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep  |sed 's/^..*\"GET\ /GET-/'| sed 's/^..*\"HEAD\ /HEAD-/'| sed 's/^..*\"POST\ /POST-/' | sed 's/^..*\"OPTIONS\ /OPTIONS-/'  | sed 's/^..*\"CONNECT\ /CONNECT-/'  | sed 's/^..*\"PROPFIND\ /PROPFIND-/'  |sed 's/ ..*$//'|sort |uniq -c |sort -nr |awk '{printf ("<TR><TD>%s</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-webpages.shtml


	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-webpages.shtml" "Top 20 Webpages" "" "Count" "Webpage"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-webpages.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-webpages.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-webpages.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-webpages.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-webpages.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-webpages.data

	#-------------------------------------------------------------------------
	# shellshock webpages requested
	#
	# This will get sped up when I convert this whole thing to perl in
	# Version 2.0
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-http_attack 1 " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-shellshock.shtml" "Shellshock Attacks" " " "Count" "Webpage"

	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep | grep \:\; |sed 's/^..*\"GET\ /GET-/'| sed 's/^..*\"HEAD\ /HEAD-/'| sed 's/^..*\"POST\ /POST-/' | sed 's/^..*\"OPTIONS\ /OPTIONS-/'  | sed 's/^..*\"CONNECT\ /CONNECT-/'  | sed 's/^..*\"PROPFIND\ /PROPFIND-/'  |sort |uniq -c |sort -nr |\
sed 's/^ *//'  | sed 's/^/<TR><TD>/' |sed 's/ /<\/TD><TD>/' |sed 's/$/<\/TD><\/TR>/' >> $TMP_HTML_DIR/$FILE_PREFIX-shellshock.shtml

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock.shtml" "Top 20 Webpages" "" "Count" "Webpage"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-shellshock.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-shellshock.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-shellshock.data


	#-------------------------------------------------------------------------
	# wget webpages requested
	#
	# This will get sped up when I convert this whole thing to perl in
	# Version 2.0
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-http_attack 1 " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-wget.shtml" "wget requests" " " "Count" "Webpage"

	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep | grep wget\  |sed 's/^..*\"GET\ /GET-/'| sed 's/^..*\"HEAD\ /HEAD-/'| sed 's/^..*\"POST\ /POST-/' | sed 's/^..*\"OPTIONS\ /OPTIONS-/'  | sed 's/^..*\"CONNECT\ /CONNECT-/'  | sed 's/^..*\"PROPFIND\ /PROPFIND-/'  |sort |uniq -c |sort -nr |\
sed 's/^ *//'  | sed 's/^/<TR><TD>/' |sed 's/ /<\/TD><TD>/' |sed 's/$/<\/TD><\/TR>/' >> $TMP_HTML_DIR/$FILE_PREFIX-wget.shtml

	echo "#!/bin/sh" > $TMP_HTML_DIR/$FILE_PREFIX-wget.sh
	echo "cd $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/malware" >> $TMP_HTML_DIR/$FILE_PREFIX-wget.sh
	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep | grep wget\  |sed 's/^..*wget //'|sed 's/;.*$//' |sed 's/ ..*$//' |sed 's/^/wget /'|sed 's/>.*$//' |sed 's/<.*$//'  |sort |uniq |sort -nr  >> $TMP_HTML_DIR/$FILE_PREFIX-wget.sh

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-wget.shtml" "Top 20 Webpages" "" "Count" "Webpage"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-wget.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-wget.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-wget.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-wget.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-wget.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-wget.data


	#-------------------------------------------------------------------------
	# 404 webpages requested
	#
	# This will get sped up when I convert this whole thing to perl in
	# Version 2.0
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-http_attack 1 " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-404.shtml" "404 Pages Requested " " " "Count" "Webpage"

	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep -vf $SCRIPT_DIR/LongTail-exclude-webpages.grep | grep \ 404\  |sed 's/^..*\"GET\ /GET-/'| sed 's/^..*\"HEAD\ /HEAD-/'| sed 's/^..*\"POST\ /POST-/' | sed 's/^..*\"OPTIONS\ /OPTIONS-/'  | sed 's/^..*\"CONNECT\ /CONNECT-/'  | sed 's/^..*\"PROPFIND\ /PROPFIND-/'  |sort |uniq -c |sort -nr |\
sed 's/^ *//'  | sed 's/^/<TR><TD>/' |sed 's/ /<\/TD><TD>/' |sed 's/$/<\/TD><\/TR>/' >> $TMP_HTML_DIR/$FILE_PREFIX-404.shtml

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-404.shtml" "Top 20 Webpages" "" "Count" "Webpage"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-404.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-404.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-404.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-404.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-404.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-404.data



	#-------------------------------------------------------------------------
	# This works but gives only IP addresses
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-http_attack 5 " ; date ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml" "IP Addresses" " " "Count" "IP Address" "Country" "WhoIS" "Blacklisted" "Attack Patterns"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml" "Top 20 IP Addresses" " " "Count" "IP Address" "Country" "WhoIS" "Blacklisted" "Attack Patterns"
	# I need to make a temp file for this

# I am now doing this for all hosts so that each host can have it's own image map
# and (more importantly) each hosts index.shtml can be a copy/paste of the main
# index.shtml
	if [ "x$HOSTNAME" == "x/" ] ;then
echo "DEBUG writing to $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt"
		echo "# http://longtail.it.marist.edu "> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# This is a sorted list of IP addresses that have tried to login" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# to a server related to LongTail." >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# LEGAL DISCLAIMER" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# This list is provided for research only.  We do not recommend or" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# suggest importing this list into fail2ban, denyhosts, or any" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# other tool that might block access." >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# The format of the data is number of times seen, followed by the IP address" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		RIGHT_NOW=`date`
		echo "# This list was created on: $RIGHT_NOW" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		cat $TMP_DIRECTORY/LongTail-messages.$$  | awk '{print $3}' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		mv $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp
echo "Calling LongTail_add_country_to_ip.pl"
		$SCRIPT_DIR/LongTail_add_country_to_ip.pl $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp > $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
echo "Calling LongTail_make_map.pl"
		$SCRIPT_DIR/LongTail_make_map.pl $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt > $TMP_HTML_DIR/$FILE_PREFIX-map.html
		rm $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp
	fi

	#
	# Code to try and add the country to the ip-addresses.shtml page
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-http_attack 5a " ; date ; fi
	cat $TMP_DIRECTORY/LongTail-messages.$$  | awk '{print $3}' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr   > $TMP_DIRECTORY/Longtail.tmpIP.$$

	cat $TMP_DIRECTORY/Longtail.tmpIP.$$ | /usr/local/etc/LongTail_add_country_to_ip.pl > $TMP_DIRECTORY/Longtail.tmpIP.$$-2 # Delete this line once the code works

	cat $TMP_DIRECTORY/Longtail.tmpIP.$$-2 | awk '{printf("<TR><TD>%d</TD><TD>%s</TD><TD>%s</TD><TD><a href=\"http://whois.urih.com/record/%s\">Whois lookup</A></TD><TD><a href=\"http://www.dnsbl-check.info/?checkip=%s\">Blacklisted?</A></TD><TD><a href=\"/HONEY/ip_attacks.shtml#%s\">Attack Patterns</A></TD></TR>\n",$1,$2,$3,$2,$2,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml

	rm $TMP_DIRECTORY/Longtail.tmpIP.$$
	rm $TMP_DIRECTORY/Longtail.tmpIP.$$-2

	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-http_attack 5b " ; date ; fi
	sed -i s/HONEY/$HTML_TOP_DIR/g $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml

	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml |head -20 |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml"

	#-------------------------------------------------------------------------
	# This translates IPs to countries
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-http_attack 6, doing whois.pl lookups " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml" "Attacks by Country" " " "Count" "Country"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml" "Top 20 Countries" " " "Count" "Country"
	# I need to make a temp file for this


#WHOIS.PL

	for IP in `cat $TMP_DIRECTORY/LongTail-messages.$$  | awk '{print $3}' |uniq |sort -T $TMP_DIRECTORY -u `; do   if [ "x${IP_ADDRESS[$IP]}" == "x" ] ; then $SCRIPT_DIR/whois.pl $IP ; else echo "Country: ${IP_ADDRESS[$IP]}"; fi  |grep -i country|head -1|sed 's/:/: /g' ; done | awk '{print $NF}' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml


	sed -i -f $SCRIPT_DIR/translate_country_codes.sed  $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml"
	
	#-------------------------------------------------------------------------
	# Figuring out http-attacks-by-time-of-day
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-http_attack 7B Figuring out http-attacks-by-time-of-day " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-http-attacks-by-time-of-day.shtml" "Historical SSH Attacks By Time Of Day" "" "Count" "Hour of Day"
	cat $TMP_DIRECTORY/LongTail-messages.$$ | awk '{print $6}'| awk -F: '{print $2}' | sort -T $TMP_DIRECTORY |uniq -c| awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-http-attacks-by-time-of-day.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-http-attacks-by-time-of-day.shtml"

	#-------------------------------------------------------------------------
	# raw data compressed 
	# This only prints the account and the password
	# This is different from the temp file I make earlier as it does
	# a grep for both Password AND password (Note the capitalization differences).
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-http_attack 8, gathering data for raw-data.gz " ; date; fi
	if [ $FILE_PREFIX == "current" ] ;
	then
	
		if [ $OBFUSCATE_IP_ADDRESSES -gt 0 ] ; then
			cat $TMP_DIRECTORY/LongTail-messages.$$  |sed -r 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)[0-9]{1,3}/\1127/g'  |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
		else
			cat $TMP_DIRECTORY/LongTail-messages.$$ |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
		fi
		# Code do avoid doing this if REBUILD is set
		if [ $REBUILD  != 1 ] ; then
			echo "REBUILD NOT SET, copying .gz file now"
			# Lets make sure we have one for today and this month and this year
			# I added this code on 2015-03-17, Lets see if it breaks anything...
			TMP_YEAR=`date +%Y`
			TMP_MONTH=`date +%m`
			TMP_DAY=`date +%d`
	
			TMP_DIR="$TMP_HTML_DIR"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			cp $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
			chmod a+r $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
			for dir in $HOSTS_PROTECTED ; do
				if [ "x$HOSTNAME" == "x$dir" ] ; then
					touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
					echo $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
				fi
			done
		else
			echo "REBUILD SET, NOT copying .gz file now"
		fi 
	fi


	if [ $DEBUG == 1 ] ; then echo -n "Wrote to $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz "; date ;fi
	#
	# I only need the count data for today, so there's no point counting 7, 30, or historical
	#
	if [ $FILE_PREFIX == "current" ] ;
	then
		TODAY=`$SCRIPT_DIR/catall.sh $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz  |grep $PROTOCOL | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`
		echo $TODAY > $TMP_HTML_DIR/$FILE_PREFIX-attack-count.data
	fi

	#
	# read and run any LOCALLY WRITTEN reports
	#
	#if [ $DEBUG == 1 ] ; then echo "Running http-local-reports"; fi
	#. $SCRIPT_DIR/Longtail-http-local-reports

	# cd back to the original directory.  this should be the last command in 
	# the function.
	cd $ORIGINAL_DIRECTORY
	rm $TMP_DIRECTORY/LongTail-messages.$$
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Done with http_attack " ; date; fi
	date > $TMP_HTML_DIR/date_updated.txt

}
############################################################################
# Current ssh attacks
#
# Called as ssh_attacks             $TMP_HTML_DIR $YEAR $PATH_TO_VAR_LOG DATE "messages*"
#
function ssh_attacks {
	local TMP_HTML_DIR=$1
	is_directory_good $TMP_HTML_DIR
	local YEAR=$2
	local PATH_TO_VAR_LOG=$3
	local DATE=$4
	local MESSAGES=$5
	local FILE_PREFIX=$6
#DEBUG=1
	if [ $DEBUG  == 1 ] ; then echo "DEBUG TMP_HTML_DIR=$TMP_HTML_DIR, YEAR=$YEAR, PATH_TO_VARLOG=$PATH_TO_VAR_LOG, $DATE, MESSAGES=$MESSAGES, FILE_PREFIX=$FILE_PREFIX" ; fi

	#
	# I do a cd tp $PATH_TO_VAR_LOG to reduce the commandline length.  If the 
	# commandline is too long and breaks on your system due to there being 
	# way too many files in the directory, then you should probably be using
	# some other tool.
	local ORIGINAL_DIRECTORY=`pwd`
	cd $PATH_TO_VAR_LOG

	#
	# I hate making temporary files, but I have to so this doesn't take forever to run
	#
	# NOTE: Sometimes attackers use a malformed attack and don't specify
	# a username, so I am changing the Username field to NO-USERNAME-PROVIDED those attacks now
	# Example: 2015-02-26T12:46:40.500085-05:00 shepherd sshd-2222[28001]: IP: 107.150.35.218 Pass2222Log: Username:  Password: qwe123
	# So we grep out Username:\ \  so my reports work
	# It took 55 days for this bug to show up

	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Making temp file now "  ;date; fi

	if [ "x$HOSTNAME" == "x/" ] ;then
		echo "hostname is not set"
echo "PROTOCOL is $PROTOCOL"
		if [ $LONGTAIL -eq 1 ] ; then
#echo "DEBUG Making tmp file $TMP_DIRECTORY/LongTail-messages.$$ now"
			$SCRIPT_DIR/catall.sh $MESSAGES |grep $PROTOCOL |grep "$DATE"|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep | grep Password |sed 's/Username:\ \ /Username: NO-USERNAME-PROVIDED /'  > $TMP_DIRECTORY/LongTail-messages.$$
		fi
		if [ $KIPPO -eq 1 ] ; then
			$SCRIPT_DIR/catall.sh $MESSAGES |grep ssh |grep "$DATE"|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep | grep login\ attempt | sed -e 's/ /T/' \
  -e 's/.SSHService ssh-userauth on HoneyPotTransport,.*,//' \
  -e 's/\]/ /' \
  -e 's/\] failed$//' \
  -e 's/\[//' \
  -e 's/ / LOCALHOST sshd-22[9999]: IP: /' \
  -e 's/login attempt/PassLog: Username:/' \
  -e 's/\// Password: /' \
  > $TMP_DIRECTORY/LongTail-messages.$$
ls -l $TMP_DIRECTORY/LongTail-messages.$$
		fi


		if [ $REBUILD  != 1 ] ; then
			$SCRIPT_DIR/catall.sh $MESSAGES | grep ssh |grep "$DATE"  > $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages

			touch $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz
			/bin/rm $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz
			gzip $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages
			chmod 0000 $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz
		fi
	else
		echo "hostname IS set to $HOSTNAME."
		$SCRIPT_DIR/catall.sh $MESSAGES |awk '$2 == "'$HOSTNAME'" {print}' |grep $PROTOCOL |grep "$DATE"|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep | grep Password |sed 's/Username:\ \ /Username: NO-USERNAME-PROVIDED /'  > $TMP_DIRECTORY/LongTail-messages.$$
	fi

	#-------------------------------------------------------------------------
	# Root
	#
	# This takes longer to run than "admin" passwords because there are so 
	# many more root passwords to look at.
	#
	# This will get sped up when I convert this whole thing to perl in
	# Version 2.0
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-ssh_attack 1 " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml" "Root Passwords" " " "Count" "Password"

	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep Username\:\ root |\
	sed 's/^..*Password: //'|sed 's/^..*Password:$/ /' | sed 's/ /\&nbsp;/g'|\
	sort -T $TMP_DIRECTORY |uniq -c|sort -T $TMP_DIRECTORY -nr |\
	awk '{printf("<TR><TD>%d</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">%s</a> </TD></TR>\n",$1,$2,$2)}' \
	>> $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml" "Top 20 Root Passwords" "" "Count" "Password"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.data

	touch $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml.gz
	/bin/rm $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml.gz
	gzip $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml



	#-------------------------------------------------------------------------
	# admin
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 2 "  ;date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml" "Admin Passwords" " " "Count" "Password"
	cat $TMP_DIRECTORY/LongTail-messages.$$ |grep Username\:\ admin |\
	sed 's/^..*Password: //'|sed 's/^..*Password:$/ /' |sed 's/ /\&nbsp;/g'|\
	sort -T $TMP_DIRECTORY |uniq -c|sort -T $TMP_DIRECTORY -nr |\
	awk '{printf("<TR><TD>%d</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">%s</a> </TD></TR>\n",$1,$2,$2)}'\
	>> $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml" "Top 20 Admin Passwords" " " "Count" "Password"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.data


	#-------------------------------------------------------------------------
	# Not root or admin PASSWORDS
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 3 "  ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml" "Non Root Passwords" " " "Count" "Password"

	cat $TMP_DIRECTORY/LongTail-messages.$$ |egrep -v Username\:\ root\ \|Username\:\ admin\  |\
	sed 's/^..*Password: //'|sed 's/^..*Password:$/ /'  | sed 's/ /\&nbsp;/g'|\
	sort -T $TMP_DIRECTORY |uniq -c|sort -T $TMP_DIRECTORY -nr |\
	awk '{printf("<TR><TD>%d</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">%s</a> </TD></TR>\n",$1,$2,$2)}'\
	>> $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml

	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml" "Top 20 Non Root Passwords" " " "Count" "Password"
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml | head -20  >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml"
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD><a..*34">/ /' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.data
	

	#-------------------------------------------------------------------------
	# Not root or admin ACCOUNTS
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 4 " ;date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml" "Accounts Tried" " " "Count" "Account"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml" "Top 20 Accounts Tried" "" "Count" "Account"
	cat $TMP_DIRECTORY/LongTail-messages.$$ |\
	sed 's/^..*Username: //' |sed 's/ Password:.*//' |\
	sort -T $TMP_DIRECTORY |uniq -c|sort -T $TMP_DIRECTORY -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml

	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml | head -20   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml
	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml | head -21 |grep -v '<TD>root<.TD>'  > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts-real.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml"

	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD>/ /'|sed 's/<.TD><.TR>//' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.data
	cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts-real.shtml |grep -v HEADERLINE|sed -r 's/^<TR><TD>//' |sed 's/<.a> <.TD><.TR>//' |sed 's/<.TD><TD>/ /'|sed 's/<.TD><.TR>//' |grep -v ^$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts-real.data
	
	#-------------------------------------------------------------------------
	# This works but gives only IP addresses
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 5 " ; date ; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml" "IP Addresses" " " "Count" "IP Address" "Country" "WhoIS" "Blacklisted" "Attack Patterns"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml" "Top 20 IP Addresses" " " "Count" "IP Address" "Country" "WhoIS" "Blacklisted" "Attack Patterns"
	# I need to make a temp file for this

# I am now doing this for all hosts so that each host can have it's own image map
# and (more importantly) each hosts index.shtml can be a copy/paste of the main
# index.shtml
#	if [ "x$HOSTNAME" == "x/" ] ;then
#echo "DEBUG writing to $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt"
		echo "# http://longtail.it.marist.edu "> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# This is a sorted list of IP addresses that have tried to login" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# to a server related to LongTail." >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# LEGAL DISCLAIMER" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# This list is provided for research only.  We do not recommend or" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# suggest importing this list into fail2ban, denyhosts, or any" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# other tool that might block access." >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# The format of the data is number of times seen, followed by the IP address" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		RIGHT_NOW=`date`
		echo "# This list was created on: $RIGHT_NOW" >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		echo "# " >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		cat $TMP_DIRECTORY/LongTail-messages.$$  | grep IP: |grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | sed 's/^.*IP: //'|sed 's/ Pass..*$//' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
		mv $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp
		$SCRIPT_DIR/LongTail_add_country_to_ip.pl $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp > $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt
#echo "DEBUG writing map include file to $TMP_HTML_DIR/$FILE_PREFIX-map.html"
		$SCRIPT_DIR/LongTail_make_map.pl $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt > $TMP_HTML_DIR/$FILE_PREFIX-map.html
		rm $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp
#	fi

	#
	# Code to try and add the country to the ip-addresses.shtml page
	cat $TMP_DIRECTORY/LongTail-messages.$$  | grep IP: |grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | sed 's/^.*IP: //'|sed 's/ Pass..*$//' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr   > $TMP_DIRECTORY/Longtail.tmpIP.$$

	cat $TMP_DIRECTORY/Longtail.tmpIP.$$ | /usr/local/etc/LongTail_add_country_to_ip.pl > $TMP_DIRECTORY/Longtail.tmpIP.$$-2 # Delete this line once the code works

	cat $TMP_DIRECTORY/Longtail.tmpIP.$$-2 | awk '{printf("<TR><TD>%d</TD><TD>%s</TD><TD>%s</TD><TD><a href=\"http://whois.urih.com/record/%s\">Whois lookup</A></TD><TD><a href=\"http://www.dnsbl-check.info/?checkip=%s\">Blacklisted?</A></TD><TD><a href=\"/HONEY/ip_attacks.shtml#%s\">Attack Patterns</A></TD></TR>\n",$1,$2,$3,$2,$2,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml

	rm $TMP_DIRECTORY/Longtail.tmpIP.$$
	rm $TMP_DIRECTORY/Longtail.tmpIP.$$-2

	sed -i s/HONEY/$HTML_TOP_DIR/g $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml

	grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml |head -20 |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml"

	#-------------------------------------------------------------------------
	# This translates IPs to countries
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 6, doing whois.pl lookups " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml" "Attacks by Country" " " "Count" "Country"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml" "Top 20 Countries" " " "Count" "Country"
	# I need to make a temp file for this


#WHOIS.PL

	for IP in `cat $TMP_DIRECTORY/LongTail-messages.$$  |grep IP: | awk '{print $5}' |uniq |sort -T $TMP_DIRECTORY -u `; do   if [ "x${IP_ADDRESS[$IP]}" == "x" ] ; then $SCRIPT_DIR/whois.pl $IP ; else echo "Country: ${IP_ADDRESS[$IP]}"; fi  |grep -i country|head -1|sed 's/:/: /g' ; done | awk '{print $NF}' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml

	sed -i -f $SCRIPT_DIR/translate_country_codes.sed  $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml
	tail -20 $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml"
	
	#-------------------------------------------------------------------------
	# Figuring out most common non-root pairs
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 7 Figuring out most common non-root pairs " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml" "Non Root Pairs" " " "Count" "Account:Password"
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs.shtml" "Top 20 Non Root Pairs" " " "Count" "Account:Password"

	if [ $FILE_PREFIX == "current" ] ;
	then
		if [ $DEBUG  == 1 ] ; then 
			echo "DEBUG current non-root-pairs"
			echo "DATE is $DATE"
		fi
		cat $TMP_DIRECTORY/LongTail-messages.$$ |egrep -v Username\:\ root\ \|Username\:\ admin\  |\
		awk -F'Username: ' '/Username/{print $2}' | sed 's/ Password: /:/' |sed 's/ /\&nbsp;/g'|\
		sort -T $TMP_DIRECTORY |uniq -c|sort -T $TMP_DIRECTORY -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' \
		>> $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml

		cat $TMP_DIRECTORY/LongTail-messages.$$ |\
		awk -F'Username: ' '/Username/{print $2}' | sed 's/ Password: /:/' |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-account-password-pairs.data.gz
	else
		if [ $DEBUG  == 1 ] ; then 
			echo "DEBUG Non-current non-root-pairs"
			echo "DATE is $DATE"
		fi
		cat $TMP_DIRECTORY/LongTail-messages.$$ |egrep -v Username\:\ root\ \|Username\:\ admin\  |\
		awk -F'Username: ' '/Username/{print $2}' | sed 's/ Password: /:/'|sed 's/ /\&nbsp;/g'|\
		sort -T $TMP_DIRECTORY |uniq -c|sort -T $TMP_DIRECTORY -nr | awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' \
		>> $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml
	fi

	cat  $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml |grep -v HEADERLINE |head -20 >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs.shtml

	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml"
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs.shtml"

	#-------------------------------------------------------------------------
	# Figuring out ssh-attacks-by-time-of-day
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 7B Figuring out ssh-attacks-by-time-of-day " ; date; fi
	make_header "$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day.shtml" "Historical SSH Attacks By Time Of Day" "" "Count" "Hour of Day"
	cat $TMP_DIRECTORY/LongTail-messages.$$ | grep Password | awk '{print $1}'| awk -FT '{print $2}' | awk -F: '{print $1}' |sort -T $TMP_DIRECTORY |uniq -c| awk '{printf("<TR><TD>%d</TD><TD>%s</TD></TR>\n",$1,$2)}' >> $TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day.shtml
	make_footer "$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day.shtml"

	#-------------------------------------------------------------------------
	# raw data compressed 
	# This only prints the account and the password
	# This is different from the temp file I make earlier as it does
	# a grep for both Password AND password (Note the capitalization differences).
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-ssh_attack 8, gathering data for raw-data.gz " ; date; fi
	if [ $FILE_PREFIX == "current" ] ;
	then
	
		if [ $OBFUSCATE_IP_ADDRESSES -gt 0 ] ; then
			cat $TMP_DIRECTORY/LongTail-messages.$$  |sed -r 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)[0-9]{1,3}/\1127/g'  |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
		else
			cat $TMP_DIRECTORY/LongTail-messages.$$ |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
		fi
		# Code do avoid doing this if REBUILD is set
		if [ $REBUILD  != 1 ] ; then
			echo "REBUILD NOT SET, copying .gz file now"
			# Lets make sure we have one for today and this month and this year
			# I added this code on 2015-03-17, Lets see if it breaks anything...
			TMP_YEAR=`date +%Y`
			TMP_MONTH=`date +%m`
			TMP_DAY=`date +%d`
	
			TMP_DIR="$TMP_HTML_DIR"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY"
			if [ ! -d $TMP_DIR  ] ; then mkdir $TMP_DIR ; chmod a+rx $TMP_DIR; fi
			cp $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
			chmod a+r $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz
			for dir in $HOSTS_PROTECTED ; do
				if [ "x$HOSTNAME" == "x$dir" ] ; then
					touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
					echo $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
				fi
			done
		else
			echo "REBUILD SET, NOT copying .gz file now"
		fi 
	fi


	if [ $DEBUG == 1 ] ; then echo -n "Wrote to $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz "; date ;fi
	#
	# I only need the count data for today, so there's no point counting 7, 30, or historical
	#
	if [ $FILE_PREFIX == "current" ] ;
	then
		TODAY=`$SCRIPT_DIR/catall.sh $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz  |grep $PROTOCOL | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`
		echo $TODAY > $TMP_HTML_DIR/$FILE_PREFIX-attack-count.data
	fi

	#
	# read and run any LOCALLY WRITTEN reports
	#
	if [ $DEBUG == 1 ] ; then echo "Running ssh-local-reports"; fi
	if [ -x $SCRIPT_DIR/Longtail-ssh-local-reports ] ; then
		. $SCRIPT_DIR/Longtail-ssh-local-reports
	fi

	# cd back to the original directory.  this should be the last command in 
	# the function.
	cd $ORIGINAL_DIRECTORY
	rm $TMP_DIRECTORY/LongTail-messages.$$
	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-Done with ssh_attack " ; date; fi
	date > $TMP_HTML_DIR/date_updated.txt

}

function make_http_trends {
	if [ $START_HOUR -eq $MIDNIGHT ]; then
	#if [ $START_HOUR -eq 19 ]; then
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends" ; fi
		#-----------------------------------------------------------------
		# Now lets do some long term ssh reports....  Lets do a comparison of 
		# top 20 non-root-passwords and top 20 root passwords
		#-----------------------------------------------------------------
		cd $HTML_DIR/historical 
		make_header "$HTML_DIR/trends-in-webpages.shtml" "Trends In Webpages Requested From Most Common To 20th"  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
		
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-webpages" ; fi
		for FILE in `find . -name 'current-top-20-webpages.shtml'|sort -T $TMP_DIRECTORY -nr ` ; do  
			echo "<TR>";echo -n "<TD>"; \
			echo -n "$FILE $FILE"  |\
			sed 's/current-top-20-webpages.shtml//g' |\
			sed 's/\.\///g' |\
			sed 's/^/<A HREF=\"historical\//' |\
			sed 's/\/ /\/\">/' |\
			sed 's/$/ <\/a>/'  ;\
			echo "</TD>"; grep TR $FILE |\
			grep -v HEADERLINE | \
			sed 's/<TR><TD>/<TD>/' |sed 's/<title>//i'|sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done >> $TMPFILE
	
		#
		# code to color code NEW entries
		#
		tac $TMPFILE  |\
		perl -e ' while (<>){
		if (/<A HREF="historical/){print; next;}
		if (/^<TD/){
			$line=$_;
			$tmp_line=$_;
			$tmp_line =~ s/^..*">//;
			$tmp_line =~ s/<\/a>.*$//;
			($trash,$tmp_line) = split (/:/,$tmp_line,2);
			
			if (defined $password{"$tmp_line"}){
				print $line;
			}
			else {
				$line =~ s/<TD/<TD bgcolor=#FF0000/;
				$password{"$tmp_line"}=1;
				print $line;
			}
		}
		else {
			print;
		}
		}' |tac >> $HTML_DIR/trends-in-webpages.shtml
		rm $TMPFILE
	
		make_footer "$HTML_DIR/trends-in-webpages.shtml"
		sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-webpages.shtml
	
		cd $HTML_DIR/historical 
	fi
}
function make_trends {	
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends" ; fi
		#-----------------------------------------------------------------
		# Now lets do some long term ssh reports....  Lets do a comparison of 
		# top 20 non-root-passwords and top 20 root passwords
		#-----------------------------------------------------------------
		cd $HTML_DIR/historical 
		make_header "$HTML_DIR/trends-in-non-root-passwords.shtml" "Trends In Non Root Passwords From Most Common To 20th"  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
		
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-non-root-passwords" ; fi
		for FILE in `find . -name 'current-top-20-non-root-passwords.shtml'|sort -T $TMP_DIRECTORY -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
			echo -n "$FILE $FILE"  |\
			sed 's/current-top-20-non-root-passwords.shtml//g' |\
			sed 's/\.\///g' |\
			sed 's/^/<A HREF=\"historical\//' |\
			sed 's/\/ /\/\">/' |\
			sed 's/$/ <\/a>/' ; \
			echo "</TD>"; grep TR $FILE |\
			grep -v HEADERLINE | \
			sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done >> $TMPFILE
	
		#
		# code to color code NEW entries
		#
		tac $TMPFILE  |\
		perl -e ' while (<>){
		if (/<A HREF="historical/){print; next;}
		if (/^<TD/){
			$line=$_;
			$tmp_line=$_;
			$tmp_line =~ s/^..*">//;
			$tmp_line =~ s/<\/a>.*$//;
			
			if (defined $password{"$tmp_line"}){
				print $line;
			}
			else {
				$line =~ s/<TD/<TD bgcolor=#FF0000/;
				$password{"$tmp_line"}=1;
				print $line;
			}
		}
		else {
			print;
		}
		}' |tac >> $HTML_DIR/trends-in-non-root-passwords.shtml
		rm $TMPFILE
	
		make_footer "$HTML_DIR/trends-in-non-root-passwords.shtml"
		sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-non-root-passwords.shtml
		
	
		#-----------------------------------------------------------------
		cd $HTML_DIR/historical 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-root-passwords" ; fi
		make_header "$HTML_DIR/trends-in-root-passwords.shtml" "Trends In Root Passwords From Most Common To 20th"  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
	
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in `find . -name 'current-top-20-root-passwords.shtml'|sort -T $TMP_DIRECTORY -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
			echo -n "$FILE $FILE" |\
			sed 's/current-top-20-root-passwords.shtml//g'|\
			sed 's/\.\///g' |\
			sed 's/^/<A HREF=\"historical\//' |\
			sed 's/\/ /\/\">/' |\
			sed 's/$/ <\/a>/' ; \
			echo "</TD>"; grep TR $FILE |\
			grep -v HEADERLINE   |\
			sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done >> $TMPFILE
	
		#
		# code to color code NEW entries
		#
		tac $TMPFILE  |\
		perl -e ' while (<>){
		if (/<A HREF="historical/){print; next;}
		if (/^<TD/){
			$line=$_;
			$tmp_line=$_;
			$tmp_line =~ s/^..*">//;
			$tmp_line =~ s/<\/a>.*$//;
			
			if (defined $password{"$tmp_line"}){
				print $line;
			}
			else {
				$line =~ s/<TD/<TD bgcolor=#FF0000/;
				$password{"$tmp_line"}=1;
				print $line;
			}
		}
		else {
			print;
		}
		}' |tac >> $HTML_DIR/trends-in-root-passwords.shtml
		rm $TMPFILE
		
		make_footer "$HTML_DIR/trends-in-root-passwords.shtml"
		sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-root-passwords.shtml
		cd $HTML_DIR/historical 
		
		#-----------------------------------------------------------------
		cd $HTML_DIR/historical 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-admin-passwords" ; fi
	
		make_header "$HTML_DIR/trends-in-admin-passwords.shtml" "Trends In Admin Passwords From Most Common To 20th"  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
		
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in `find . -name 'current-top-20-admin-passwords.shtml'|sort -T $TMP_DIRECTORY -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
			echo -n "$FILE $FILE" |\
			sed 's/current-top-20-admin-passwords.shtml//g'|\
			sed 's/\.\///g' |\
			sed 's/^/<A HREF=\"historical\//' |\
			sed 's/\/ /\/\">/' |\
			sed 's/$/ <\/a>/' ; \
			echo "</TD>"; grep TR $FILE |\
			grep -v HEADERLINE   |\
			sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done  >> $TMPFILE
	
		#
		# code to color code NEW entries
		#
		tac $TMPFILE  |\
		perl -e ' while (<>){
		if (/<A HREF="historical/){print; next;}
		if (/^<TD/){
			$line=$_;
			$tmp_line=$_;
			$tmp_line =~ s/^..*">//;
			$tmp_line =~ s/<\/a>.*$//;
			
			if (defined $password{"$tmp_line"}){
				print $line;
			}
			else {
				$line =~ s/<TD/<TD bgcolor=#FF0000/;
				$password{"$tmp_line"}=1;
				print $line;
			}
		}
		else {
			print;
		}
		}' |tac >> $HTML_DIR/trends-in-admin-passwords.shtml
		rm $TMPFILE
		
		make_footer "$HTML_DIR/trends-in-admin-passwords.shtml"
		sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-admin-passwords.shtml
		cd $HTML_DIR/historical 
	
		#-----------------------------------------------------------------
		cd $HTML_DIR/historical 
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing trends-in-Accounts" ; fi
	
		make_header "$HTML_DIR/trends-in-accounts.shtml" "Trends In Accounts Tried From Most Common To 20th"  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20." "Date" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20"
		
		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
		for FILE in `find . -name 'current-top-20-non-root-accounts.shtml'|sort -T $TMP_DIRECTORY -nr ` ; do  echo "<TR>";echo -n "<TD>"; \
			echo -n "$FILE $FILE" |\
			sed 's/current-top-20-non-root-accounts.shtml//g'|\
			sed 's/\.\///g' |\
			sed 's/^/<A HREF=\"historical\//' |\
			sed 's/\/ /\/\">/' |\
			sed 's/$/ <\/a>/' ; \
			echo "</TD>"; grep TR $FILE |\
			grep -v HEADERLINE   |\
			sed 's/<TR><TD>/<TD>/' |sed 's/<.TD><TD>/:/' |sed 's/<.TR>//'; echo "</TR>" ; done  >> $TMPFILE
	
		#
		# code to color code NEW entries
		#
		tac $TMPFILE  |\
		perl -e ' while (<>){
		if (/<A HREF="historical/){print; next;}
		if (/^<TD/){
			$line=$_;
			$tmp_line=$_;
			$tmp_line =~ s/^..*">//;
			$tmp_line =~ s/<\/a>.*$//;
			$tmp_line=~ s/^.*://;
			$tmp_line=~ s/<.*$//;
	
			
			if (defined $password{"$tmp_line"}){
				print $line;
			}
			else {
				$line =~ s/<TD/<TD bgcolor=#FF0000/;
				$password{"$tmp_line"}=1;
				print $line;
			}
		}
		else {
			print;
		}
		}' |tac >> $HTML_DIR/trends-in-accounts.shtml
		rm $TMPFILE
		
		make_footer "$HTML_DIR/trends-in-accounts.shtml"
		sed -i 's/<TD>/<TD class="td-some-name">/g' $HTML_DIR/trends-in-accounts.shtml
		cd $HTML_DIR/historical 
	fi
}


############################################################################
#
# Example input line: 

function do_http {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in do_http now" ; fi
	if [ ! -d $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/malware ] ; then
		mkdir $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/malware
	fi
	#-----------------------------------------------------------------
	# Lets count the http attacks
	count_http_attacks $HTML_DIR $PATH_TO_VAR_LOG "$LOGFILE*"
	
	#----------------------------------------------------------------
	# Lets check the http logs
	http_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG "$DATE"  "$LOGFILE*" "current"
	
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in do_http/last7,30,historical  now" ; fi
		#----------------------------------------------------------------
		# Lets check the http logs for the last 7 days
		LAST_WEEK="/dev/null "
		for i in 1 2 3 4 5 6 7 ; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			if [ -e "$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz" ] ; then
			if [ "$LAST_WEEK" == "" ] ; then
				LAST_WEEK="$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			else
				LAST_WEEK="$LAST_WEEK $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			fi
			fi
		done
		TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG
		http_attacks $HTML_DIR $YEAR "/" "."      "$LAST_WEEK" "last-7-days"
		PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG
	
		#----------------------------------------------------------------
		# Lets check the http logs for the last 30 days
		LAST_MONTH="/dev/null "
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			if [ -e "$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz" ] ; then
			if [ "$LAST_MONTH" == "" ] ; then
				LAST_MONTH="$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			else
				LAST_MONTH="$LAST_MONTH $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			fi
			fi
		done
		TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG
		http_attacks $HTML_DIR $YEAR "/" "."      "$LAST_MONTH" "last-30-days"
		PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG
	
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing historical now" ; fi
		TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG
		http_attacks $HTML_DIR $YEAR "/$HTML_DIR/historical/" "."      "*/*/*/current-raw-data.gz" "historical"
		PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG
		#----------------------------------------------------------------
		# Lets make last-30-days-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-httppsycho-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-httppsycho-2-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-friends-of-httppsycho-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-associates-of-httppsycho-attack-count.data
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			TMP_DATE2=`date "+%m/%d" --date="$i day ago"`

			if [ -e /$HTML_DIR/historical/$TMP_DATE/current-attack-count.data ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-attack-count.data`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-attack-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-attack-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays-uniq-ips.txt.count ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-ips.txt.count`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays-uniq-webpages ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-webpages`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-webpages-txt-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-webpages-txt-count.data
			fi

		done

		for file in $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data $HTML_DIR/last-30-days-todays-uniq-webpages-txt-count.data ; do
			cp $file $file.tmp
			tac $file.tmp > $file
			rm $file.tmp
		done
	fi # if [ $START_HOUR -eq $MIDNIGHT ]
	
	#-----------------------------------------------------------------
	cd $HTML_DIR/
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Making Graphics now" ; date; fi
	if [ $GRAPHS == 1 ] ; then
		#
		# Deal with creating empty 7-day, 30-day and historical files the 
		# first time this is run
		echo ""
		echo "Making Graphics now"
		echo ""
		if [ ! -e last-7-days-top-20-admin-passwords.data ] ; then
			touch current-attack-count.data
			touch current_attackers_lifespan.data
			touch current-top-20-admin-passwords.data
			touch current-top-20-non-root-accounts.data
			touch current-top-20-non-root-passwords.data
			touch current-top-20-root-passwords.data
			touch historical-top-20-admin-passwords.data
			touch historical-top-20-non-root-accounts.data
			touch historical-top-20-non-root-passwords.data
			touch historical-top-20-root-passwords.data
			touch last-30-days-top-20-admin-passwords.data
			touch last-30-days-top-20-non-root-accounts.data
			touch last-30-days-top-20-non-root-passwords.data
			touch last-30-days-top-20-root-passwords.data
			touch last-7-days-top-20-admin-passwords.data
			touch last-7-days-top-20-non-root-accounts.data
			touch last-7-days-top-20-non-root-passwords.data
			touch last-7-days-top-20-root-passwords.data
			touch last-30-days-attack-count.data
			touch last-30-days-ips-count.data
		fi

#		for FILE in current*.data ; do 
#			if [ ! "$FILE" == "current-attack-count.data" ] ; then
#				MAP=`echo $FILE |sed 's/.data/.map/'`
#				GRAPHIC_FILE=`echo $FILE | sed 's/.data/.png/'`
#				TITLE=`echo $FILE | sed 's/non-root-passwords/non-root-non-admin-passwords/' | sed 's/last/Prior/'| sed 's/-/ /g' |sed 's/.data//'`
#				TMP_TITLE=`for word in $TITLE; do printf '%s ' "${word^}"; done; echo`
#				TITLE=$TMP_TITLE
#				TITLE=`echo $TITLE | sed 's/Top 20 Admin Passwords/Top 20 Username \"admin\" Passwords/' `
#				if [ -s "$FILE" ] ; then
#					# Hack to make sure we use the real "top 20 non root accounts"
#					if [ "$FILE" == "current-top-20-non-root-accounts.data" ] ;
#					then
#						FILE="current-top-20-non-root-accounts-real.data"
#					fi
#					if [[ $FILE == *"accounts"* ]] ; then
#						php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE
#							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
#					fi
#					if [[ $FILE == *"password"* ]] ; then
#						php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE
#							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
#					fi
#				else #We have an empty file, deal with it here
#					echo "0 0" >$TMP_DIRECTORY/LongTail.data.$$
#					if [[ $FILE == *"accounts"* ]] ; then
#						php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE
#							echo "" >$MAP
#					fi
#					if [[ $FILE == *"password"* ]] ; then
#						php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE
#							echo "" >$MAP
#					fi
#					rm $TMP_DIRECTORY/LongTail.data.$$
#				fi
#			fi
#		done        

		
		echo ""
		echo "checking to see if we need to make midnight Graphics now"
		#echo "midnight is set to $MIDNIGHT"
		echo ""
		if [ $START_HOUR -eq $MIDNIGHT ]; then
		#if [ $START_HOUR -eq 18 ]; then
			/usr/local/etc/LongTail_make_30_days_imagemap.pl >30_days_imagemap.html
			echo ""
			echo "Making midnight Graphics now"
			echo ""
			for FILE in historical*.data last-*.data ; do 
				echo "DEBUG FILE is $FILE";
				if [ ! "$FILE" == "current-attack-count.data" ] ; then
					MAP=`echo $FILE |sed 's/.data/.map/'`
					GRAPHIC_FILE=`echo $FILE | sed 's/.data/.png/'`
					TITLE=`echo $FILE |  sed 's/last/Prior/'| sed 's/-/ /g' |sed 's/.data//'`
					TMP_TITLE=`for word in $TITLE; do printf '%s ' "${word^}"; done; echo`
					TITLE=$TMP_TITLE
					TITLE=`echo $TITLE | sed 's/Top 20 Admin Passwords/Top 20 Username \"admin\" Passwords/' `
				fi
				if [ -s "$FILE" ] ; then
					if [[ $FILE == *"last-30-days-attack-count.data"* ]] ; then
						if [ "x$HOSTNAME" == "x/" ] ;then
							php /usr/local/etc/LongTail_make_graph.php $HTML_DIR/last-30-days-attack-count.data "Last 30 Days Attacks" "" "" "wide" > $GRAPHIC_FILE
						else
							php /usr/local/etc/LongTail_make_graph.php $HTML_DIR/last-30-days-attack-count.data "Last 30 Days Attacks" "" "" "wide" > $GRAPHIC_FILE
						fi
					fi
				fi
			done # for FILE in historical*.data last-*.data
		fi # if [ $START_HOUR -eq $MIDNIGHT ]
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-Done Making Graphics now" ; date; fi
	fi
} # End of do_http

#
############################################################################
#
# Example input line: 
# 2015-02-26T12:46:40.500085-05:00 shepherd sshd-2222[28001]: IP: 107.150.35.218 Pass2222Log: Username:  Password: qwe123
# 2015-02-26T12:46:40.500085-05:00 shepherd sshd-22[28001]: IP: 107.150.35.218 PassLog: Username:  Password: qwe123
# 2015-02-26T12:46:40.500085-05:00 shepherd sshd[28001]: STUFF
# 2015-02-26T12:46:40.500085-05:00 shepherd telnet-honeypot[28001]: IP: 107.150.35.218 TelnetLog: Username:  Password: qwe123

function do_ssh {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-in do_ssh now" ; fi
	#-----------------------------------------------------------------
	# Lets count the ssh attacks
	count_ssh_attacks $HTML_DIR $PATH_TO_VAR_LOG "$LOGFILE*"
	
	#----------------------------------------------------------------
	# Lets check the ssh logs
	ssh_attacks $HTML_DIR $YEAR $PATH_TO_VAR_LOG "$DATE"  "$LOGFILE*" "current"
	
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-in do_ssh/last7,30,historical  now" ; fi
		#----------------------------------------------------------------
		# Lets check the ssh logs for the last 7 days
		LAST_WEEK="/dev/null "
		for i in 1 2 3 4 5 6 7 ; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			if [ -e "$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz" ] ; then
			if [ "$LAST_WEEK" == "" ] ; then
				LAST_WEEK="$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			else
				LAST_WEEK="$LAST_WEEK $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			fi
			fi
		done
		TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG
		ssh_attacks $HTML_DIR $YEAR "/" "."      "$LAST_WEEK" "last-7-days"
		PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG
	
		#----------------------------------------------------------------
		# Lets check the ssh logs for the last 30 days
		LAST_MONTH="/dev/null "
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			if [ -e "$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz" ] ; then
			if [ "$LAST_MONTH" == "" ] ; then
				LAST_MONTH="$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			else
				LAST_MONTH="$LAST_MONTH $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz"
			fi
			fi
		done
		TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG
		ssh_attacks $HTML_DIR $YEAR "/" "."      "$LAST_MONTH" "last-30-days"
		PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG
	
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-doing historical now" ; fi
		TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG
		ssh_attacks $HTML_DIR $YEAR "/$HTML_DIR/historical/" "."      "*/*/*/current-raw-data.gz" "historical"
		PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG
		#----------------------------------------------------------------
		# Lets make last-30-days-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-sshpsycho-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data
		echo -n "" > $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			TMP_DATE2=`date "+%m/%d" --date="$i day ago"`

			if [ -e /$HTML_DIR/historical/$TMP_DATE/current-attack-count.data ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-attack-count.data`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-attack-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-attack-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-attack-count.data ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-attack-count.data`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-sshpsycho-attack-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-sshpsycho-attack-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-2-attack-count.data ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-2-attack-count.data`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/current-friends_of_sshpsycho-attack-count.data ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-friends_of_sshpsycho-attack-count.data`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/current-associates_of_sshpsycho-attack-count.data ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-associates_of_sshpsycho-attack-count.data`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays-uniq-ips.txt.count ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-ips.txt.count`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays-uniq-passwords.txt.count ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-passwords.txt.count`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-passwords-txt-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-passwords-txt-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays-uniq-usernames.txt.count ] ; then
				tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-usernames.txt.count`
				echo "$tmp_attack_count $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-usernames-txt-count.data
			else
				#echo "Can not find /$HTML_DIR/historical/$TMP_DATE/todays-uniq-usernames.txt.count "
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-todays-uniq-usernames-txt-count.data
			fi

		done

		for file in $HTML_DIR/last-30-days-sshpsycho-attack-count.data $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-todays-uniq-usernames-txt-count.data $HTML_DIR/last-30-days-todays-uniq-passwords-txt-count.data $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data  $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data ; do
			cp $file $file.tmp
			tac $file.tmp > $file
			rm $file.tmp
		done


		#----------------------------------------------------------------
		# Lets make last-30-days-ips-count.data, last-30-days-password-count.data, last-30-days-username-count.data
		echo -n "" > $HTML_DIR/last-30-days-ips-count.data
		echo -n "" > $HTML_DIR/last-30-days-username-count.data
		echo -n "" > $HTML_DIR/last-30-days-password-count.data
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
			TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`
			TMP_DATE2=`date "+%m/%d" --date="$i day ago"`

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays_password.count ] ; then
				tmp_password=`cat /$HTML_DIR/historical/$TMP_DATE/todays_password.count`
				echo "$tmp_password $TMP_DATE2" >> $HTML_DIR/last-30-days-password-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-password-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays_username.count ] ; then
				tmp_username=`cat /$HTML_DIR/historical/$TMP_DATE/todays_username.count`
				echo "$tmp_username $TMP_DATE2" >> $HTML_DIR/last-30-days-username-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-username-count.data
			fi

			if [ -e /$HTML_DIR/historical/$TMP_DATE/todays_ips.count ] ; then
				tmp_ips=`cat /$HTML_DIR/historical/$TMP_DATE/todays_ips.count`
				echo "$tmp_ips $TMP_DATE2" >> $HTML_DIR/last-30-days-ips-count.data
			else
				echo "0 $TMP_DATE2" >> $HTML_DIR/last-30-days-ips-count.data
			fi
		done

		cp $HTML_DIR/last-30-days-password-count.data $HTML_DIR/last-30-days-password-count.data.tmp
		tac $HTML_DIR/last-30-days-password-count.data.tmp > $HTML_DIR/last-30-days-password-count.data
		rm $HTML_DIR/last-30-days-password-count.data.tmp

		cp $HTML_DIR/last-30-days-username-count.data $HTML_DIR/last-30-days-username-count.data.tmp
		tac $HTML_DIR/last-30-days-username-count.data.tmp > $HTML_DIR/last-30-days-username-count.data
		rm $HTML_DIR/last-30-days-username-count.data.tmp

		cp $HTML_DIR/last-30-days-ips-count.data $HTML_DIR/last-30-days-ips-count.data.tmp
		tac $HTML_DIR/last-30-days-ips-count.data.tmp > $HTML_DIR/last-30-days-ips-count.data
		rm $HTML_DIR/last-30-days-ips-count.data.tmp

	fi


	# This is an example of how to call ssh_attacks for past dates and 
	# put the reports in the $HTML_DIR/historical/Year/month/date directory
	# Make sure you edit the date in BOTH places in the line.
	#
#	for LOOP in 04 05 06 07 08 09 ; do
#		mkdir -p $HTML_DIR/historical/2015/01/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/01/$LOOP $YEAR $PATH_TO_VAR_LOG "2015-01-$LOOP"      "$LOGFILE*" "current"
#	done
#	for LOOP in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
#		mkdir -p $HTML_DIR/historical/2015/01/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/01/$LOOP $YEAR $PATH_TO_VAR_LOG "2015-01-$LOOP"      "$LOGFILE*" "current"
#	done
#	for LOOP in 01 02 03 04 05 06 07 08 09 ; do
#		mkdir -p $HTML_DIR/historical/2015/02/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/02/$LOOP $YEAR $PATH_TO_VAR_LOG "2015-02-$LOOP"      "$LOGFILE*" "current"
#	done
#	for LOOP in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28; do
#	for LOOP in 25 26 27 28; do
#		mkdir -p $HTML_DIR/historical/2015/02/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/02/$LOOP $YEAR $PATH_TO_VAR_LOG "2015-02-$LOOP"      "$LOGFILE*" "current"
#	done
#	for LOOP in 01 02 03 04 05 06 07 08 09 ; do
#		mkdir -p $HTML_DIR/historical/2015/03/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/03/$LOOP $YEAR $PATH_TO_VAR_LOG "2015-03-$LOOP"      "$LOGFILE*" "current"
#	done
#	for LOOP in 10 11 12 13 ; do
#		mkdir -p $HTML_DIR/historical/2015/03/$LOOP
#		ssh_attacks $HTML_DIR/historical/2015/03/$LOOP $YEAR $PATH_TO_VAR_LOG "2015-03-$LOOP"      "$LOGFILE*" "current"
#	done

# Example of getting a single date.  Make sure you edit the date in BOTH places in the line.
#	ssh_attacks $HTML_DIR/historical/2015/02/24 $YEAR $PATH_TO_VAR_LOG "2015-02-24"      "$LOGFILE*" "current"
	
	
	#-----------------------------------------------------------------
	cd $HTML_DIR/
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Making Graphics now" ; date; fi
	if [ $GRAPHS == 1 ] ; then
	#
	# Deal with creating empty 7-day, 30-day and historical files the 
	# first time this is run
echo ""
echo "Making Graphics now"
echo ""
	if [ ! -e last-7-days-top-20-admin-passwords.data ] ; then
		touch current-attack-count.data
		touch current_attackers_lifespan.data
		touch current-top-20-admin-passwords.data
		touch current-top-20-non-root-accounts.data
		touch current-top-20-non-root-passwords.data
		touch current-top-20-root-passwords.data
		touch historical-top-20-admin-passwords.data
		touch historical-top-20-non-root-accounts.data
		touch historical-top-20-non-root-passwords.data
		touch historical-top-20-root-passwords.data
		touch last-30-days-top-20-admin-passwords.data
		touch last-30-days-top-20-non-root-accounts.data
		touch last-30-days-top-20-non-root-passwords.data
		touch last-30-days-top-20-root-passwords.data
		touch last-7-days-top-20-admin-passwords.data
		touch last-7-days-top-20-non-root-accounts.data
		touch last-7-days-top-20-non-root-passwords.data
		touch last-7-days-top-20-root-passwords.data
		touch last-30-days-attack-count.data
		touch last-30-days-ips-count.data
	fi

		for FILE in current*.data ; do 
			if [ ! "$FILE" == "current-attack-count.data" ] ; then
				MAP=`echo $FILE |sed 's/.data/.map/'`
				GRAPHIC_FILE=`echo $FILE | sed 's/.data/.png/'`
				TITLE=`echo $FILE | sed 's/non-root-passwords/non-root-non-admin-passwords/' | sed 's/last/Prior/'| sed 's/-/ /g' |sed 's/.data//'`
				TMP_TITLE=`for word in $TITLE; do printf '%s ' "${word^}"; done; echo`
				TITLE=$TMP_TITLE
				TITLE=`echo $TITLE | sed 's/Top 20 Admin Passwords/Top 20 Username \"admin\" Passwords/' `
				if [ -s "$FILE" ] ; then
					# Hack to make sure we use the real "top 20 non root accounts"
					if [ "$FILE" == "current-top-20-non-root-accounts.data" ] ;
					then
						FILE="current-top-20-non-root-accounts-real.data"
					fi
					if [[ $FILE == *"accounts"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
					fi
					if [[ $FILE == *"password"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
					fi
				else #We have an empty file, deal with it here
					echo "0 0" >$TMP_DIRECTORY/LongTail.data.$$
					if [[ $FILE == *"accounts"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE
							echo "" >$MAP
					fi
					if [[ $FILE == *"password"* ]] ; then
						php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE
							echo "" >$MAP
					fi
					rm $TMP_DIRECTORY/LongTail.data.$$
				fi
			fi
		done        

		
echo ""
echo "checking to see if we need to make midnight Graphics now"
#echo "midnight is set to $MIDNIGHT"
echo ""
		if [ $START_HOUR -eq $MIDNIGHT ]; then
		#if [ $START_HOUR -eq 12 ]; then
echo ""
echo "Making midnight Graphics now"
echo ""
			for FILE in historical*.data last-*.data ; do 
				if [ ! "$FILE" == "current-attack-count.data" ] ; then
					MAP=`echo $FILE |sed 's/.data/.map/'`
					GRAPHIC_FILE=`echo $FILE | sed 's/.data/.png/'`
					TITLE=`echo $FILE | sed 's/non-root-passwords/non-root-non-admin-passwords/' | sed 's/last/Prior/'| sed 's/-/ /g' |sed 's/.data//'`
					TMP_TITLE=`for word in $TITLE; do printf '%s ' "${word^}"; done; echo`
					TITLE=$TMP_TITLE
					TITLE=`echo $TITLE | sed 's/Top 20 Admin Passwords/Top 20 Username \"admin\" Passwords/' `

					if [ -s "$FILE" ] ; then
#						# Hack to make sure we use the real "top 20 non root accounts"
						if [ "$FILE" == "current-top-20-non-root-accounts.data" ] ;
						then
							FILE="current-top-20-non-root-accounts-real.data"
						fi
						if [ "$FILE" == "last-7-days-top-20-non-root-accounts.data" ] ;
						then
							FILE="last-7-days-top-20-non-root-accounts-real.data"
						fi
						if [ "$FILE" == "last-30-days-top-20-non-root-accounts.data" ] ;
						then
							FILE="last-30-days-top-20-non-root-accounts-real.data"
						fi
						if [ "$FILE" == "historical-top-20-non-root-accounts.data" ] ;
						then
							FILE="historical-top-20-non-root-accounts-real.data"
						fi
						if [[ $FILE == *"accounts"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
						fi
						if [[ $FILE == *"password"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
						fi
						if [[ $FILE == *"last-30-days-username-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $FILE "Last 30 Days Count of Unique Usernames" "" "" "wide"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
						fi
						if [[ $FILE == *"last-30-days-password-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $FILE "Last 30 Days Count of Unique Passwords" "" "" "wide"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
						fi
						if [[ $FILE == *"last-30-days-ips-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $FILE "Last 30 Days Count of Unique IP addresses" "" "" "wide"> $GRAPHIC_FILE
							$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP
						fi
						if [[ $FILE == *"last-30-days-attack-count.data"* ]] ; then
							# This works but I want to show sshPsycho data now
							if [ "x$HOSTNAME" == "x/" ] ;then
								php /usr/local/etc/LongTail_make_graph_sshpsycho.php $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data  $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data "Last 30 Days Attacks (Red=sshPsycho-2, Yellow=Friends of sshPsycho, Green=Associates of sshPsycho, Blue=others)" "" "" "wide" > $GRAPHIC_FILE
							else
								php /usr/local/etc/LongTail_make_graph_sshpsycho.php $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data  $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data "Last 30 Days Attacks (Red=sshPsycho-2, Yellow=Friends of sshPsycho, Blue=others)" "" "" "wide" > $GRAPHIC_FILE
							fi

						fi
					else #We have an empty file, deal with it here
						echo "0 0" >$TMP_DIRECTORY/LongTail.data.$$
						echo "" > $file.map
						if [[ $FILE == *"accounts"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE
							echo "" >$MAP
						fi
						if [[ $FILE == *"password"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE
							echo "" >$MAP
						fi
						if [[ $FILE == *"last-30-days-username-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today for Unique Usernames" "" "" "wide"> $GRAPHIC_FILE
							echo "" >$MAP
						fi
						if [[ $FILE == *"last-30-days-password-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today for Unique Passwords" "" "" "wide"> $GRAPHIC_FILE
							echo "" >$MAP
						fi
						if [[ $FILE == *"last-30-days-ips-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today for Unique IP addresses" "" "" "wide"> $GRAPHIC_FILE
							echo "" >$MAP
						fi
						if [[ $FILE == *"last-30-days-attack-count.data"* ]] ; then
							php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "$TITLE" "" "" "wide"> $GRAPHIC_FILE
							echo "" >$MAP
						fi
						rm $TMP_DIRECTORY/LongTail.data.$$
					fi
				fi
			done        
		fi
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-Done Making Graphics now" ; date; fi
	fi    
} # End of do_ssh

function make_daily_attacks_chart {
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-make_daily_attacks_chart" ; date; fi
	cd $HTML_DIR/historical
	make_header "$HTML_DIR/attacks_by_day.shtml" "Attacks By Day"  "" 
	$SCRIPT_DIR/LongTail_make_daily_attacks_chart.pl "$HTML_DIR/historical" >> $HTML_DIR/attacks_by_day.shtml 
	make_footer "$HTML_DIR/attacks_by_day.shtml"
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Done make_daily_attacks_chart" ; date; fi
}

############################################################################
# Set permissions so everybody can read the files
#
function set_permissions {
	TMP_HTML_DIR=$1
	chmod a+r $TMP_HTML_DIR/*
}

############################################################################
#
# Protect raw data for $NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA
#
function protect_raw_data {
        local TMP_HTML_DIR=$1
	local count
	is_directory_good $TMP_HTML_DIR
	if [ $START_HOUR -eq $MIDNIGHT ]; then
		if [ $PROTECT_RAW_DATA -eq 1 ]; then
			cd  $TMP_HTML_DIR

			count=`find . -name current-raw-data.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -print -quit | wc -l`
			if [ $count -gt 0 ]; then
				find . -name current-raw-data.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA |xargs chmod go-r
			fi

			count=`find . -name current-raw-data.gz -mtime +$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -print -quit | wc -l`
			if [ $count -lt 0 ]; then
				find . -name current-raw-data.gz -mtime +$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA |xargs chmod go+r
			fi
		fi
	fi
}

############################################################################
# Create historical copies of the data
#
# This creates yesterdays data, once "yesterday" is over
#
function create_historical_http_copies {
	TMP_HTML_DIR=$1
	REBUILD=1
	DEBUG=1
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-In create_historical_http_copies" ; date; fi

	if [ $START_HOUR -eq $MIDNIGHT ]; then
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Actually running create_historical_http_copies $START_HOUR -eq $MIDNIGHT) " ; date; fi
		YESTERDAY_YEAR=`date  +"%Y"  --date="1 day ago"`
		YESTERDAY_MONTH=`date  +"%m" --date="1 day ago"`
		YESTERDAY_DAY=`date  +"%d"   --date="1 day ago"`

		cd  $TMP_HTML_DIR

		mkdir -p $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY
		mkdir -p $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/malware
		for dir in $HOSTS_PROTECTED $BLACKRIDGE ; do
			if [ "x$HOSTNAME" == "x$dir" ] ; then
				touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
				echo $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
			fi
		done
		if [ -e $TMP_HTML_DIR/index-historical.shtml ] ; then
			cp $TMP_HTML_DIR/index-historical.shtml $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/index.shtml
		else
			if [ -e $HTML_DIR/index-historical.shtml ] ; then
				cp $HTML_DIR/index-historical.shtml $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/index.shtml
			else 
				echo "WARNING! CAN NOT FIND $TMP_HTML_DIR/index-historical.shtml OR $HTML_DIR/index-historical.shtml"
				echo "This is not a deal breaker but your historical directories"
				echo "will not have an index.shtml file"
			fi
		fi
		# I do individual chmods so I don't do chmod's of thousands of files...
		chmod a+rx $TMP_HTML_DIR/historical
		chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR
		chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH
		chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY
		chmod a+r  $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/*
		echo "$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY" > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/date.html

		$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$LOGFILE*  |grep $PROTOCOL |grep $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY |grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep |grep -v xymonnet | sed 's/^....-..-..T.............. //' > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages


		touch $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz
		/bin/rm $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz
		gzip $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages
		chmod 0000 $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz

		http_attacks   $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY $YESTERDAY_YEAR $PATH_TO_VAR_LOG "$YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY"      "$LOGFILE*" "current"

		#
		# Make IPs table and count for this day
		#todays_ips.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |awk '{print $3}' |sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips; 
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips.count;

		#
		# overlap between todays IPs and ssh brute forcers
		#
		grep -F -f $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips  /var/www/html/honey/all-ips  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips_overlap_with_longtail_ssh.txt
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips_overlap_with_longtail_ssh.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips_overlap_with_longtail_ssh.count


		# Make todays_honeypot.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | awk '{print $1}' | sort -T $TMP_DIRECTORY |uniq -c  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-honeypots.txt 
	cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-honeypots.txt | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-honeypots.txt.count

		# Make todays_webpages.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | sed 's/^..*\"GET\ /GET-/'| sed 's/^..*\"HEAD\ /HEAD-/'| sed 's/^..*\"POST\ /POST-/' | sed 's/^..*\"OPTIONS\ /OPTIONS-/'  | sed 's/^..*\"CONNECT\ /CONNECT-/'  | sed 's/^..*\"PROPFIND\ /PROPFIND-/'  |sed 's/ ..*$//' | sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_webpages 
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_webpages |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_webpages.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_webpages 
	cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_webpages | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-attack-count.data

		# Make todays_404_webpages.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | grep \ 404\  | sed 's/^..*\"GET\ /GET-/'| sed 's/^..*\"HEAD\ /HEAD-/'| sed 's/^..*\"POST\ /POST-/' | sed 's/^..*\"OPTIONS\ /OPTIONS-/'  | sed 's/^..*\"CONNECT\ /CONNECT-/'  | sed 's/^..*\"PROPFIND\ /PROPFIND-/'  |sed 's/ ..*$//' | sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_404_webpages 
	cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_404_webpages |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_404_webpages.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | grep \ 404\  |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_404_webpages 
	cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_404_webpages | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_404_webpages.count

		# Make todays shellshock count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | grep \:\;  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_shellshock_webpages
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_shellshock_webpages |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_shellshock_webpages.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | grep \:\;  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_shellshock_webpages
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_shellshock_webpages | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_shellshock.count

		# Make todays wget count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | grep wget  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_uniq_wget_webpages
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | grep wget  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_wget_webpages
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_shellshock_webpages | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_wget_webpages.count
		

		#
		# Lets hope this is run before all-ips, all-password, and all-username are run
		#
		if [ ! -e $HTML_DIR/all-ips ] ; then 
			echo "This must be the first time this was run, copying todays IPs to all-ips"
			/bin/cp $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips $HTML_DIR/all-ips
		fi
		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' $HTML_DIR/all-ips       $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt

		if [ ! -e $HTML_DIR/all-webpages ] ; then 
			echo "This must be the first time this was run, copying todays webpages to all-webpages"
			/bin/cp $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_webpages $HTML_DIR/all-webpages
		fi
		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' $HTML_DIR/all-webpages $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_webpages >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-webpages.txt

		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-webpages.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-webpages.txt.count
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt.count

	fi

}

############################################################################
# Create historical copies of the data
#
# This creates yesterdays data, once "yesterday" is over
#
function create_historical_copies {
	TMP_HTML_DIR=$1
	REBUILD=1
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-In create_historical_copies" ; date; fi

	if [ $START_HOUR -eq $MIDNIGHT ]; then
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Actually running create_historical_copies $START_HOUR -eq $MIDNIGHT) " ; date; fi
		YESTERDAY_YEAR=`date  +"%Y" --date="1 day ago"`
		YESTERDAY_MONTH=`date  +"%m" --date="1 day ago"`
		YESTERDAY_DAY=`date  +"%d" --date="1 day ago"`

		cd  $TMP_HTML_DIR

		mkdir -p $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY
		for dir in $HOSTS_PROTECTED $BLACKRIDGE ; do
			if [ "x$HOSTNAME" == "x$dir" ] ; then
				touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
				echo $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
			fi
		done
		if [ -e $TMP_HTML_DIR/index-historical.shtml ] ; then
			cp $TMP_HTML_DIR/index-historical.shtml $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/index.shtml
		else
			if [ -e $HTML_DIR/index-historical.shtml ] ; then
				cp $HTML_DIR/index-historical.shtml $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/index.shtml
			else 
				echo "WARNING! CAN NOT FIND $TMP_HTML_DIR/index-historical.shtml OR $HTML_DIR/index-historical.shtml"
				echo "This is not a deal breaker but your historical directories"
				echo "will not have an index.shtml file"
			fi
		fi
		# I do individual chmods so I don't do chmods of thousands of files...
		chmod a+rx $TMP_HTML_DIR/historical
		chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR
		chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH
		chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY
		chmod a+r  $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/*
		echo "$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY" > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/date.html

		if [ $LONGTAIL -eq 1 ] ; then
			grep ssh $PATH_TO_VAR_LOG/$LOGFILE* | grep $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages
		fi
		if [ $KIPPO -eq 1 ] ; then
			grep ssh $PATH_TO_VAR_LOG/$LOGFILE* | grep $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages
		fi

		touch $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz
		/bin/rm $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz
		gzip $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages
		chmod 0000 $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz


		ssh_attacks   $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY $YESTERDAY_YEAR $PATH_TO_VAR_LOG "$YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY"      "$LOGFILE*" "current"

		#
		# Make IPs table and count for this day
		#todays_ips.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's/^..*IP: //' |tr -cd '\11\12\40-\176'  |sed 's/ .*$//'|sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips; 
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips.count;

		# Make todays_honeypot.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz | egrep IP:\|sshd | sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-honeypots.txt 
	cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-honeypots.txt | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-honeypots.txt.count

		# Make todays_password.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's/^.*Password://'|sed 's/^ //'| sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password 
	cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password.count

		# Make todays_username.count
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP:|sed 's/^.*Username: //' |sed 's/ Password..*$//'|uniq |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username.count

		# Make current-sshpsycho-attack-count.data
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-attack-count.data

		# Make current-sshpsycho-2-attack-count.data
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-2-attack-count.data

		# Make current-friends_of_sshpsycho-attack-count.data
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-friends_of_sshpsycho-attack-count.data

		# Make current-associates_of_sshpsycho-attack-count.data
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-associates_of_sshpsycho-attack-count.data

    #
    # Make IPs table and count for this day
    #todays_ips.count
    zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's/^..*IP: //' |tr -cd '\11\12\40-\176'  |sed 's/ .*$//'|sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips;
    cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips.count;

    # Make todays_password.count
    zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's/^.*Password://'|sed 's/^ //'| sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//todays_password
  cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//todays_password.count

    # Make todays_username.count
    zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//current-raw-data.gz |grep IP:|sed 's/^.*Username: //' |sed 's/ Password..*$//'|uniq |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username
    cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//todays_username | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username.count

# NEW STUFF May 27th...
#
# Lets hope this is run before all-ips, all-password, and all-username are run
		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' $HTML_DIR/all-ips       $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt

		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' $HTML_DIR/all-password $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-passwords.txt

		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' $HTML_DIR/all-username $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-usernames.txt

		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-passwords.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-passwords.txt.count
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-usernames.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-usernames.txt.count
		cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt.count


	fi
}

############################################################################
# 
# Normal users should never need this.  I wrote this because I keep changing
# things around and have to rebuild the files when I change stuff
#
# Does not seem to change these files:
#  -rw-r--r--. 1 root  root       5 Mar 14 12:27 current-attack-count.data
#  -rw-r--r--. 1 root  root   34433 Mar 14 12:27 current-raw-data.gz
# This does not work yet.... 2015-03-26

function rebuild { 
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-In Rebuild now" ; fi
	REBUILD=1
  cd $HTML_DIR/historical/
# ssh_attacks $HTML_DIR/historical/2015/02/24 $YEAR $PATH_TO_VAR_LOG "2015-02-24"      "$LOGFILE*" "current"
#	ssh_attacks $HTML_DIR/historical/2015/03/14 $YEAR $PATH_TO_VAR_LOG "2015-03-14"      "$LOGFILE*" "current"
# ssh_attacks /var/www/html/honey///historical/2015/01/04 2015 /var/www/html/honey///historical/2015/01/04 2015-01-04 current-raw-data.gz current

	#
	# Make blank files so we can determine on a daily basis
	# Which IPs, usernames, passwords are NEW for that day
	#	
	touch /tmp/LongTail.$$.ips
	touch /tmp/LongTail.$$.passwords
	touch /tmp/LongTail.$$.usernames
	rm /tmp/LongTail.$$.ips
	rm /tmp/LongTail.$$.passwords
	rm /tmp/LongTail.$$.usernames
	echo "THISisAbogusFILLERline"> /tmp/LongTail.$$.ips
	echo "THISisAbogusFILLERline"> /tmp/LongTail.$$.passwords
	echo "THISisAbogusFILLERline"> /tmp/LongTail.$$.usernames

  for FILE in */*/*/current-raw-data.gz ; do
		echo $FILE
		DIRNAME=`dirname $FILE`
		echo "DIRNAME is $DIRNAME"
		YEAR=`dirname $DIRNAME`
		YEAR=`dirname $YEAR`
		DATE=`echo $DIRNAME |sed 's/\//-/g';`
		echo "DATE is $DATE"
		echo "YEAR IS $YEAR"
		echo ssh_attacks $HTML_DIR/historical/$DIRNAME $YEAR $HTML_DIR/historical/$DIRNAME "$DATE"      "current-raw-data.gz" "current"
		ssh_attacks $HTML_DIR/historical/$DIRNAME $YEAR $HTML_DIR/historical/$DIRNAME "$DATE"      "current-raw-data.gz" "current"

		# Make current-sshpsycho-attack-count.data
		zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l > $HTML_DIR/historical/$DIRNAME/current-sshpsycho-attack-count.data

		# Make current-sshpsycho-2-attack-count.data
		zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l > $HTML_DIR/historical/$DIRNAME/current-sshpsycho-2-attack-count.data

		# Make current-friends_of_sshpsycho-attack-count.data
		zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$DIRNAME/current-friends_of_sshpsycho-attack-count.data

		# Make current-associates_of_sshpsycho-attack-count.data
		zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$DIRNAME/current-associates_of_sshpsycho-attack-count.data

		#
		# Make IPs table and count for this day
		#todays_ips.count
		zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |sed 's/^..*IP: //' |tr -cd '\11\12\40-\176' |sed 's/ .*$//'|sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$DIRNAME/todays_ips; 
		cat $HTML_DIR/historical/$DIRNAME/todays_ips |wc -l > $HTML_DIR/historical/$DIRNAME//todays_ips.count;

		# Make todays_password.count
		zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |sed 's/^.*Password://'|sed 's/^ //'| sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$DIRNAME//todays_password 
	cat $HTML_DIR/historical/$DIRNAME/todays_password | wc -l > $HTML_DIR/historical/$DIRNAME//todays_password.count

		# Make todays_username.count
		zcat $HTML_DIR/historical/$DIRNAME//current-raw-data.gz |grep IP:|sed 's/^.*Username: //' |sed 's/ Password..*$//'|uniq |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$DIRNAME/todays_username
		cat $HTML_DIR/historical/$DIRNAME//todays_username | wc -l > $HTML_DIR/historical/$DIRNAME//todays_username.count


		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' /tmp/LongTail.$$.ips       $HTML_DIR/historical/$DIRNAME/todays_ips >$HTML_DIR/historical/$DIRNAME/todays-uniq-ips.txt

		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' /tmp/LongTail.$$.passwords $HTML_DIR/historical/$DIRNAME/todays_password >$HTML_DIR/historical/$DIRNAME/todays-uniq-passwords.txt

echo "looking at $HTML_DIR/historical/$DIRNAME/todays_username"
#ls -l $HTML_DIR/historical/$DIRNAME/todays_username
#wc -l $HTML_DIR/historical/$DIRNAME/todays_username

		awk 'FNR==NR{a[$0]++;next}(!($0 in a))' /tmp/LongTail.$$.usernames $HTML_DIR/historical/$DIRNAME/todays_username >$HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt

#ls -l $HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt

		cat $HTML_DIR/historical/$DIRNAME/todays_password > /tmp/LongTail.$$.passwords
		sort -T $TMP_DIRECTORY -u /tmp/LongTail.$$.passwords > /tmp/LongTail.$$.passwords.tmp
		mv /tmp/LongTail.$$.passwords.tmp /tmp/LongTail.$$.passwords

		cat $HTML_DIR/historical/$DIRNAME/todays_ips > /tmp/LongTail.$$.ips
		sort -T $TMP_DIRECTORY -u /tmp/LongTail.$$.ips > /tmp/LongTail.$$.ips.tmp
		mv /tmp/LongTail.$$.ips.tmp /tmp/LongTail.$$.ips

		cat $HTML_DIR/historical/$DIRNAME/todays_username > /tmp/LongTail.$$.usernames
		sort -T $TMP_DIRECTORY -u /tmp/LongTail.$$.usernames > /tmp/LongTail.$$.usernames.tmp
		mv /tmp/LongTail.$$.usernames.tmp /tmp/LongTail.$$.usernames

		cat $HTML_DIR/historical/$DIRNAME/todays-uniq-passwords.txt |wc -l > $HTML_DIR/historical/$DIRNAME/todays-uniq-passwords.txt.count
		cat $HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt |wc -l > $HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt.count
		cat $HTML_DIR/historical/$DIRNAME/todays-uniq-ips.txt |wc -l > $HTML_DIR/historical/$DIRNAME/todays-uniq-ips.txt.count
	
	done
}

############################################################################
# This creates a file current-attack-count.data.notfullday in all the
# hosts historical directories that shows the host is protected by
# a firewall 
#
function set_hosts_protected_flag {
	if [ "x$HOSTNAME" == "x/" ] ;then
		for host in $HOSTS_PROTECTED $BLACKRIDGE ; do
			cd /var/www/html/honey/$host/historical
			for dir in `find */*/* -type d` ; do
				touch $dir/current-attack-count.data.notfullday
			done
		done
	fi
}

function recount_last_30_days_sshpsycho_attacks {

	if [ $DEBUG  == 1 ] ; then echo -n "DEBUG-In recount_last_30_days_sshpsycho_attacks" ; date; fi
	LAST_MONTH=""
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 ; do
		YESTERDAY_YEAR=`date "+%Y" --date="$i day ago"`
		YESTERDAY_MONTH=`date "+%m" --date="$i day ago"`
		YESTERDAY_DAY=`date "+%d" --date="$i day ago"`
		# Make current-sshpsycho-attack-count.data
		if [ -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ] ; then
			zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-attack-count.data
		fi
		# Make current-sshpsycho-2-attack-count.data
		if [ -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ] ; then
			zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-2-attack-count.data
		fi


		# Make current-friends_of_sshpsycho-attack-count.data
		if [ -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ] ; then 
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-friends_of_sshpsycho-attack-count.data
		fi

		# Make current-associates_of_sshpsycho-attack-count.data
		if [ -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ] ; then 
		zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-associates_of_sshpsycho-attack-count.data
		fi

	done
}



###########################################################################
#
# Lets count all the sshpsycho (and friends, etc) attacks
#

function count_sshpsycho_attacks {

	cd $HTML_DIR/historical
	TMP_DATE=`date +"%Y-%m-%d"`
	
	###########################################################################
	if [ $DEBUG  == 1 ] ; then echo "DEBUG-Counting sshpsycho attacks now" ; fi
	if [ "x$HOSTNAME" == "x/" ] ; then
		# sshPsycho is dead... TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" |grep IP:  | grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l`
		TODAY=0
	else
		# sshPsycho is dead... TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $HOSTNAME |grep "$TMP_DATE" |grep IP:  | grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l`
		TODAY=0
	fi
	# This month
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-sshpsycho-attack-count.data ` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_MONTH=`expr $TMP + $TODAY`
	# This year
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name current-sshpsycho-attack-count.data ` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR=`expr $TMP + $TODAY`
	# Since logging started 
	TMP=0
	for FILE in  `find . -name current-sshpsycho-attack-count.data ` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL=`expr $TMP + $TODAY`
	
	TODAY=`echo $TODAY | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_MONTH=`echo $THIS_MONTH | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_YEAR=`echo $THIS_YEAR | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TOTAL=`echo $TOTAL | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	#echo "TODAY is $TODAY, THIS_MONTH is $THIS_MONTH, this year is $THIS_YEAR"
	sed -i "s/SSHPsycho Today.*$/SSHPsycho Today:--> $TODAY/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho This Month.*$/SSHPsycho This Month:--> $THIS_MONTH/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho This Year.*$/SSHPsycho This Year:--> $THIS_YEAR/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho Since Logging Started.*$/SSHPsycho Since Logging Started:--> $TOTAL/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho Today.*$/SSHPsycho Today:--> $TODAY/" $HTML_DIR/index-long.shtml
	sed -i "s/SSHPsycho This Month.*$/SSHPsycho This Month:--> $THIS_MONTH/" $HTML_DIR/index-long.shtml
	sed -i "s/SSHPsycho This Year.*$/SSHPsycho This Year:--> $THIS_YEAR/" $HTML_DIR/index-long.shtml
	sed -i "s/SSHPsycho Since Logging Started.*$/SSHPsycho Since Logging Started:--> $TOTAL/" $HTML_DIR/index-long.shtml
	
	###########################################################################
	
	if [ $DEBUG  == 1 ] ; then echo -n  "DEBUG-Counting sshpsycho-2 attacks now"; date; fi
	#echo -n "DEBUG counting sshpsycho-2 today: "; date
	if [ "x$HOSTNAME" == "x/" ] ; then
		#TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" |grep IP:  | grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l`
		TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep IP:  | grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l`
	else
		#TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $HOSTNAME |grep "$TMP_DATE" |grep IP:  | grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l`
		TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep IP:  | grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l`
	fi
	# This month
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG counting sshpsycho-2 month: "; date ; fi
	TMP=0
	for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-sshpsycho-2-attack-count.data ` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_MONTH=`expr $TMP + $TODAY`
	# This year
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG counting sshpsycho-2 year: "; date ;fi
	TMP=0
	for FILE in  `find $TMP_YEAR/ -name current-sshpsycho-2-attack-count.data ` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	THIS_YEAR=`expr $TMP + $TODAY`
	# Since logging started 
	TMP=0
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG counting sshpsycho-2 since logging started: "; date; fi
	for FILE in  `find . -name current-sshpsycho-2-attack-count.data ` ; do
		COUNT=`cat $FILE`
		(( TMP += $COUNT ))
	done
	TOTAL=`expr $TMP + $TODAY`
	
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG counting sshpsycho-2 doing sed commands: "; date; fi
	TODAY=`echo $TODAY | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_MONTH=`echo $THIS_MONTH | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	THIS_YEAR=`echo $THIS_YEAR | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	TOTAL=`echo $TOTAL | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	#echo "TODAY is $TODAY, THIS_MONTH is $THIS_MONTH, this year is $THIS_YEAR"
	sed -i "s/SSHPsycho-2 Today.*$/SSHPsycho-2 Today:--> $TODAY/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho-2 This Month.*$/SSHPsycho-2 This Month:--> $THIS_MONTH/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho-2 This Year.*$/SSHPsycho-2 This Year:--> $THIS_YEAR/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho-2 Since Logging Started.*$/SSHPsycho-2 Since Logging Started:--> $TOTAL/" $HTML_DIR/index.shtml
	sed -i "s/SSHPsycho-2 Today.*$/SSHPsycho-2 Today:--> $TODAY/" $HTML_DIR/index-long.shtml
	sed -i "s/SSHPsycho-2 This Month.*$/SSHPsycho-2 This Month:--> $THIS_MONTH/" $HTML_DIR/index-long.shtml
	sed -i "s/SSHPsycho-2 This Year.*$/SSHPsycho-2 This Year:--> $THIS_YEAR/" $HTML_DIR/index-long.shtml
	sed -i "s/SSHPsycho-2 Since Logging Started.*$/SSHPsycho-2 Since Logging Started:--> $TOTAL/" $HTML_DIR/index-long.shtml
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG Done counting sshpsycho-2 doing sed commands: "; date; fi
	
	###########################################################################
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-Counting sshpsycho friends attacks now"; date ; fi
	
	if [ "x$HOSTNAME" == "x/" ] ; then
		#TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses|wc -l`
		TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses|wc -l`
	else
		#TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $HOSTNAME |grep "$TMP_DATE" |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses|wc -l`
		TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses|wc -l`
	fi
	
		# This month
		TMP=0
	        for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-friends_of_sshpsycho-attack-count.data ` ; do
	                COUNT=`cat $FILE`
	                (( TMP += $COUNT ))
	        done
	        THIS_MONTH=`expr $TMP + $TODAY`
		# This year
		TMP=0
	        for FILE in  `find $TMP_YEAR/ -name current-friends_of_sshpsycho-attack-count.data ` ; do
	                COUNT=`cat $FILE`
	                (( TMP += $COUNT ))
	        done
	        THIS_YEAR=`expr $TMP + $TODAY`
		# Since logging started
		TMP=0
	        for FILE in  `find . -name current-friends_of_sshpsycho-attack-count.data ` ; do
	                COUNT=`cat $FILE`
	                (( TMP += $COUNT ))
	        done
	        TOTAL=`expr $TMP + $TODAY`
	
		TODAY=`echo $TODAY | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THIS_MONTH=`echo $THIS_MONTH | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		THIS_YEAR=`echo $THIS_YEAR | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
		TOTAL=`echo $TOTAL | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	#	echo "TODAY is $TODAY, THIS_MONTH is $THIS_MONTH, this year is $THIS_YEAR"
		sed -i "s/SSHfriendsPsycho Today.*$/SSHfriendsPsycho Today:--> $TODAY/" $HTML_DIR/index.shtml
		sed -i "s/SSHfriendsPsycho This Month.*$/SSHfriendsPsycho This Month:--> $THIS_MONTH/" $HTML_DIR/index.shtml
		sed -i "s/SSHfriendsPsycho This Year.*$/SSHfriendsPsycho This Year:--> $THIS_YEAR/" $HTML_DIR/index.shtml
		sed -i "s/SSHfriendsPsycho Since Logging Started.*$/SSHfriendsPsycho Since Logging Started:--> $TOTAL/" $HTML_DIR/index.shtml
		sed -i "s/SSHfriendsPsycho Today.*$/SSHfriendsPsycho Today:--> $TODAY/" $HTML_DIR/index-long.shtml
		sed -i "s/SSHfriendsPsycho This Month.*$/SSHfriendsPsycho This Month:--> $THIS_MONTH/" $HTML_DIR/index-long.shtml
		sed -i "s/SSHfriendsPsycho This Year.*$/SSHfriendsPsycho This Year:--> $THIS_YEAR/" $HTML_DIR/index-long.shtml
		sed -i "s/SSHfriendsPsycho Since Logging Started.*$/SSHfriendsPsycho Since Logging Started:--> $TOTAL/" $HTML_DIR/index-long.shtml
	
	
	###########################################################################
	if [ $DEBUG  == 1 ] ; then  echo "DEBUG-Counting sshpsycho associates attacks now" ;fi
	if [ "x$HOSTNAME" == "x/" ] ; then
	        #TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses|wc -l`
	        TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses|wc -l`
	else
	        #TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep $HOSTNAME |grep "$TMP_DATE" |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses|wc -l`
	        TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep IP: | grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses|wc -l`
	fi
	
	        # This month
	        TMP=0
	        for FILE in  `find $TMP_YEAR/$TMP_MONTH -name current-associates_of_sshpsycho-attack-count.data ` ; do
	                COUNT=`cat $FILE`
	                (( TMP += $COUNT ))
	        done
	        THIS_MONTH=`expr $TMP + $TODAY`
	        # This year
	        TMP=0
	        for FILE in  `find $TMP_YEAR/ -name current-associates_of_sshpsycho-attack-count.data ` ; do
	                COUNT=`cat $FILE`
	                (( TMP += $COUNT ))
	        done
	        THIS_YEAR=`expr $TMP + $TODAY`
	        # Since logging started
	        TMP=0
	        for FILE in  `find . -name current-associates_of_sshpsycho-attack-count.data ` ; do
	                COUNT=`cat $FILE`
	                (( TMP += $COUNT ))
	        done
	        TOTAL=`expr $TMP + $TODAY`
	
	        TODAY=`echo $TODAY | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	        THIS_MONTH=`echo $THIS_MONTH | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	        THIS_YEAR=`echo $THIS_YEAR | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	        TOTAL=`echo $TOTAL | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'`
	#        echo "TODAY is $TODAY, THIS_MONTH is $THIS_MONTH, this year is $THIS_YEAR"
	        sed -i "s/SSHassociatesPsycho Today.*$/SSHassociatesPsycho Today:--> $TODAY/" $HTML_DIR/index.shtml
	        sed -i "s/SSHassociatesPsycho This Month.*$/SSHassociatesPsycho This Month:--> $THIS_MONTH/" $HTML_DIR/index.shtml
	        sed -i "s/SSHassociatesPsycho This Year.*$/SSHassociatesPsycho This Year:--> $THIS_YEAR/" $HTML_DIR/index.shtml
	        sed -i "s/SSHassociatesPsycho Since Logging Started.*$/SSHassociatesPsycho Since Logging Started:--> $TOTAL/" $HTML_DIR/index.shtml
	        sed -i "s/SSHassociatesPsycho Today.*$/SSHassociatesPsycho Today:--> $TODAY/" $HTML_DIR/index-long.shtml
	        sed -i "s/SSHassociatesPsycho This Month.*$/SSHassociatesPsycho This Month:--> $THIS_MONTH/" $HTML_DIR/index-long.shtml
	        sed -i "s/SSHassociatesPsycho This Year.*$/SSHassociatesPsycho This Year:--> $THIS_YEAR/" $HTML_DIR/index-long.shtml
	        sed -i "s/SSHassociatesPsycho Since Logging Started.*$/SSHassociatesPsycho Since Logging Started:--> $TOTAL/" $HTML_DIR/index-long.shtml
	if [ $DEBUG  == 1 ] ; then  echo -n "DEBUG-Done Counting sshpsycho attacks* now: "; date ;fi
	###########################################################################
	
}

############################################################################
# Main 
#

echo -n "Started LongTail.sh at:"
date

init_variables
read_local_config_file
check_config
#DEBUG=1

SEARCH_FOR="sshd"

if [ "x$1" == "xREBUILD" ] ;then
	run_rebuild=1
	SEARCH_FOR="sshd"
	HTML_DIR="$HTML_DIR/$SSH_HTML_TOP_DIR"
	HTML_TOP_DIR=$SSH_HTML_TOP_DIR
	HOSTNAME="/"
else
	if [ "x$1" == "x" ] ;then
	        echo "No parameters passed, assuming search for all ssh tries on all hosts"
		SEARCH_FOR="sshd"
		HTML_DIR="$HTML_DIR/$SSH_HTML_TOP_DIR"
		HTML_TOP_DIR=$SSH_HTML_TOP_DIR
		shift
	fi
	if [ "x$1" == "xssh" ] ;then
	        echo "ssh passed, assuming search for all ssh tries on all hosts"
		SEARCH_FOR="sshd"
		HTML_DIR="$HTML_DIR/$SSH_HTML_TOP_DIR"
		HTML_TOP_DIR=$SSH_HTML_TOP_DIR
		shift
	fi
	if [ "x$1" == "x22" ] ;then
	        echo "22 passed, searching for just ssh port 22"
		SEARCH_FOR="sshd-22"
		HTML_DIR="$HTML_DIR/$SSH22_HTML_TOP_DIR"
		HTML_TOP_DIR=$SSH22_HTML_TOP_DIR
		shift
	fi
	if [ "x$1" == "x2222" ] ;then
	        echo "2222 passed, searching for just ssh port 2222"
		SEARCH_FOR="sshd-2222"
		HTML_DIR="$HTML_DIR/$SSH2222_HTML_TOP_DIR"
		HTML_TOP_DIR=$SSH2222_HTML_TOP_DIR
		shift
	fi
	if [ "x$1" == "xtelnet" ] ;then
	        echo "telnet passed, searching for telnet"
		SEARCH_FOR="telnet-honeypot"
		HTML_DIR="$HTML_DIR/$TELNET_HTML_TOP_DIR"
		HTML_TOP_DIR=$TELNET_HTML_TOP_DIR
		shift
	fi
	if [ "x$1" == "xhttp" ] ;then
	        echo "http passed, searching for http"
		SEARCH_FOR="http"
		HTML_DIR="$HTML_DIR/$HTTP_HTML_TOP_DIR"
		HTML_TOP_DIR=$HTTP_HTML_TOP_DIR
		shift
	fi
	
	HOSTNAME=$1
	if [ "x$HOSTNAME" != "x" ] ;then
		echo "hostname set to $HOSTNAME"
		shift
	else
		# I'm relying on "//" being the same as "/"
		# in unix :-)
		HOSTNAME="/"
	fi
	if [ "x$1" == "xMIDNIGHT" ] ;then
		echo "Running midnight routines now"
		MIDNIGHT=$START_HOUR
	fi
fi	


declare -A IP_ADDRESS
grep -v UNKNOWN $SCRIPT_DIR/ip-to-country |\
tail -9000 |\
sed 's/^/IP_ADDRESS[/' |sed 's/ /]="/' |\
sed 's/$/"/' >$TMP_DIRECTORY/LongTail.$$.ip.sh
. $TMP_DIRECTORY/LongTail.$$.ip.sh
rm $TMP_DIRECTORY/LongTail.$$.ip.sh

echo "HTML_DIR/HOSTNAME is set to $HTML_DIR/$HOSTNAME"

if [ ! -d $HTML_DIR/$HOSTNAME ] ; then
	echo "Can not find $HTML_DIR/$HOSTNAME making it  now"
	mkdir $HTML_DIR/$HOSTNAME
	chmod a+rx $HTML_DIR/$HOSTNAME
	cp $HTML_DIR/index.shtml $HTML_DIR/$HOSTNAME
	chmod a+r $HTML_DIR/$HOSTNAME/index.shtml
	cp $HTML_DIR/index-long.shtml $HTML_DIR/$HOSTNAME
	chmod a+r $HTML_DIR/$HOSTNAME/index-long.shtml
	cp $HTML_DIR/graphics.shtml $HTML_DIR/$HOSTNAME
	chmod a+r $HTML_DIR/$HOSTNAME/graphics.shtml
fi

HTML_DIR="$HTML_DIR/$HOSTNAME"
echo "HTML_DIR is $HTML_DIR"


# Uncomment out the next two lines to rebuild all the data files
# CREATE A BACKUP OF /var/www/html/honey FIRST, just in case.
# cd /var/www/html/honeyl tar -cf $TMP_DIRECTORY/honey.tar  .
if [ "x$1" == "xREBUILD" ] ;then
	echo "Running rebuild now"
	PROTOCOL=$SEARCH_FOR
	rebuild
	exit
fi

change_date_in_index $HTML_DIR $YEAR

DATE=`date +"%Y-%m-%d"` # THIS IS TODAY

#
# This sets up a default search in case nothing was passed
#
PROTOCOL=$SEARCH_FOR

#This is a manual re-creation of a dated directory
#ssh_attacks $HTML_DIR/historical/2015/03/29 $YEAR "/var/www/html/honey/syrtest/historical/2015/03/29" "2015-03-29"      "$LOGFILE" "current"


#PROTOCOL=$SEARCH_FOR
#ssh_attacks $HTML_DIR/historical/2015/03/30 $YEAR "/var/log" "2015-03-30"      "tmp_messages" "current"
#ssh_attacks $HTML_DIR/historical/2015/03/31 $YEAR "/var/log" "2015-03-31"      "tmp_messages" "current"
#exit
#create_historical_copies  $HTML_DIR
#exit

# Recounting needs to be done here so that the numbers
# show up in this day's graphs made at midnight
if [ $START_HOUR -eq $MIDNIGHT ]; then
	recount_last_30_days_sshpsycho_attacks 
fi

# NOTE: I have to make historical copies (if appropriate) BEFORE
# I call do_ssh so that the reports properly create the
# last 30 days of data charts 
echo "SEARCH_FOR is $SEARCH_FOR"
if [ $SEARCH_FOR == "http" ] ; then
	echo "Searching for http attacks"
	PROTOCOL="LongTail_apache"
	#MIDNIGHT=21
	create_historical_http_copies  $HTML_DIR
	make_http_trends
	do_http
fi
if [ $SEARCH_FOR == "sshd" ] ; then
	echo "Searching for ssh attacks"
	PROTOCOL=$SEARCH_FOR
	create_historical_copies  $HTML_DIR
	make_trends
	do_ssh
fi
if [ $SEARCH_FOR == "sshd-2222" ] ; then
	echo "Searching for ssh 2222 attacks"
	PROTOCOL=$SEARCH_FOR
	create_historical_copies  $HTML_DIR
	make_trends
	do_ssh
fi
if [ $SEARCH_FOR == "telnet-honeypot" ] ; then
	echo "Searching for telnet attacks"
	PROTOCOL=$SEARCH_FOR
	create_historical_copies  $HTML_DIR
	make_trends
	do_ssh
fi

set_permissions  $HTML_DIR 
protect_raw_data $HTML_DIR
set_hosts_protected_flag

make_daily_attacks_chart

if [ "x$HOSTNAME" == "x/" ] ;then
	if [ $SEARCH_FOR == "sshd" ] ; then
		echo "Doing blacklist efficiency tests now"
		make_header "$HTML_DIR/blacklist_efficiency.shtml" "Blacklist Efficiency"  "" 

		/usr/local/etc/LongTail_compare_IP_addresses.pl >> $HTML_DIR/blacklist_efficiency.shtml
		make_footer "$HTML_DIR/blacklist_efficiency.shtml"
	
		make_header "$HTML_DIR/password_analysis_todays_passwords.shtml" "Password Analysis of Today's Passwords"  "" 
		$SCRIPT_DIR/LongTail_password_analysis_part_1.pl $HTML_DIR/todays_passwords >> $HTML_DIR/password_analysis_todays_passwords.shtml
		make_footer "$HTML_DIR/password_analysis_todays_passwords.shtml"
	
		if [ $START_HOUR -eq $MIDNIGHT ]; then
			/usr/local/etc/LongTail_make_30_days_imagemap.pl >$HTML_DIR/30_days_imagemap.html
		fi

		if [ $START_HOUR -eq $MIDNIGHT ]; then
			awk '{print length, $0}' $HTML_DIR/all-password | sort -n | cut -d " " -f2- |tail -2000 >$HTML_DIR/2000-longest-passwords.txt

			make_header "$HTML_DIR/password_analysis_all_passwords.shtml" "Password Analysis of All Passwords"  "" 
			$SCRIPT_DIR/LongTail_password_analysis_part_1.pl $HTML_DIR/all-password >> $HTML_DIR/password_analysis_all_passwords.shtml
			make_footer "$HTML_DIR/password_analysis_all_passwords.shtml"
	
			make_header "$HTML_DIR/password_list_analysis_all_passwords.shtml" "Password vs Wordlist Analysis"  "" 
	
			echo "<P>This is a comparison of passwords used vs several publicly available" >> $HTML_DIR/password_list_analysis_all_passwords.shtml
			echo "lists of passwords." >> $HTML_DIR/password_list_analysis_all_passwords.shtml
			echo "<BR><BR>" >> $HTML_DIR/password_list_analysis_all_passwords.shtml
			$SCRIPT_DIR/LongTail_password_analysis_part_2.pl $HTML_DIR/all-password >> $HTML_DIR/password_list_analysis_all_passwords.shtml
			make_footer "$HTML_DIR/password_list_analysis_all_passwords.shtml"

#			make_header "$HTML_DIR/first_seen_ips.shtml" "First Occurence of an IP Address"  "" 
#			echo "</TABLE>" >> $HTML_DIR/first_seen_ips.shtml
#			$SCRIPT_DIR/LongTail_find_first_password_use.pl ips >> $HTML_DIR/first_seen_ips.shtml
#			make_footer "$HTML_DIR/first_seen_ips.shtml"

			make_header "$HTML_DIR/first_seen_usernames.shtml" "First Occurence of an Username"  "" 
			echo "</TABLE>" >> $HTML_DIR/first_seen_usernames.shtml
			$SCRIPT_DIR/LongTail_find_first_password_use.pl usernames >> $HTML_DIR/first_seen_usernames.shtml
			make_footer "$HTML_DIR/first_seen_usernames.shtml"

			make_header "$HTML_DIR/first_seen_passwords.shtml" "First Occurence of a Password"  "" 
			echo "</TABLE>" >> $HTML_DIR/first_seen_passwords.shtml
			echo "<PRE>" >> $HTML_DIR/first_seen_passwords.shtml
			$SCRIPT_DIR/LongTail_find_first_password_use.pl passwords >> $HTML_DIR/first_seen_passwords.shtml
			echo "</PRE>" >> $HTML_DIR/first_seen_passwords.shtml
			make_footer "$HTML_DIR/first_seen_passwords.shtml"
			if [ -e  $HTML_DIR/first_seen_passwords.shtml.gz ] ; then
				/bin/rm $HTML_DIR/first_seen_passwords.shtml.gz
			fi 
			gzip $HTML_DIR/first_seen_passwords.shtml
			make_header "$HTML_DIR/class_c_hall_of_shame.shtml" "Class C Hall Of Shame"  "Top 10 worst offending Class C subnets sorted by the number of attack patterns.  Class C subnets must have over 10,000 login attempts to make this list." 
			`$SCRIPT_DIR/LongTail_class_c_hall_of_shame.pl >>/$HTML_DIR/class_c_hall_of_shame.shtml`;
			make_footer "$HTML_DIR/class_c_hall_of_shame.shtml" 

			make_header "$HTML_DIR/class_c_list.shtml" "List of Class C subnets sorted by the number of attack patterns. "  ""
			`$SCRIPT_DIR/LongTail_class_c_hall_of_shame.pl  "ALL" >>/$HTML_DIR/class_c_list.shtml`;
			make_footer "$HTML_DIR/class_c_list.shtml" 
		fi
	fi

#	if [ $START_HOUR -eq $MIDNIGHT ]; then
#		echo -n "Starting LongTail_class_c_hall_of_shame.pl now "; date
#		make_header "$HTML_DIR/class_c_list.shtml" "List of Class C "  "Class C subnets sorted by the number of attack patterns."
#		`$SCRIPT_DIR/LongTail_class_c_hall_of_shame.pl  "ALL" >>/$HTML_DIR/class_c_list.shtml`;
#		make_footer "$HTML_DIR/class_c_list.shtml" 
#	fi


fi

if [ "x$HOSTNAME" == "x/" ] ; then
	if [ $SEARCH_FOR == "sshd" ] ; then
		echo -n "Starting sshPsycho analysis now :-) " ; date
		if [ $DEBUG  == 1 ] ; then echo "DEBUG-Doing SSHPsycho report now" ; fi
		if [ $HTML_DIR/SSHPsycho.shtml -ot $HTML_DIR/attacks/sum2.data ] ; then
			echo "$HTML_DIR/SSHPsycho.shtml is older than $HTML_DIR/attacks/sum2.data, running SSHPsycho.shtml"
			#ls -l $HTML_DIR/SSHPsycho.shtml  $HTML_DIR/attacks/sum2.data 
			make_header "$HTML_DIR/SSHPsycho.shtml" "SSHPsycho Attacks"
			/usr/local/etc/LongTail_local_reports/SSHPsycho.pl >> $HTML_DIR/SSHPsycho.shtml
			make_footer "$HTML_DIR/SSHPsycho.shtml"
		else
			echo "$HTML_DIR/SSHPsycho.shtml is younger than $HTML_DIR/attacks/sum2.data, notrunning SSHPsycho.shtml"
			#ls -l $HTML_DIR/SSHPsycho.shtml  $HTML_DIR/attacks/sum2.data 
		fi
		echo -n "Done with sshPsycho analysis now: "; date
	fi
fi 

cd $HTML_DIR/historical
TMP_DATE=`date +"%Y-%m-%d"`

if [ $SEARCH_FOR == "sshd" ] ; then
	echo -n "Calling count_sshpsycho_attacks: "; date
	count_sshpsycho_attacks
	echo -n "Back from Calling count_sshpsycho_attacks: "; date
fi

echo -n "Calling lock_down_files: "; date
lock_down_files 
echo -n "Back from lock_down_files: "; date

echo -n "Done with LongTail.sh at:"
date

exit
