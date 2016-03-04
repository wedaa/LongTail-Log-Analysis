#!/usr/bin/perl

############################################################################
#
# Design note: I am PERFECTLY willing to trade using more disk space in 
# order to speed things up.
#
# This is my crontab entry
# 05 * * * * /usr/local/etc/LongTail.pl >> /tmp/LongTail.pl.out 2>> /tmp/LongTail.pl.out
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
#	/usr/local/etc/LongTail.pl 
#
# gets all hosts and looks for all ssh activity
#	/usr/local/etc/LongTail.pl ssh
#
# gets all hosts and looks for all ssh only on port 22 activity
#	/usr/local/etc/LongTail.pl 22
#
# gets all hosts and looks for all ssh only on port 2222 activity
#	/usr/local/etc/LongTail.pl 2222
#
# gets all hosts and looks for telnet activity
#	/usr/local/etc/LongTail.pl telnet
#
# If you are looking for a specific host, you MUST include the protocol
# to search for
# gets all hosts and looks for all ssh activity
#	/usr/local/etc/LongTail.pl ssh HOSTNAME
#
# gets all hosts and looks for all ssh only on port 22 activity
#	/usr/local/etc/LongTail.pl 22 HOSTNAME
#
# gets all hosts and looks for all ssh only on port 2222 activity
#	/usr/local/etc/LongTail.pl 2222 HOSTNAME
#
# gets all hosts and looks for telnet activity
#	/usr/local/etc/LongTail.pl telnet HOSTNAME
#
#
# LongTail.pl is not fully tested yet :-)
#
############################################################################
# This reads /usr/local/etc/LongTail.config.  If your file isn't there,
# then this is the only place you need to edit.

############################################################################
## Touch a file
sub touch {
	my $now = time;
	my $file=shift;
	local (*TMP);
	utime ($now, $now, $file)
	|| open (TMP, ">>$file")
	|| warn ("Couldn't touch file: $!\n");
}

sub commify {
	my ( $sign, $int, $frac ) = ( $_[0] =~ /^([+-]?)(\d*)(.*)/ );
	my $commified = (
	reverse scalar join ',',
	unpack '(A3)*',
	scalar reverse $int
	);
	return $sign . $commified . $frac;
}

sub read_local_config_file {
	if ( -e "$CONFIG_FILE" ) {
		open (INPUT, "$CONFIG_FILE");
		while (<INPUT>){
			chomp;
			$_ =~ s/#.*//;
			$_ =~ s/\s//g;
			$_ =~ s/"//g;
			if (/^$/){next;}
			if (! /=/){next;}
			#print "$_\n";;
			($variable,$value)=split(/=/,$_);
			#if ( $DEBUG  == 1 ) { print "DEBUG-variable=$variable,value=$value\n" ; }
			if ($variable eq "PUBLIC_WEBSERVER"){$PUBLIC_WEBSERVER=$value;next;}
			if ($variable eq "MIDNIGHT"){$MIDNIGHT=$value;next;}
			if ($variable eq "GRAPHS"){$GRAPHS=$value;next;}
			if ($variable eq "KIPPO"){$KIPPO=$value;next;}
			if ($variable eq "LONGTAIL"){$LONGTAIL=$value;next;}
			if ($variable eq "PATH_TO_VAR_LOG"){$PATH_TO_VAR_LOG=$value;next;}
			if ($variable eq "LOGFILE"){$LOGFILE=$value;next;}
			if ($variable eq "PATH_TO_VAR_LOG_HTTPD"){$PATH_TO_VAR_LOG_HTTPD=$value;next;}
			if ($variable eq "DEBUG"){$DEBUG=$value;next;}
			if ($variable eq "DO_SSH"){$DO_SSH=$value;next;}
			if ($variable eq "DO_HTTPD"){$DO_HTTPD=$value;next;}
			if ($variable eq "OBFUSCATE_IP_ADDRESSES"){$OBFUSCATE_IP_ADDRESSES=$value;next;}
			if ($variable eq "OBFUSCATE_URLS"){$OBFUSCATE_URLS=$value;next;}
			if ($variable eq "PASSLOG"){$PASSLOG=$value;next;}
			if ($variable eq "PASSLOG2222"){$PASSLOG2222=$value;next;}
			if ($variable eq "TMP_DIRECTORY"){$TMP_DIRECTORY=$value;next;}
			if ($variable eq "SCRIPT_DIR"){$SCRIPT_DIR=$value;next;}
			if ($variable eq "HTML_DIR"){$HTML_DIR=$value;next;}
			if ($variable eq "SSH_HTML_TOP_DIR"){$SSH_HTML_TOP_DIR=$value;next;}
			if ($variable eq "SSH22_HTML_TOP_DIR"){$SSH22_HTML_TOP_DIR=$value;next;}
			if ($variable eq "SSH2222_HTML_TOP_DIR"){$SSH2222_HTML_TOP_DIR=$value;next;}
			if ($variable eq "TELNET_HTML_TOP_DIR"){$TELNET_HTML_TOP_DIR=$value;next;}
			if ($variable eq "RLOGIN_HTML_TOP_DIR"){$RLOGIN_HTML_TOP_DIR=$value;next;}
			if ($variable eq "FTP_HTML_TOP_DIR"){$FTP_HTML_TOP_DIR=$value;next;}
			if ($variable eq "CONSOLIDATION"){$CONSOLIDATION=$value;next;}
			if ($variable eq "PROTECT_RAW_DATA"){$PROTECT_RAW_DATA=$value;next;}
			if ($variable eq "NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA"){$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA=$value;next;}
		}
		close (INPUT);
	}
}

sub check_config {
	if ( $DEBUG  == 1 ) { print "DEBUG-in check_config\n" ; }

  if ( ! -d "$PATH_TO_VAR_LOG" ){
    print "$PATH_TO_VAR_LOG does not exist, exiting now\n";
    exit;
  }
  if ( ! -e "$PATH_TO_VAR_LOG/$LOGFILE" ){
    print "$PATH_TO_VAR_LOG/$LOGFILE does not exist, exiting now\n";
    exit;
  }
  if ( ! -d "$PATH_TO_VAR_LOG_HTTPD" ){
    print "$PATH_TO_VAR_LOG_HTTPD does not exist, exiting now\n";
    exit;
  }
  if ( ! -d "$SCRIPT_DIR" ){
    print "Can not find SCRIPT_DIR: $SCRIPT_DIR, exiting now\n";
    exit;
  }
  if ( ! -d "$HTML_DIR" ){
    print "Can not find HTML_DIR: $HTML_DIR, exiting now\n";
    exit;
  }
  if ( ! -d "$TMP_DIRECTORY" ){
    print "Can not find TMP_DIRECTORY $TMP_DIRECTORY, exiting now\n";
    exit;
  }

	if ( ! -r "$PATH_TO_VAR_LOG/$LOGFILE" ){
		print "Can not read $PATH_TO_VAR_LOG/$LOGFILE, please check file permissions\n";
		print "Exiting now\n";
		exit;
	}

  $rsyslog_format_check=`tail -1 $PATH_TO_VAR_LOG/$LOGFILE |awk '{print $1}'`;
	chomp $rsyslog_format_check;
  $rsyslog_format_check_exit=0;
  if ( $rsyslog_format_check eq "Jan" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Feb" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Mar" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Apr" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "May" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Jun" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Jul" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Aug" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Sep" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Oct" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Nov" ){ $rsyslog_format_check_exit=1 ; }
  if ( $rsyslog_format_check eq "Dec" ){ $rsyslog_format_check_exit=1 ; }

  if ( $rsyslog_format_check_exit == 1 ){ 
    print "$PATH_TO_VAR_LOG/$LOGFILE file appears to have the wrong style data stamp (monthName vs YYYY-MM-DD format) Please see the README again.\n";
    print "rsyslog format line should be \"\$ActionFileDefaultTemplate RSYSLOG_FileFormat\"\n";
    print "You will have to edit $PATH_TO_VAR_LOG/$LOGFILE by hand to fix the formating or start with a fresh $PATH_TO_VAR_LOG/$LOGFILE file\n";
    exit;
  }
	if ( $DEBUG  == 1 ) { print "DEBUG-Done with check_config\n" ; }

}

sub load_exclude_files {
	open (FILE, "$SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep ")|| die "Can not read $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep, exiting now!\n";
	while (<FILE>){
		chomp;
		$_ =~ s/\./\\\./g;
		$LongTail_exclude_IPs_ssh_grep{$_}=1;
	}
	close (FILE);
	open (FILE, "$SCRIPT_DIR/LongTail-exclude-accounts.grep ")|| die "Can not read $SCRIPT_DIR/LongTail-exclude-accounts-ssh.grep, exiting now!\n";
	while (<FILE>){
		chomp;
		$_ =~ s/\./\\\./g;
		$LongTail_exclude_accounts_ssh_grep{$_}=1;
	}
	close (FILE);
}



# This sub is called as 
# NEW_STRING=$(convert_kippo_to_longtail "$STRING")
# STRING should look like
# 2015-05-10 18:05:31-0400 [SSHService ssh-userauth on HoneyPotTransport,16534,58.218.204.52] login attempt [root/skata1] failed
sub convert_kippo_to_longtail {
  $STRING=shift;
	$STRING=~ s/ /T/;
  $STRING =~ s/.SSHService ssh-userauth on HoneyPotTransport,.*,//;
  $STRING =~ s/\]/ /;
  $STRING =~ s/\] failed$//;
  $STRING =~ s/\[// ;
  $STRING =~ s/ / LOCALHOST sshd-22[9999]: IP: /;
  $STRING =~ s/login attempt/PassLog: Username:/;
  $STRING =~ s/\// Password: /;
  return $STRING;
}


sub lock_down_files {
	if ( "x$HOSTNAME" eq "x/" ) {
		if ( -d "$HTML_DIR" ) { 
		chdir ("$HTML_DIR");

		print "Expect to see chmod warnings until you have run LongTail for at least 24 hours\n";

		`find . -name last-7-days-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA  -o -name last-7-days-non-root-pairs.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name last-30-days-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name last-30-days-non-root-pairs.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name historical-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name historical-non-root-pairs.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA | xargs chmod go-r`;
		`find . -name todays_password -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name current-root-passwords.shtml.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name current-non-root-passwords.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA | xargs chmod go-r`;
		`find . -name current-account-password-pairs.data.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -o -name current-admin-passwords.shtml -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA | xargs chmod go-r`;
		}
	}
}

############################################################################
# Assorted Variables, you should probably edit /usr/local/etc/LongTail.config
# though...  Otherwise when you install a new version you'll lose your
# configuration
#
sub init_variables {
	# Is this a public webserver?  If so then we need to protect
	# certain webpages so they are not seen by the badguys.  We
	# have to do this in order to hide what the current "Hot" or
	# "Desirable" account and password combinations are
	#
	# Do not assume that just because your page isn't indexed
	# by Google that your webpage is private.
	#
	# Set it to 1 if it is public, or 0 if it is private.
 $PUBLIC_WEBSERVER=1;

	# Do you want Pretty graphs using jpgraph?  Set this to 1
	# http://jpgraph.net/  JpGraph - Most powerful PHP-driven charts
	$GRAPHS=1;

	# Which honeypot are you running?  Uncomment only ONE of the following
	#$KIPPO=1 ; $LONGTAIL=0; # This is for the Kippo honeypot
	$KIPPO=0 ; $LONGTAIL=1; # This is for the LongTail honeypot
	
	#Where is the messages file?  Uncomment only ONE of the following
	$PATH_TO_VAR_LOG="/var/log/" ;# Typically for messages file from ryslog
	#$PATH_TO_VAR_LOG="/usr/local/kippo-master/log/" ;# One place for kippo
	#$PATH_TO_VAR_LOG="/var/log/kippo/" ;# another place for kippo

	if ( ! -d $PATH_TO_VAR_LOG ) {
		print "$PATH_TO_VAR_LOG does not exist, exiting now\n";
		exit;
	}

	# What is the name of the default log file
	$LOGFILE="messages";
	#$LOGFILE="kippo.log";
	
	if ( ! -e "$PATH_TO_VAR_LOG/$LOGFILE" ) {
		print "$PATH_TO_VAR_LOG/$LOGFILE does not exist, exiting now\n";
		exit;
	}
	
	#Where is the apache access_log file?
	$PATH_TO_VAR_LOG_HTTPD="/var/log/httpd/";
	if ( ! -d "$PATH_TO_VAR_LOG_HTTPD" ) {
		print "$PATH_TO_VAR_LOG_HTTPD does not exist, exiting now\n";
		exit;
	}

	# Do you want debug output?  Set this to 1
	$DEBUG=1;
	
	# Do you want ssh analysis?  Set this to 1
	$DO_SSH=1;
	
	# Do you want httpd analysis?  Set this to 1
	$DO_HTTPD=1;
	
	# Do we obfuscate/rename the IP addresses?  You might want to do this if
	# you are copying your reports to a public site.
	# $OBFUSCATE_IP_ADDRESSES=1 ;will hide addresses
	# $OBFUSCATE_IP_ADDRESSES=0; will NOT hide addresses
	$OBFUSCATE_IP_ADDRESSES=0;
	
	# $OBFUSCATE_URLS=1 will hide URLs in the http report
	# $OBFUSCATE_URLS=0 will NOT hide URLs in the http report
	# This may not work properly yet.
	$OBFUSCATE_URLS=0;
	
	# These are the search strings from the "LogIt" sub in auth-passwd.c
	# and are used to figure out which ports are being brute-forced.
	# The code for PASSLOG2222 has not yet been written.
	$PASSLOG="PassLog";
	$PASSLOG2222="Pass2222Log";

	# Where do we put the temporary files
	$TMP_DIRECTORY="/data/tmp";
	
	# Where are the scripts we need to run?
	$SCRIPT_DIR="/usr/local/etc/";
	if ( ! -d $SCRIPT_DIR ) {
		print "Can not find SCRIPT_DIR: $SCRIPT_DIR, exiting now\n";
		exit;
	}
	
	# Where do we put the reports?
	$HTML_DIR="/var/www/html";
	if ( ! -d $HTML_DIR ) {
		print "Can not find HTML_DIR: $HTML_DIR, exiting now\n";
		exit;
	}
	# What's the top level directory?
	$SSH_HTML_TOP_DIR="honey"; #NO slashes please, it breaks sed
	$SSH22_HTML_TOP_DIR="honey-22"; #NO slashes please, it breaks sed
	$SSH2222_HTML_TOP_DIR="honey-2222"; #NO slashes please, it breaks sed
	$TELNET_HTML_TOP_DIR="telnet"; #NO slashes please, it breaks sed
	$RLOGIN_HTML_TOP_DIR="rlogin"; #NO slashes please, it breaks sed
	$FTP_HTML_TOP_DIR="ftp"; #NO slashes please, it breaks sed
	
	# This is for my personal debugging, just leave them
	# commented out if you aren't me.
	#$PATH_TO_VAR_LOG="/home/wedaa/source/LongTail/var/log/";
	#$PATH_TO_VAR_LOG_HTTPD="/home/wedaa/source/LongTail/var/log/httpd/";

 	# Is this a consolidation server?  (A server that
 	# processes many servers results AND makes individual
 	# reports for each server).
 	$CONSOLIDATION=0;
	
	# What hosts are protected by a firewall or Intrusion Detection System?
	# This is used to set the current-attack-count.data.notfullday flag 
	# in those directories to help "normalize" the data
	if ( `hostname` eq "longtail.it.marist.edu" ) {
		$HOSTS_PROTECTED="erhp erhp2";
		$BLACKRIDGE="blackridge";
		$RESIDENTIAL_SITES="shepherd";
		$EDUCATIONAL_SITES="syrtest edub edu_c";
		$CLOUD_SITES="cloud_v cloud_c";
		$BUSINESS_SITES="";
	}
	else {
		$HOSTS_PROTECTED="";
		$BLACKRIDGE="";
		$RESIDENTIAL_SITES="";
		$EDUCATIONAL_SITES="";
		$CLOUD_SITES="";
		$BUSINESS_SITES="";
	}
 
	
	# Do we protect the raw data, and for how long?
	# $PROTECT_RAW_DATA=1 will protect raw data
	# $PROTECT_RAW_DATA=0 will NOT protect raw data
	$PROTECT_RAW_DATA=1;
	$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA=90;

	
	############################################################################
	# You don't need to edit after this.
	#
	$TODAY_AT_START_OF_RUNTIME=`date`;
	$YEAR=`date +%Y`;
	chomp $YEAR;
	$HOUR=`date +%H` ;# This is used at the end of the program but we want to know it NOW
	chomp $HOUR;
	$START_HOUR=`date +%H`; # This is used at the end of the program but we want to know it NOW
	chomp $START_HOUR;
	$YEAR_AT_START_OF_RUNTIME=`date +%Y`;
	chomp $YEAR_AT_START_OF_RUNTIME;
	$MONTH_AT_START_OF_RUNTIME=`date +%m`;
	chomp $MONTH_AT_START_OF_RUNTIME;
	$DAY_AT_START_OF_RUNTIME=`date +%d`;
	chomp $DAY_AT_START_OF_RUNTIME;
	$REBUILD=0;
	$MIDNIGHT=0;
	$ONE_AM=1;

	# Load the IP addresses we have seen here
	open (INPUT, "tail -9999 $SCRIPT_DIR/ip-to-country|");
	while (<INPUT>){
		if (/UNKNOWN/){next;}
		chomp;
		($ip,$country)=split(/ /,$_,2);
		$IP_ADDRESS{$ip}=$country;
	}
	close (INPUT);
}

############################################################################
# Lets make sure we can write to the directory
#
sub is_directory_good {
	my $dir=shift;
	if ( ! -d "$dir"  ) {
		print "$dir is not a directory, exiting now \n";
		exit
	}
	if ( ! -w "$dir"  ) {
		print "I can't write to $dir, exiting now\n";
		exit;
	}
}

############################################################################
# Lets make sure we can write to the directory
#
sub is_file_good {
	my $file=shift;
	if ( ! -e "$file"  ) {
		print "DANGER DANGER DANGER\n";
		print "$file does not exist, exiting now \n";
		exit;
	}
	if ( ! -w $file  ) {
		print "DANGER DANGER DANGER\n";
		print "I can't write to $file, exiting now\n";
		exit;
	}
}


############################################################################
# Change the date in index.shtml

sub change_date_in_index {
	my $DATE=$datestring=localtime(); 
	print $datestring;;
	my $dir=shift;
	print "DEBUG in change_date_in_index, dir is $dir";

	&is_file_good ("$dir/index.shtml");
	&is_file_good ("$dir/index-long.shtml");
	&is_file_good ("$dir/graphics.shtml");
	`sed -i "s/updated on..*\$/updated on $DATE/" $dir/index.shtml`;
	`sed -i "s/updated on..*\$/updated on $DATE/" $dir/index-long.shtml`;
	`sed -i "s/updated on..*\$/updated on $DATE/" $dir/graphics.shtml`;
}


############################################################################
# Make a proper HTML header for assorted columns
#
sub make_header {
	# first argument, the full path including the filename you want to write to
	# second argument, the title of the web page
	# Third argument, text for description
	# Other arguments are the column headers
	# NOTE: This destroys $MAKE_HEADER_FILENAME before adding to it.
	my $tmp;
	my $MAKE_HEADER_DATE;
	my $MAKE_HEADER_FILENAME;
	my $TITLE;
	my $DESCRIPTION;

	$MAKE_HEADER_DATE=`date`;
	chomp $MAKE_HEADER_DATE;
#	if ( "$#" == "0" ) {
#		print "You forgot to pass arguments, exiting now\n";
#		exit 1;
#	}
	$MAKE_HEADER_FILENAME=shift;
	&touch ($MAKE_HEADER_FILENAME);
	if ( ! -w $MAKE_HEADER_FILENAME ) {
		print "Can't write to $MAKE_HEADER_FILENAME, exiting now\n";
		exit;
	}
	
	$TITLE= shift;
	
	$DESCRIPTION= shift;

	open (FILE, ">$MAKE_HEADER_FILENAME") || die "Can not write to $MAKE_HEADER_FILENAME\n";
	print (FILE "<HTML><!--HEADERLINE -->\n" );
	print (FILE "<HEAD><!--HEADERLINE -->\n" );
	print (FILE "<META http-equiv=\"pragma\" content=\"no-cache\"><!--HEADERLINE -->\n" );
	print (FILE "<TITLE>LongTail Log Analysis $TITLE</TITLE> <!--HEADERLINE -->\n" );
	print (FILE "<style> /* HEADERLINE */ \n" );
	print (FILE ".td-some-name /* HEADERLINE */ \n" );
	print (FILE "{ /* HEADERLINE */ \n" );
	print (FILE "  white-space:nowrap; /* HEADERLINE */ \n" );
	print (FILE "  vertical-align:top; /* HEADERLINE */ \n" );
	print (FILE "} /* HEADERLINE */ \n" );
	print (FILE "</style> <!--HEADERLINE --> \n" );

	print (FILE "</HEAD><!--HEADERLINE -->\n" );
	print (FILE "<BODY BGCOLOR=#00f0FF><!--HEADERLINE -->\n" );
	print (FILE "<!--#include virtual=\"/$HTML_TOP_DIR/header.html\" --> <!--HEADERLINE --> \n" );
	print (FILE "<H1>LongTail Log Analysis</H1><!--HEADERLINE -->\n" );
	print (FILE "<H3>$TITLE</H3><!--HEADERLINE -->\n" );
	print (FILE "<P>$DESCRIPTION <!--HEADERLINE -->\n" );
	print (FILE "<P>Created on $MAKE_HEADER_DATE<!--HEADERLINE -->\n" );
	
	print (FILE "<TABLE border=1><!--HEADERLINE -->\n" );
	print (FILE "<TR><!--HEADERLINE -->\n" );
	while ( $tmp=shift ) {
#print "DEBUG make_header columns now, this column is $tmp\n";
		print (FILE "<TH>$tmp</TH><!--HEADERLINE -->\n" );
	}
	print (FILE "</TR><!--HEADERLINE -->\n" );
	close (FILE);
}

############################################################################
# Make a proper HTML footer for assorted columns
#
sub make_footer {
	# One argument, the full path including the filename you want to write to
#	if ( "$#" == "0" ) {
#		print "You forgot to pass arguments, exiting now\n";
#		exit 1;
#	}
	$MAKE_FOOTER_FILENAME=shift;
	&touch ($MAKE_FOOTER_FILENAME);
	if ( ! -w $MAKE_FOOTER_FILENAME ) {
		print "Can't write to $MAKE_FOOTER_FILENAME, exiting now\n";
		exit 1;
	}
	open (FILE, ">> $MAKE_FOOTER_FILENAME");
	print (FILE "\n" );
	print (FILE  "</TABLE><!--HEADERLINE -->" );
	print (FILE "<!--#include virtual=\"/$HTML_TOP_DIR/footer.html\" --> <!--HEADERLINE --> ");
	print (FILE "</BODY><!--HEADERLINE -->" );
	print (FILE "</HTML><!--HEADERLINE -->" );
}


############################################################################
# Count ssh attacks and modify $HTML_DIR/index.html
#
# Called as count_ssh_attacks $HTML_DIR $PATH_TO_VAR_LOG "messages*"
#
sub count_ssh_attacks {
	use List::Util qw(max min sum);
	if ( $DEBUG  == 1 ) { print "DEBUG-in count_ssh_attacks now\n" ; }
	$TMP_HTML_DIR=shift;
	$PATH_TO_VAR_LOG=shift;
	$MESSAGES=shift;

	$ORIGINAL_DIRECTORY=`pwd`;
	chomp $ORIGINAL_DIRECTORY;

	$TMP_DATE=`date +%Y-%m-%d`;
	chomp $TMP_DATE;
	$TMP_YEAR=`date +%Y`;
	chomp $TMP_YEAR;
	$TMP_MONTH=`date +%m`;
	chomp $TMP_MONTH;
	$TMP_DAY=`date +%d`;
	chomp $TMP_DAY;
	#
	# Lets make sure we have one for today and this month and this year
	$TMP_DIR=$TMP_HTML_DIR;
	if ( ! -d "$TMP_DIR"  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR;` }

	$TMP_DIR="$TMP_HTML_DIR/historical";
	if ( ! -d "$TMP_DIR"  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR;` }

	$TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR";
	if ( ! -d "$TMP_DIR"  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR;` }

	$TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH";
	if ( ! -d "$TMP_DIR"  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR;` }

	$TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY";
	if ( ! -d "$TMP_DIR"  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR;` }

	$list="$HOSTS_PROTECTED $BLACKRIDGE";
	while ($list =~ s/  / /g){}
	$count=@my_word_list=split(/ /,$list);
	#print "count is $count\n";
	if ($count >0){
		foreach (@my_word_list) {
			chomp;
			$dir=$_;
			if ( "x$HOSTNAME" eq "x$dir" ) {
				&touch ("$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday");
				#print "$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/ \n";
			}
		}
	}
	#
	# Why did I add this line?
	# This makes sure the current day exists and is set to no data ?
  # But why am I creating this file later?
  # So I commented out the if statement so I ALWAYS clear the current data.
	#if ( ! -e "$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz" ) {
		`echo "" |gzip -c > $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz`;
		`chmod a+r $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz`;
	#}


	#
	# TODAY
	#
	if ( $DEBUG  == 1 ) { print "DEBUG-in count_ssh_attacks/TODAY now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	# WHY WAS THIS HERE? 2015-12-29 chdir ("$PATH_TO_VAR_LOG");
	chdir ("$HTML_DIR");
	if ( "x$HOSTNAME" eq "x/" ) {
		if ( $LONGTAIL == 1 ) {
				$TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`;
				chomp $TODAY;
		}
		if ( $KIPPO == 1 ) {
			$TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt|wc -l`;
				chomp $TODAY;
		}
	}
	else { # We were passed a hostname.  This should never happen with Kippo
		if ( $KIPPO == 1 ) {
			print "LongTail is only for single instances of Kippo.  You passed a hostname to LongTail.pl";
			print "Exiting now\n";
			exit;
		}
		$TODAY=`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '\$2 == \"$HOSTNAME\" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`;
			chomp $TODAY;
	}
	`echo  $TODAY > $TMP_HTML_DIR/current-attack-count.data`;
print "\n\nDEBUG TODAY is $TODAY\n\n";


	if ( $START_HOUR == $MIDNIGHT ) {
		#
		# THIS MONTH
		#
		chdir ("$TMP_HTML_DIR/historical/");
		if ( $DEBUG  == 1 ) {
			print "Its midnight, doing midnight stuff\n";
			print "\n\nDEBUG Tried to chdir to $TMP_HTML_DIR/historical/\n\n";
		}
		if ( $DEBUG  == 1 ) { print  "DEBUG-in count_ssh_attacks-This Month now\n"  }
		$TMP=0;
		open (FIND, "find $TMP_YEAR/$TMP_MONTH -name current-attack-count.data|");
		while (<FIND>){
			chomp;
			open (FILE, "$_");
			while (<FILE>){
				chomp;
				$COUNT=$_;
			}
			close (FILE);
			$TMP+=$COUNT;
		}
		close (FIND);
		$THIS_MONTH=$TMP + $TODAY ;
		# OK, this may not be 100% secure, but it's close enough for now
		if ( $DEBUG  == 1 ) { print  "DEBUG this month statistics;" ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		#
		# So there's a problem if it's the first day of the month and there's
		# No real statistics yet.
		#
		if ( -e "$TMP_YEAR/$TMP_MONTH" ) { 
			if ( $DEBUG  == 1 ) { print "DEBUG-in count_ssh_attacks/This Month/Statistics now\n" ; }
			@a=();
			$tmp_count=0;
			open (FIND, "find $TMP_YEAR/$TMP_MONTH/*/current-attack-count.data|");
			while(<FIND>){
				open (FILE, $_);
				while (<FILE>){
					$sqsum+=$_*$_; push(@a,$_)
				}
				close (FILE);
				$tmp_count++;
			}; 
			if ($tmp_count>0){
				$n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}; $n; 
				$MONTH_COUNT=$n;;
				$MONTH_SUM=$s;;
				$MONTH_AVERAGE=$a;
				$MONTH_STD=$std;
				$MONTH_MEDIAN=$med;
				$MONTH_MAX=$m;
				$MONTH_MIN=$mm;
			
				$MONTH_AVERAGE=sprintf "%.2f",$MONTH_AVERAGE;
				$MONTH_STD=sprintf "%.2f",$MONTH_STD;
			} else {
				$MONTH_COUNT=1;
				$MONTH_SUM=$TODAY;
				$MONTH_AVERAGE=$TODAY;
				$MONTH_STD=0;
				$MONTH_MEDIAN=$TODAY;
				$MONTH_MAX=$TODAY;
				$MONTH_MIN=$TODAY;
				#MONTH_AVERAGE=`printf '%.2f' 0`
				$MONTH_STD=0;
			}
		} else {
			$MONTH_COUNT=1;
			$MONTH_SUM=$TODAY;
			$MONTH_AVERAGE=$TODAY;
			$MONTH_STD=0;
			$MONTH_MEDIAN=$TODAY;
			$MONTH_MAX=$TODAY;
			$MONTH_MIN=$TODAY;
			#MONTH_AVERAGE=`printf '%.2f' 0`
			$MONTH_STD=0;
		}
		
	
		$MONTH_COUNT=&commify("$MONTH_COUNT");
		$MONTH_SUM=&commify("$MONTH_SUM");
		$MONTH_AVERAGE=&commify("$MONTH_AVERAGE");
		$MONTH_STD=&commify("$MONTH_STD");
		$MONTH_MEDIAN=&commify("$MONTH_MEDIAN");
		$MONTH_MAX=&commify("$MONTH_MAX");
		$MONTH_MIN=&commify("$MONTH_MIN");
	
	
		#
		# LAST MONTH
		#
		print "DEBUG trying to chdir to $TMP_HTML_DIR/historical/\n";
		chdir ("$TMP_HTML_DIR/historical/");
		if ( $DEBUG  == 1 ) { print  "DEBUG-in count_ssh_attacks/Last Month now \n"  }
	#
	# Gotta fix this for the year boundary
	#
		$TMP_LAST_MONTH=`date "+%m" --date="last month"`;
		chomp $TMP_LAST_MONTH;
		$TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`;
		chomp $TMP_LAST_MONTH_YEAR;
		$TMP=0;
		print "DEBUG LAST MONTH $TMP_LAST_MONTH $TMP_LAST_MONTH_YEAR\n";
	
		if ( -d $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH ){
		open (FIND, "find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name current-attack-count.data|") ||
			die "Can't run find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name current-attack-count.data, exiting now\n";
		while (<FIND>){
			chomp;
			open (FILE, "$_");
			while (<FILE>){
				chomp;
				$COUNT=$_;
			}
			close (FILE);
			$TMP+=$COUNT;
		}
		close (FIND);
		}
		$LAST_MONTH=$TMP;
		# OK, this may not be 100% secure, but it's close enough for now
		if ( $DEBUG  == 1 ) { print  "DEBUG Last month statistics :" ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; ;  }
		#
		# So there's a problem if it's the first day of the month and there's
		# No real statistics yet.
		#
		#
		# Gotta do the date calculation to figure out "When" is last month
		#
		print "DEBUG-1\n"; `$date`;
		if ( -d "$TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH" ) { 
			if ( $DEBUG  == 1 ) { print "DEBUG-in count_ssh_attacks/Last Month/statistics now:" ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	
			@a=();
			open (FIND, "find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/*/current-attack-count.data|");
			while(<FIND>){
				open (FILE, $_);
				while (<FILE>){
					$sqsum+=$_*$_; push(@a,$_)
				}
				close (FILE);
			} 
			close (FIND);
			$n=@a;
			$s=sum(@a);
			if ( @a) {$a=$s/@a }else{$a="NA";}
			$m=max(@a);
			$mm=min(@a);
			if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
			$mid=int @a/2;
			@srtd=sort { $a <=> $b } @a;
			if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
			$LAST_MONTH_COUNT=$n;
			$LAST_MONTH_SUM=$s;
			$LAST_MONTH_AVERAGE=$a;
			$LAST_MONTH_STD=$std;
			$LAST_MONTH_MEDIAN=$med;
			$LAST_MONTH_MAX=$m;
			$LAST_MONTH_MIN=$mm;
			#
			# Now we "clean up" the average and STD deviation
			$LAST_MONTH_AVERAGE=sprintf "%.2f",$LAST_MONTH_AVERAGE;
			$LAST_MONTH_STD=sprintf "%.2f",$LAST_MONTH_STD;
		}
		else {
			$LAST_MONTH_COUNT="N/A";
			$LAST_MONTH_SUM="N/A";
			$LAST_MONTH_AVERAGE="N/A";
			$LAST_MONTH_STD="N/A";
			$LAST_MONTH_MEDIAN="N/A";
			$LAST_MONTH_MAX="N/A";
			$LAST_MONTH_MIN="N/A";
			$LAST_MONTH_STD="N/A";
		}
	
		$LAST_MONTH_COUNT=&commify( $LAST_MONTH_COUNT );
		$LAST_MONTH_SUM=&commify( $LAST_MONTH_SUM );
		$LAST_MONTH_AVERAGE=&commify( $LAST_MONTH_AVERAGE );
		$LAST_MONTH_STD=&commify( $LAST_MONTH_STD );
		$LAST_MONTH_MEDIAN=&commify( $LAST_MONTH_MEDIAN );
		$LAST_MONTH_MAX=&commify( $LAST_MONTH_MAX );
		$LAST_MONTH_MIN=&commify( $LAST_MONTH_MIN);
	
		#
		# THIS YEAR
		#
		# This was tested and works with 365 files :-)
		if ( $DEBUG  == 1 ) { print  "DEBUG-in count_ssh_attacks/This Year now\n"  }
		$TMP=0;
		open (FIND, "find $TMP_YEAR -name current-attack-count.data|");
		while (<FIND>){
			chomp;
			open (FILE, "$_");
			while (<FILE>){
				chomp;
				$COUNT=$_;
			}
			close (FILE);
			$TMP+=$COUNT;
		}
	
	
		$THIS_YEAR=`expr $TMP + $TODAY`;
		if ( $DEBUG  == 1 ) { print  "DEBUG this year statistics \n" ; }
		# OK, this may not be 100% secure, but it's close enough for now
		@a=();
		open (FIND, "find $TMP_YEAR/ -name current-attack-count.data|");
		while(<FIND>){
			open (FILE, $_);
			while (<FILE>){
				$sqsum+=$_*$_; push(@a,$_)
			}
			close (FILE);
		} 
		close (FIND);
		$n=@a;
		$s=sum(@a);
		if ( @a) {$a=$s/@a }else{$a="NA";}
		$m=max(@a);
		$mm=min(@a);
		if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
		$mid=int @a/2;
		@srtd=sort { $a <=> $b } @a;
		if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
	
		$YEAR_COUNT=$n;
		$YEAR_SUM=$s;
		$YEAR_AVERAGE=$a;
		$YEAR_STD=$std;
		$YEAR_MEDIAN=$med;
		$YEAR_MAX=$m;
		$YEAR_MIN=$mm;
		$YEAR_AVERAGE=sprintf "%.2f",$YEAR_AVERAGE;
		$YEAR_STD=sprintf "%.2f",$YEAR_STD;
	
	
		$YEAR_COUNT=&commify( $YEAR_COUNT );
		$YEAR_SUM=&commify( $YEAR_SUM );
		$YEAR_AVERAGE=&commify( $YEAR_AVERAGE );
		$YEAR_STD=&commify( $YEAR_STD );
		$YEAR_MEDIAN=&commify( $YEAR_MEDIAN );
		$YEAR_MAX=&commify( $YEAR_MAX );
		$YEAR_MIN=&commify( $YEAR_MIN );
	
	
		#
		# EVERYTHING
		#
		# I have no idea where this breaks, but it's a big-ass number of files
		$TMP=0;
		if ( $DEBUG  == 1 ) { print  "DEBUG-in count_ssh_attacks-everything \n" ;  }
		open (FIND, "find . -name current-attack-count.data|");
		while (<FIND>){
			chomp;
			open (FILE, "$_");
			while (<FILE>){
				chomp;
				$COUNT=$_;
			}
			close (FILE);
			$TMP+=$COUNT;
		}
	
		$TOTAL= $TMP + $TODAY;
		# OK, this may not be 100% secure, but it's close enough for now
		if ( $DEBUG  == 1 ) { print  "DEBUG ALL  statistics\n" ; }
		if ( $DEBUG  == 1 ) { print "DEBUG-in count_ssh_attacks-everything-statistics\n" ; }
		@a=();
		open (FIND, "find . -name current-attack-count.data|");
		while(<FIND>){
			open (FILE, $_);
			while (<FILE>){
				$sqsum+=$_*$_; push(@a,$_)
			}
			close (FILE);
		} 
		close (FIND);
	
		$n=@a;
		$s=sum(@a);
		if ( @a) {$a=$s/@a }else{$a="NA";}
		$m=max(@a);
		$mm=min(@a);
		if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
		$mid=int @a/2;
		@srtd=sort { $a <=> $b } @a;
		if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
	
		$EVERYTHING_COUNT=$n;
		$EVERYTHING_SUM=$s;
		$EVERYTHING_AVERAGE=$a;
		$EVERYTHING_STD=$std;
		$EVERYTHING_MEDIAN=$med;
		$EVERYTHING_MAX=$m;
		$EVERYTHING_MIN=$mm;
		$EVERYTHING_AVERAGE=sprintf "%.2f",$EVERYTHING_AVERAGE;
		$EVERYTHING_STD=sprintf "%.2f",$EVERYTHING_STD;
	
		$EVERYTHING_COUNT=&commify( $EVERYTHING_COUNT );
		$EVERYTHING_SUM=&commify( $EVERYTHING_SUM );
		$EVERYTHING_AVERAGE=&commify( $EVERYTHING_AVERAGE );
		$EVERYTHING_STD=&commify( $EVERYTHING_STD );
		$EVERYTHING_MEDIAN=&commify( $EVERYTHING_MEDIAN );
		$EVERYTHING_MAX=&commify( $EVERYTHING_MAX );
		$EVERYTHING_MIN=&commify( $EVERYTHING_MIN );
	
	
		#
		# Normalized data
		#
		# I have no idea where this breaks, but it's a big-ass number of files
		chdir ("$TMP_HTML_DIR/historical/");
		# OK, this may not be 100% secure, but it's close enough for now
		if ( $DEBUG  == 1 ) { print  "DEBUG ALL Normalized statistics \n"  }
	
		@a=();
		open (FIND, "find . -name current-attack-count.data|");
		while(<FIND>){
			chomp;
			if ( ! -e "$_.notfullday" ) {
				open (FILE, $_);
				while (<FILE>){
					$sqsum+=$_*$_; push(@a,$_)
				}
				close (FILE);
			}
		} 
		close (FIND);
		$n=@a;
		$s=sum(@a);
		if ( @a) {$a=$s/@a }else{$a="NA";}
		$m=max(@a);
		$mm=min(@a);
		if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
		$mid=int @a/2;
		@srtd=sort { $a <=> $b } @a;
		if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
	
	
		$NORMALIZED_COUNT=$n;
		$NORMALIZED_SUM=$s;
		$NORMALIZED_AVERAGE=$a;
		$NORMALIZED_STD=$std;
		$NORMALIZED_MEDIAN=$med;
		$NORMALIZED_MAX=$m;
		$NORMALIZED_MIN=$mm;
		
		$NORMALIZED_AVERAGE=sprintf "%.2f",$NORMALIZED_AVERAGE;
		$NORMALIZED_STD=sprintf "%.2f",$NORMALIZED_STD;
	
		$NORMALIZED_COUNT=&commify( $NORMALIZED_COUNT );
		$NORMALIZED_SUM=&commify( $NORMALIZED_SUM );
		$NORMALIZED_AVERAGE=&commify( $NORMALIZED_AVERAGE );
		$NORMALIZED_STD=&commify( $NORMALIZED_STD );
		$NORMALIZED_MEDIAN=&commify( $NORMALIZED_MEDIAN );
		$NORMALIZED_MAX=&commify( $NORMALIZED_MAX );
		$NORMALIZED_MIN=&commify( $NORMALIZED_MIN );
	
		$THIS_MONTH=&commify( $THIS_MONTH);
		$THIS_YEAR=&commify( $THIS_YEAR);
		$TOTAL=&commify( $TOTAL);
		chomp $THIS_MONTH;
print "ASDF-1\n";
		`sed -i 's/Login Attempts This Month.*\$/Login Attempts This Month:--> $THIS_MONTH/' $TMP_HTML_DIR/index.shtml`;
		chomp $THIS_YEAR;
print "ASDF-2\n";
		`sed -i 's/Login Attempts This Year.*\$/Login Attempts This Year:--> $THIS_YEAR/' $TMP_HTML_DIR/index.shtml`;
		chomp $TOTAL;
print "ASDF-3\n";
		`sed -i 's/Login Attempts Since Logging Started.*\$/Login Attempts Since Logging Started:--> $TOTAL/' $TMP_HTML_DIR/index.shtml`;
	
		
		########################################################################################
		# Make statistics.shtml webpage here
		#
	print "\n\nDEBUG Make statistics.shtml webpage here\n";
		&make_header ("$TMP_HTML_DIR/statistics.shtml", "Assorted Statistics", "Analysis does not include today's numbers. Numbers rounded to two decimal places", "Time<BR>Frame", "Number<BR>of Days", "Total<BR>SSH attempts", "Average<BR>Per Day", "Std. Dev.", "Median", "Max", "Min");
	
		open (FILE, ">> $TMP_HTML_DIR/statistics.shtml");
		print (FILE "
	<TR><TD>So Far Today</TD><TD>1</TD><TD>$TODAY</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD></TR> 
	<TR><TD>This Month</TD><TD> $MONTH_COUNT</TD><TD> $MONTH_SUM</TD><TD> $MONTH_AVERAGE</TD><TD> $MONTH_STD</TD><TD> $MONTH_MEDIAN</TD><TD> $MONTH_MAX</TD><TD> $MONTH_MIN 
	<TR><TD>Last Month</TD><TD> $LAST_MONTH_COUNT</TD><TD> $LAST_MONTH_SUM</TD><TD> $LAST_MONTH_AVERAGE</TD><TD> $LAST_MONTH_STD</TD><TD> $LAST_MONTH_MEDIAN</TD><TD> $LAST_MONTH_MAX</TD><TD> $LAST_MONTH_MIN 
	<TR><TD>This Year</TD><TD> $YEAR_COUNT</TD><TD> $YEAR_SUM</TD><TD> $YEAR_AVERAGE</TD><TD> $YEAR_STD</TD><TD> $YEAR_MEDIAN</TD><TD> $YEAR_MAX</TD><TD> $YEAR_MIN 
	<TR><TD>Since Logging Started</TD><TD> $EVERYTHING_COUNT</TD><TD> $EVERYTHING_SUM</TD><TD> $EVERYTHING_AVERAGE</TD><TD> $EVERYTHING_STD</TD><TD> $EVERYTHING_MEDIAN</TD><TD> $EVERYTHING_MAX</TD><TD> $EVERYTHING_MIN 
	<TR><TD>Normalized Since Logging Started</TD><TD> $NORMALIZED_COUNT</TD><TD> $NORMALIZED_SUM</TD><TD> $NORMALIZED_AVERAGE</TD><TD> $NORMALIZED_STD</TD><TD> $NORMALIZED_MEDIAN</TD><TD> $NORMALIZED_MAX</TD><TD> $NORMALIZED_MIN 
	 
	</TABLE><!--HEADERLINE -->\n"); 
		close(FILE);
	
		`cat $TMP_HTML_DIR/statistics.shtml > $TMP_HTML_DIR/more_statistics.shtml`;
		&todays_assorted_stats ("todays_ips.count", "$TMP_HTML_DIR/more_statistics.shtml");
		&todays_assorted_stats ("todays_password.count", "$TMP_HTML_DIR/more_statistics.shtml");
		&todays_assorted_stats ("todays_username.count", "$TMP_HTML_DIR/more_statistics.shtml");
		open (FILE, "$TMP_HTML_DIR/more_statistics.shtml");
		print (FILE "
	<P>Normalized data is data that consists of only full days of attacks,<!--HEADERLINE --> 
	AND to servers that are NOT protected by firewalls or other kinds of <!--HEADERLINE -->
	intrusion protection systems.<!--HEADERLINE -->\n");
		close(FILE);
	
		open (FILE, "$TMP_HTML_DIR/statistics.shtml");
		print (FILE "<P>Normalized data is data that consists of only full days of attacks,<!--HEADERLINE --> 
	AND to servers that are NOT protected by firewalls or other kinds of <!--HEADERLINE -->
	intrusion protection systems.<!--HEADERLINE -->\n");
		close(FILE);
	
		&make_footer ("$TMP_HTML_DIR/statistics.shtml");
		&make_footer ("$TMP_HTML_DIR/more_statistics.shtml");
	
	
		# Make statistics_all.shtml and more_statistics_all.shtml webpage here
		if ( "x$HOSTNAME" eq "x/" ) {
			chdir ("$HTML_DIR");
			$table_header="<TR><TH>Time<BR>Frame</TH><TH>Number<BR>of Days</TH><TH>Total<BR>SSH attempts</TH><TH>Average<br>Per Day</TH><TH>Std. Dev.</TH><TH>Median</TH><TH>Max</TH><TH>Min</TH>";
			`grep HEADERLINE statistics.shtml |egrep -v footer.html\\|'</BODY'\\|'</HTML'\\|'</TABLE'\\|'</TR' > statistics_all.shtml`;
			open (FILE, "statistics_all.shtml");
			print (FILE "<TR><TH colspan=8>All Hosts Combined</TH></TR>\n");
			close (FILE);
			`grep '<TR>' $HTML_DIR/statistics.shtml |grep -v HEADERLINE |sed 's/<TD>/<TD>ALL Hosts /' >> statistics_all.shtml`;
	
			`grep HEADERLINE statistics.shtml |egrep -v footer.html\\|'</BODY'\\|'</HTML'\\|'</TABLE'\\|'</TR' > more_statistics_all.shtml`;
			open (TMP_OUTPUT_FILE, ">>more_statistics_all.shtml");
			print (TMP_OUTPUT_FILE "<TR><TH colspan=8>All Hosts Combined</TH></TR>\n");
			close (TMP_OUTPUT_FILE);
	
			open (TMP_FILE, "$HTML_DIR/more_statistics.shtml");
			open (TMP_OUTPUT_FILE, ">>more_statistics_all.shtml");
			while (<TMP_FILE>){
				if (/<TR>/||<TH>){
					$_ =~ s/<TD>/<TD>ALL Hosts /;
					print (TMP_OUTPUT_FILE $_);
				}
			}
			close (TMP_FILE);
			close (TMP_OUTPUT_FILE);
			#This was completed above, do not recode this
			#egrep '<TR>'\|'<TH>' $HTML_DIR/more_statistics.shtml |sed 's/<TD>/<TD>ALL Hosts /' >> more_statistics_all.shtml
	
			open (STATISTICS_ALL, ">>statistics_all.shtml");
			open (MORE_STATISTICS_ALL, ">>more_statistics_all.shtml");
	
			print (STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by BlackRidge Technologies</TH></TR>" );
			print (MORE_STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by BlackRidge Technologies</TH></TR>" );
			foreach (split(/\s+/,$BLACKRIDGE)){
				$dir=$_;
				if ( -e "$dir/statistics.shtml" ) {
					$DESCRIPTION=`cat \"$dir/description.html\"`;
					print (STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>");
					print (STATISTICS_ALL $table_header);
					print (MORE_STATISTICS_ALL $table_header);
					open (TMP_FILE, "$dir/statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
	
					print (MORE_STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" );
	
					open (TMP_FILE, "$dir/more_statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (MORE_STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
				}
			}
			
			print (STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by an Intrusion Protection System</TH></TR>\n");
			print (MORE_STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Hosts protected by an Intrusion Protection System</TH></TR>\n");
			foreach (split(/\s+/,$HOSTS_PROTECTED)){
				$dir=$_;
				if ( -e "$dir/statistics.shtml" ) {
					$DESCRIPTION=`cat $dir/description.html`;
					print (STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>");
					print (STATISTICS_ALL $table_header);
					print (MORE_STATISTICS_ALL $table_header);
					open (TMP_FILE, "$dir/statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
	
					print (MORE_STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" );
	
					open (TMP_FILE, "$dir/more_statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (MORE_STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
				}
			}
	
			print (STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Educational Sites</TH></TR>\n"); 
			print (MORE_STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Educational Sites</TH></TR>\n");
			foreach (split(/\s+/,$EDUCATIONAL_SITES)){
				$dir=$_;
				if ( -e "$dir/statistics.shtml" ) {
					$DESCRIPTION=`cat $dir/description.html`;
					print (STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>");
					print (STATISTICS_ALL $table_header);
					print (MORE_STATISTICS_ALL $table_header);
					open (TMP_FILE, "$dir/statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
	
					print (MORE_STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" );
	
					open (TMP_FILE, "$dir/more_statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (MORE_STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
				}
			}
	
			print (STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Residential Sites</TH></TR>\n");
			print (MORE_STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Residential Sites</TH></TR>\n");
			foreach (split(/\s+/,$RESIDENTIAL_SITES)){
				$dir=$_;
				if ( -e "$dir/statistics.shtml" ) {
					$DESCRIPTION=`cat $dir/description.html`;
					print (STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>");
					print (STATISTICS_ALL $table_header);
					print (MORE_STATISTICS_ALL $table_header);
					open (TMP_FILE, "$dir/statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
	
					print (MORE_STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" );
	
					open (TMP_FILE, "$dir/more_statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (MORE_STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
				}
			}
	
			print (STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Cloud Provider Sites</TH></TR>\n");
			print (MORE_STATISTICS_ALL "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Cloud Provider Sites</TH></TR>\n");
			foreach (split(/\s+/,$CLOUD_SITES)){
				$dir=$_;
				if ( -e "$dir/statistics.shtml" ) {
					$DESCRIPTION=`cat $dir/description.html`;
					print (STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>");
					print (STATISTICS_ALL $table_header);
					print (MORE_STATISTICS_ALL $table_header);
					open (TMP_FILE, "$dir/statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
	
					print (MORE_STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" );
	
					open (TMP_FILE, "$dir/more_statistics.shtml");
					while (<TMP_FILE>){
						if (/<TR>/){
							$_ =~ s/<TD>/<TD>$dir /;
							print (MORE_STATISTICS_ALL $_);
						}
					}
					close (TMP_FILE);
				}
			}
	
			#echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Commercial Sites</TH></TR>" >> statistics_all.shtml
			#echo "<TR><TH colspan=8>&nbsp;</TH></TR><TR><TH colspan=8>Commercial Sites</TH></TR>" >> more_statistics_all.shtml
			#foreach (split(/\s+/,$BUSINESS_SITES)){
			#	$dir=$_;
			#	if ( -e "$dir/statistics.shtml" ) {
			#		$DESCRIPTION=`cat $dir/description.html`;
			#		print (STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>");
			#		print (STATISTICS_ALL $table_header);
			#		print (MORE_STATISTICS_ALL $table_header);
			#		open (TMP_FILE, "$dir/statistics.shtml");
			#		while (<TMP_FILE>){
			#			if (/<TR>/){
			#				$_ =~ s/<TD>/<TD>$dir /;
			#				print (STATISTICS_ALL $_);
			#			}
			#		}
			#		close (TMP_FILE);
			#
			#		print (MORE_STATISTICS_ALL "<TR><TH colspan=8  ><A href=\"/$HTML_TOP_DIR/$dir/\">$dir $DESCRIPTION</A></TH></TR>" );
			#
			#		open (TMP_FILE, "$dir/more_statistics.shtml");
			#		while (<TMP_FILE>){
			#			if (/<TR>/){
			#				$_ =~ s/<TD>/<TD>$dir /;
			#				print (MORE_STATISTICS_ALL $_);
			#			}
			#		}
			#		close (TMP_FILE);
			#	}
			#}
	
			print (STATISTICS_ALL "</TABLE>" );
			print (MORE_STATISTICS_ALL "</TABLE>" );
	
			print (STATISTICS_ALL "<P>Total SSH attempts for all hosts may be LARGER than the sum <!--HEADERLINE -->"  );
			print (STATISTICS_ALL "of SSH attempts of each host.  This is because each host's attacks <!--HEADERLINE -->"  );
			print (STATISTICS_ALL "are counted before totalling all the SSH attacks, and if attacks are<!--HEADERLINE -->"  );
			print (STATISTICS_ALL "ongoing, { more attacks will have come in between counting for a host<!--HEADERLINE -->"  );
			print (STATISTICS_ALL "and counting all the SSH attacks.<!--HEADERLINE -->"  );
	
	
			print (MORE_STATISTICS_ALL "<P>Total SSH attempts for all hosts may be LARGER than the sum <!--HEADERLINE -->"  );
			print (MORE_STATISTICS_ALL "of SSH attempts of each host.  This is because each host's attacks <!--HEADERLINE -->"  );
			print (MORE_STATISTICS_ALL "are counted before totalling all the SSH attacks, and if attacks are<!--HEADERLINE -->"  );
			print (MORE_STATISTICS_ALL "ongoing, { more attacks will have come in between counting for a host<!--HEADERLINE -->"  );
			print (MORE_STATISTICS_ALL "and counting all the SSH attacks.<!--HEADERLINE -->"  );
	
			print (STATISTICS_ALL "<!--#include virtual=/$HTML_TOP_DIR/footer.html --> <!--HEADERLINE --> " );
			print (STATISTICS_ALL "</BODY><!--HEADERLINE -->" );
			print (STATISTICS_ALL "</HTML><!--HEADERLINE -->" );
	
			print (MORE_STATISTICS_ALL "<!--#include virtual=/$HTML_TOP_DIR/footer.html --> <!--HEADERLINE --> " );
			print (MORE_STATISTICS_ALL "</BODY><!--HEADERLINE -->" );
			print (MORE_STATISTICS_ALL "</HTML><!--HEADERLINE -->" );
			close (STATISTICS_ALL);
			close (MORE_STATISTICS_ALL);
		}
	}

	#
	# This really needs to be sped up somehow
	#
	# Couting honeypots here
	if ( $START_HOUR == $MIDNIGHT ) {
		if ( "x$HOSTNAME" eq "x/" ) {
			if ( $SEARCH_FOR eq "sshd" ) {
				if ( $DEBUG  == 1 ) { print  "DEBUG-Getting all honeypots now, this really should be sped up somehow:";$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
				#$ALLUNIQUEHONEYPOTS=`zcat historical/*/*/*/current-raw-data.gz |egrep IP:\\|sshd | awk '{print \$2}' |sort -T $TMP_DIRECTORY -u  |wc -l`;
				#$THISYEARUNIQUEHONEYPOTS=`zcat historical/$TMP_YEAR/*/*/current-raw-data.gz |egrep IP:\\|sshd |awk '{print \$2}'|sort -T $TMP_DIRECTORY -u |wc -l `;
 				#all_messages.gz, NOT current-raw-data.gz because some months
				#honeypots like BlackRidge protected honeypots like erhp and erhp2 
				#have no traffic.
				# 2015-12-29- Why is that?  I need to document it better
				#$THISMONTHUNIQUEHONEYPOTS=`zcat historical/$TMP_YEAR/$TMP_MONTH/*/all_messages.gz |grep ssh |awk '{print \$2}'|sort -T $TMP_DIRECTORY -u |wc -l `;

				`cat historical/*/*/*/todays-honeypots.txt |awk '{print \$2}' |sort -T $TMP_DIRECTORY -u > all-honeypots`;
				$THISYEARUNIQUEHONEYPOTS=`cat historical/$TMP_YEAR/*/*/todays-honeypots.txt |sort -T $TMP_DIRECTORY -u |wc -l `;
				chomp $THISYEARUNIQUEHONEYPOTS;
				$THISMONTHUNIQUEHONEYPOTS=`cat historical/$TMP_YEAR/$TMP_MONTH/*/todays-honeypots.txt |sort -T $TMP_DIRECTORY -u |wc -l `;
				chomp $THISMONTHUNIQUEHONEYPOTS;
				$ALLUNIQUEHONEYPOTS=`cat all-honeypots |wc -l`;
				chomp $ALLUNIQUEHONEYPOTS;

				$THISMONTHUNIQUEHONEYPOTS=&commify($THISMONTHUNIQUEHONEYPOTS);
				$THISYEARUNIQUEHONEYPOTS=&commify( $THISYEARUNIQUEHONEYPOTS);
				$ALLUNIQUEHONEYPOTS=&commify( $ALLUNIQUEHONEYPOTS);

				chomp $THISMONTHUNIQUEHONEYPOTS;
				chomp $THISYEARUNIQUEHONEYPOTS;
				chomp $ALLUNIQUEHONEYPOTS;

				`sed -i "s/Number of Honeypots This Month.*\$/Number of Honeypots This Month:--> $THISMONTHUNIQUEHONEYPOTS/" $TMP_HTML_DIR/index.shtml`;
				`sed -i "s/Number of Honeypots This Year.*\$/Number of Honeypots This Year:--> $THISYEARUNIQUEHONEYPOTS/" $TMP_HTML_DIR/index.shtml`;
				`sed -i "s/Number of Honeypots Since Logging Started.*\$/Number of Honeypots Since Logging Started:--> $ALLUNIQUEHONEYPOTS/" $TMP_HTML_DIR/index.shtml`;
				`sed -i "s/Number of Honeypots This Month.*\$/Number of Honeypots This Month:--> $THISMONTHUNIQUEHONEYPOTS/" $TMP_HTML_DIR/index-long.shtml`;
				`sed -i "s/Number of Honeypots This Year.*\$/Number of Honeypots This Year:--> $THISYEARUNIQUEHONEYPOTS/" $TMP_HTML_DIR/index-long.shtml`;
				`sed -i "s/Number of Honeypots Since Logging Started.*\$/Number of Honeypots Since Logging Started:--> $ALLUNIQUEHONEYPOTS/" $TMP_HTML_DIR/index-long.shtml`;
			}
		}
	}


	# SOMEWHERE there is a bug which if the password is empty, that the
	# line sent to syslog is "...Password:$", instead of "...Password: $"
	# Please note the missing space at the end of the line is the bug
	# and now I need to code around it everyplace :-(
	if ( ! -e "all-password" ) {
		&touch ("all-password");
	}
	if ( $START_HOUR == $MIDNIGHT ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-Getting all passwords now "; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
		`cat historical/*/*/*/todays_password |sort -T $TMP_DIRECTORY -u > all-password`;
		$THISYEARUNIQUEPASSWORDS=`cat historical/$TMP_YEAR/*/*/todays_password |sort -T $TMP_DIRECTORY -u |wc -l `;
		chomp $THISYEARUNIQUEPASSWORDS;
		$THISMONTHUNIQUEPASSWORDS=`cat historical/$TMP_YEAR/$TMP_MONTH/*/todays_password |sort -T $TMP_DIRECTORY -u |wc -l `;
		chomp $THISMONTHUNIQUEPASSWORDS;
		$ALLUNIQUEPASSWORDS=`cat all-password |wc -l`;
		chomp $ALLUNIQUEPASSWORDS;
		if ( $DEBUG  == 1 ) { print  "DEBUG-A-Done Getting all passwords now "; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }

#print "DEBUG WAS $THISMONTHUNIQUEPASSWORDS $THISYEARUNIQUEPASSWORDS $ALLUNIQUEPASSWORDS\n";
		$THISMONTHUNIQUEPASSWORDS=&commify( $THISMONTHUNIQUEPASSWORDS );
		$THISYEARUNIQUEPASSWORDS=&commify( $THISYEARUNIQUEPASSWORDS );
		$ALLUNIQUEPASSWORDS=&commify( $ALLUNIQUEPASSWORDS );
#print "DEBUG IS $THISMONTHUNIQUEPASSWORDS $THISYEARUNIQUEPASSWORDS $ALLUNIQUEPASSWORDS\n";

		`sed -i "s/Unique Passwords This Month.*\$/Unique Passwords This Month:--> $THISMONTHUNIQUEPASSWORDS/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique Passwords This Year.*\$/Unique Passwords This Year:--> $THISYEARUNIQUEPASSWORDS/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique Passwords Since Logging Started.*\$/Unique Passwords Since Logging Started:--> $ALLUNIQUEPASSWORDS/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique Passwords This Month.*\$/Unique Passwords This Month:--> $THISMONTHUNIQUEPASSWORDS/" $TMP_HTML_DIR/index-long.shtml`;
		`sed -i "s/Unique Passwords This Year.*\$/Unique Passwords This Year:--> $THISYEARUNIQUEPASSWORDS/" $TMP_HTML_DIR/index-long.shtml`;
		`sed -i "s/Unique Passwords Since Logging Started.*\$/Unique Passwords Since Logging Started:--> $ALLUNIQUEPASSWORDS/" $TMP_HTML_DIR/index-long.shtml`;
	}
	if ( "x$HOSTNAME" eq "x/" ) {
		open (OUTPUT, ">todays_passwords.tmp");
		if ( $DEBUG  == 1 ) { print  "DEBUG-Getting todays passwords now "; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
# This chunk of code works, but reads the damn messages file, 
# even though there's a temp file....
#		open (FILE, "$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |");
#		while (<FILE>){
#			if (/$PROTOCOL/){
#				if (/$TMP_DATE/){
#				if (/ Password: /){
#					#NOTYETCONVERTED grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |
#					$_ =~ s/^..*Password:\ //;
#					$_ =~ s/^..*Password:$/ /;
#					chomp;
#					print (OUTPUT "$_\n");
#				}
#			}
#		}
#	}
	open (FILE, "$TMP_DIRECTORY/LongTail-messages.$$") || die "something happened to $TMP_DIRECTORY/LongTail-messages.$$, exiting now\n";
	while (<FILE>){
		if (/ Password: /){
			$_ =~ s/^..*Password:\ //;
			$_ =~ s/^..*Password:$/ /;
			chomp;
			print (OUTPUT "$_\n");
		}
	}

	close (OUTPUT);
	close (FILE);
	`sort -T $TMP_DIRECTORY -u todays_passwords.tmp > todays_passwords`;
	}else{
		open (FILE, "$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES|  awk '\$2 == \"$HOSTNAME\" {print}' | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |");
		open (OUTPUT, ">todays_passwords.tmp");
		if ( $DEBUG  == 1 ) { print  "DEBUG-Getting todays passwords now "; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
		while (<FILE>){
			if (/$PROTOCOL/){
				if (/$TMP_DATE/){
				if (/ Password: /){
					#NOTYETCONVERTED grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |
					$_ =~ s/^..*Password:\ //;
					$_ =~ s/^..*Password:$/ /;
					chomp;
					print (OUTPUT "$_\n");
				}
			}
		}
	}
	close (OUTPUT);
	close (FILE);
	`sort -T $TMP_DIRECTORY -u todays_passwords.tmp > todays_passwords`;
		
	}
	if ( $DEBUG  == 1 ) { print  "DEBUG-Done Getting todays passwords now "; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	$TODAYSUNIQUEPASSWORDS=`cat todays_passwords |wc -l`;
	chomp $TODAYSUNIQUEPASSWORDS;
	`echo $TODAYSUNIQUEPASSWORDS  >todays_password.count`;
	`awk 'FNR==NR{a[\$0]++;next}(!(\$0 in a))' all-password todays_passwords >todays-uniq-passwords.txt`;
	$PASSWORDSNEWTODAY=`cat todays-uniq-passwords.txt |wc -l`;
	chomp $PASSWORDSNEWTODAY;

	&make_header ("$TMP_HTML_DIR/todays-uniq-passwords.shtml", "Passwords Never Seen Before Today");
	open (TMP_FILE, "$TMP_HTML_DIR/todays-uniq-passwords.txt");
	print (TMP_FILE "</TABLE>\n");
	print (TMP_FILE "<HR>\n");
	close (TMP_FILE);

	open (TMP_FILE, "todays-uniq-passwords.txt");
	open (TMP_OUTPUT_FILE, ">>$TMP_HTML_DIR/todays-uniq-passwords.shtml");
	while (<TMP_FILE>){
		chomp;
		print (TMP_OUTPUT_FILE "<BR><a href=\"https://www.google.com/search?q=&#34password+$_&#34\">$_</a> \n");
	}
	close (TMP_FILE);
	close (TMP_OUTPUT_FILE);
	&make_footer("$TMP_HTML_DIR/todays-uniq-passwords.shtml");
		if ( $DEBUG  == 1 ) { print  "DEBUG-B-Done Getting all passwords now:"; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }



	#
	# This really needs to be sped up somehow
	#
#7:36-04:00 shepherd sshd-22[2766]: IP: 103.41.124.140 PassLog: Username: root Password: tommy007

	if ( ! -e "all-username" ) {
		&touch ("all-username");
	}
	if ( $START_HOUR == $MIDNIGHT ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-Getting all Usernames now\n"; }
		`cat historical/*/*/*/todays_username |sort -T $TMP_DIRECTORY -u > all-username`;
		$THISYEARUNIQUEUSERNAMES=`cat historical/$TMP_YEAR/*/*/todays_username |sort -T $TMP_DIRECTORY -u |wc -l `;
		chomp $THISYEARUNIQUEUSERNAMES;
		$THISMONTHUNIQUEUSERNAMES=`cat historical/$TMP_YEAR/$TMP_MONTH/*/todays_username |sort -T $TMP_DIRECTORY -u |wc -l `;
		chomp $THISMONTHUNIQUEUSERNAMES;
		if ( $DEBUG  == 1 ) { print  "DEBUG-Done Getting all username now\n"; }
		$ALLUNIQUEUSERNAMES=`cat all-username |wc -l`;
		chomp $ALLUNIQUEUSERNAMES;

		$THISMONTHUNIQUEUSERNAMES=&commify( $THISMONTHUNIQUEUSERNAMES);
		$THISYEARUNIQUEUSERNAMES=&commify( $THISYEARUNIQUEUSERNAMES);
		$ALLUNIQUEUSERNAMES=&commify( $ALLUNIQUEUSERNAMES);

		`sed -i "s/Unique Usernames This Month.*\$/Unique Usernames This Month:--> $THISMONTHUNIQUEUSERNAMES/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique Usernames This Year.*\$/Unique Usernames This Year:--> $THISYEARUNIQUEUSERNAMES/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique Usernames Since Logging Started.*\$/Unique Usernames Since Logging Started:--> $ALLUNIQUEUSERNAMES/" $TMP_HTML_DIR/index.shtml`;

		`sed -i "s/Unique Usernames This Month.*\$/Unique Usernames This Month:--> $THISMONTHUNIQUEUSERNAMES/" $TMP_HTML_DIR/index-long.shtml`;
		`sed -i "s/Unique Usernames This Year.*\$/Unique Usernames This Year:--> $THISYEARUNIQUEUSERNAMES/" $TMP_HTML_DIR/index-long.shtml`;
		`sed -i "s/Unique Usernames Since Logging Started.*\$/Unique Usernames Since Logging Started:--> $ALLUNIQUEUSERNAMES/" $TMP_HTML_DIR/index-long.shtml`;
	}
	if ( "x$HOSTNAME" eq "x/" ) {
		if ( $KIPPO == 1 ) {
			#NOTYETCONVERTED $SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt |sed 's/^..*\[//' | sed 's/\/..*$//' |sort -T $TMP_DIRECTORY -u > todays_username
			print "kippo not done, fix this\n";
		} else {
			`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|sed 's\/^..*Username:\\ \/\/' |sed 's\/ Password:.*$\//' |sort -T $TMP_DIRECTORY -u > todays_username`;
		}
	} else {
		`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '\$2 == \"$HOSTNAME\" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|sed 's\/^..*Username:\\ \/\/' |sed 's\/ Password:.*$\//' |sort -T $TMP_DIRECTORY -u > todays_username`;
	}
	$TODAYSUNIQUEUSERNAMES=`cat todays_username |wc -l`;
	chomp $TODAYSUNIQUEUSERNAMES;
	`echo $TODAYSUNIQUEUSERNAMES  >todays_username.count`;
# 2016-01-04 this works ericw.
	`awk 'FNR==NR{a[\$0]++;next}(!(\$0 in a))' all-username todays_username >todays-uniq-username.txt`;
	$USERNAMESNEWTODAY=`cat todays-uniq-username.txt |wc -l`;
	chomp $USERNAMESNEWTODAY;

	&make_header("$TMP_HTML_DIR/todays-uniq-username.shtml", "Usernames Never Seen Before Today");
	open (INPUT, "todays-uniq-username.txt");
	open (OUTPUT, ">> $TMP_HTML_DIR/todays-uniq-username.shtml");
	while (<INPUT>){
		chomp;
		print(OUTPUT "<BR><a href=\"https://www.google.com/search?q=&#34username+$_&#34\">$_</a> \n");
	}
	close (INPUT);
	close (OUTPUT);
	&make_footer("$TMP_HTML_DIR/todays-uniq-username.shtml");

print "\n\n\nWARNING!!! I need to check todays uniq password and IP before moving on, but it seems to work on 2016-03-01\n\n\n";


	#
	# This really needs to be sped up somehow
	#
#2015-03-29T03:07:36-04:00 shepherd sshd-22[2766]: IP: 103.41.124.140 PassLog: Username: root Password: tommy007

	if ( ! -e "all-ips" ) {
		&touch ("all-ips");
	}
	if ( $START_HOUR == $MIDNIGHT ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-Getting all IPs now\n"; }
		`cat historical/*/*/*/todays_ips |sort -T $TMP_DIRECTORY -u > all-ips`;
		$THISYEARUNIQUEIPSS=`cat historical/$TMP_YEAR/*/*/todays_ips |sort -T $TMP_DIRECTORY -u |wc -l `;
		chomp $THISYEARUNIQUEIPSS;
		$THISMONTHUNIQUEIPSS=`cat historical/$TMP_YEAR/$TMP_MONTH/*/todays_ips |sort -T $TMP_DIRECTORY -u |wc -l `;
		chomp $THISMONTHUNIQUEIPSS;
		if ( $DEBUG  == 1 ) { print  "DEBUG-Done Getting all ips now\n"; }
		$ALLUNIQUEIPSS=`cat all-ips |wc -l`;
		chomp $ALLUNIQUEIPSS;

		$THISMONTHUNIQUEIPSS=&commify( $THISMONTHUNIQUEIPSS);
		$THISYEARUNIQUEIPSS=&commify( $THISYEARUNIQUEIPSS);
		$ALLUNIQUEIPSS=&commify( $ALLUNIQUEIPSS);

		`sed -i "s/Unique IPs This Month.*\$/Unique IPs This Month:--> $THISMONTHUNIQUEIPSS/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique IPs This Year.*\$/Unique IPs This Year:--> $THISYEARUNIQUEIPSS/" $TMP_HTML_DIR/index.shtml`;
		`sed -i "s/Unique IPs Since Logging Started.*\$/Unique IPs Since Logging Started:--> $ALLUNIQUEIPSS/" $TMP_HTML_DIR/index.shtml`;

		`sed -i "s/Unique IPs This Month.*\$/Unique IPs This Month:--> $THISMONTHUNIQUEIPSS/" $TMP_HTML_DIR/index-long.shtml`;
		`sed -i "s/Unique IPs This Year.*\$/Unique IPs This Year:--> $THISYEARUNIQUEIPSS/" $TMP_HTML_DIR/index-long.shtml`;
		`sed -i "s/Unique IPs Since Logging Started.*\$/Unique IPs Since Logging Started:--> $ALLUNIQUEIPSS/" $TMP_HTML_DIR/index-long.shtml`;
	}
	#
	if ( "x$HOSTNAME" eq "x/" ) {
		if ( $KIPPO == 1 ) {
			print "Kippo code not converted yet\n";
#NOTYETCONVERTED			$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep ssh |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep login\ attempt |sed 's/^..*,.*,//' |sed 's/\]..*$//' |sort -T $TMP_DIRECTORY -u > todays_ips
		} else {
			`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|grep IP: |sed 's\/^..*IP: \/\/' |sed 's\/ .*$\/\/'|sort -T $TMP_DIRECTORY -u > todays_ips`;
		}
	} else {
		`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep $PROTOCOL |awk '\$2 == \"$HOSTNAME\" {print}'  |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |grep IP: |sed 's\/^..*IP: \/\/' |sed 's\/ .*$\/\/' |sort -T $TMP_DIRECTORY -u > todays_ips`;
	}
	$TODAYSUNIQUEIPS=`cat todays_ips |wc -l`;
	chomp $TODAYSUNIQUEIPS;
	`echo $TODAYSUNIQUEIPS  >todays_ips.count`;
	`awk 'FNR==NR{a[\$0]++;next}(!(\$0 in a))' all-ips todays_ips >todays-uniq-ips.txt`;
	$IPSNEWTODAY=`cat todays-uniq-ips.txt |wc -l`;
	chomp $IPSNEWTODAY;

	&make_header ("$TMP_HTML_DIR/todays-uniq-ips.shtml", "IP Addresses Never Seen Before Today", " ", "Count", "IP Address", "Country", "WhoIS", "Blacklisted", "Attack Patterns");

	`for IP in \`cat todays-uniq-ips.txt\` ; do echo "TEST-\$IP-TEST"; grep .TD.\$IP..TD. current-ip-addresses.shtml >> $TMP_HTML_DIR/todays-uniq-ips.shtml; done`;

	&make_footer ("$TMP_HTML_DIR/todays-uniq-ips.shtml");
	`sed -i s/HONEY/$HTML_TOP_DIR/g $TMP_HTML_DIR/todays-uniq-ips.shtml`;
#print (STDERR "Gotta check todays-uniq-ips.shtml, but it seems to work on 2016-03-01\n\n\n");
	$TODAY=&commify($TODAY);

	$TODAYSUNIQUEPASSWORDS=&commify( $TODAYSUNIQUEPASSWORDS);
	$PASSWORDSNEWTODAY=&commify( $PASSWORDSNEWTODAY);
	$TODAYSUNIQUEUSERNAMES=&commify( $TODAYSUNIQUEUSERNAMES);
	$USERNAMESNEWTODAY=&commify( $USERNAMESNEWTODAY);
	$TODAYSUNIQUEIPS=&commify( $TODAYSUNIQUEIPS);
	$IPSNEWTODAY=&commify( $IPSNEWTODAY);

	chomp $TODAY;
	`sed -i 's/Login Attempts Today.*\$/Login Attempts Today:--> $TODAY/' $TMP_HTML_DIR/index.shtml`;

	chomp $TODAYSUNIQUEPASSWORDS;
	`sed -i 's/Unique Passwords Today.*\$/Unique Passwords Today:--> $TODAYSUNIQUEPASSWORDS/' $TMP_HTML_DIR/index.shtml`;
	chomp $PASSWORDSNEWTODAY;
	`sed -i 's/New Passwords Today.*\$/New Passwords Today:--> $PASSWORDSNEWTODAY/' $TMP_HTML_DIR/index.shtml`;

	chomp $TODAYSUNIQUEUSERNAMES;
	`sed -i 's/Unique Usernames Today.*\$/Unique Usernames Today:--> $TODAYSUNIQUEUSERNAMES/' $TMP_HTML_DIR/index.shtml`;
	chomp $USERNAMESNEWTODAY;
	`sed -i 's/New Usernames Today.*\$/New Usernames Today:--> $USERNAMESNEWTODAY/' $TMP_HTML_DIR/index.shtml`;

	chomp $TODAYSUNIQUEIPS;
	`sed -i 's/Unique IPs Today.*\$/Unique IPs Today:--> $TODAYSUNIQUEIPS/' $TMP_HTML_DIR/index.shtml`;
	chomp $IPSNEWTODAY;
	`sed -i 's/New IPs Today.*\$/New IPs Today:--> $IPSNEWTODAY/' $TMP_HTML_DIR/index.shtml`;

	chomp $TODAY;
	`sed -i 's/Login Attempts Today.*\$/Login Attempts Today:--> $TODAY/' $TMP_HTML_DIR/index-long.shtml`;
	chomp $THIS_MONTH;
	`sed -i 's/Login Attempts This Month.*\$/Login Attempts This Month:--> $THIS_MONTH/' $TMP_HTML_DIR/index-long.shtml`;
	chomp $THIS_YEAR;
	`sed -i 's/Login Attempts This Year.*\$/Login Attempts This Year:--> $THIS_YEAR/' $TMP_HTML_DIR/index-long.shtml`;
	chomp $TOTAL;
	`sed -i 's/Login Attempts Since Logging Started.*\$/Login Attempts Since Logging Started:--> $TOTAL/' $TMP_HTML_DIR/index-long.shtml`;

	chomp $TODAYSUNIQUEPASSWORDS;
	`sed -i 's/Unique Passwords Today.*\$/Unique Passwords Today:--> $TODAYSUNIQUEPASSWORDS/' $TMP_HTML_DIR/index-long.shtml`;
	chomp $PASSWORDSNEWTODAY;
	`sed -i 's/New Passwords Today.*\$/New Passwords Today:--> $PASSWORDSNEWTODAY/' $TMP_HTML_DIR/index-long.shtml`;

	chomp $TODAYSUNIQUEUSERNAMES;
	`sed -i 's/Unique Usernames Today.*\$/Unique Usernames Today:--> $TODAYSUNIQUEUSERNAMES/' $TMP_HTML_DIR/index-long.shtml`;
	chomp $USERNAMESNEWTODAY;
	`sed -i 's/New Usernames Today.*\$/New Usernames Today:--> $USERNAMESNEWTODAY/' $TMP_HTML_DIR/index-long.shtml`;

	chomp $TODAYSUNIQUEIPS;
	`sed -i 's/Unique IPs Today.*\$/Unique IPs Today:--> $TODAYSUNIQUEIPS/' $TMP_HTML_DIR/index-long.shtml`;
	chomp $IPSNEWTODAY;
	`sed -i 's/New IPs Today.*\$/New IPs Today:--> $IPSNEWTODAY/' $TMP_HTML_DIR/index-long.shtml`;

	if ( "x$HOSTNAME" eq "x/" ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-looking for honeypots now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }

		`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep "$TMP_DATE" | egrep IP:\\|sshd |awk '{print \$2}' |grep -v longtail| sort -T $TMP_DIRECTORY |uniq -c > $TMP_HTML_DIR/todays-honeypots.txt`;
		`cat $TMP_HTML_DIR/todays-honeypots.txt |wc -l  > $TMP_HTML_DIR/todays-honeypots.txt.count`;

		$HONEYPOTSTODAY=`cat $TMP_HTML_DIR/todays-honeypots.txt.count`;
		chomp $HONEYPOTSTODAY;


	`sed -i 's/Number of Honeypots Today:.*\$/Number of Honeypots Today:--> $HONEYPOTSTODAY/' $TMP_HTML_DIR/index.shtml`;
	`sed -i 's/Number of Honeypots Today:.*\$/Number of Honeypots Today:--> $HONEYPOTSTODAY/' $TMP_HTML_DIR/index-long.shtml`;
		
		&make_header ("$TMP_HTML_DIR/todays_honeypots.shtml", "Today's honeypots", "Count reflects log entries, not actual login attempts", "Entries in syslog", "Hostname" );
		open(INPUT_HONEY, "$TMP_HTML_DIR/todays-honeypots.txt");
		open (OUTPUT, ">>$TMP_HTML_DIR/todays_honeypots.shtml");
		while (<INPUT_HONEY>){
			chomp;
			$_ =~ s/^\s+//;
			($count,$name)=split(/\s+/,$_,2);
 			print(OUTPUT "<TR><TD>$count</TD><TD>$name</TD></TR>\n");
		}
		close(INPUT_HONEY);
		close(OUTPUT);


		&make_footer ("$TMP_HTML_DIR/todays_honeypots.shtml" );
		#
		# Is this really necessary?  2015-08-20
		# 2015-12-31 Apparently not :-)
		#`$SCRIPT_DIR/catall.sh $PATH_TO_VAR_LOG/$MESSAGES |grep "$TMP_DATE" | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep IP:\\|sshd |awk '{print \$2}' |grep -v longtail| sort -T $TMP_DIRECTORY |uniq -c > $TMP_HTML_DIR/todays_honeypots.data`;
	}
	else{
		$HONEYPOTSTODAY=1	
	}
	if ( $DEBUG  == 1 ) { print  "DEBUG-Done looking for honeypots now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	
	chdir ("$ORIGINAL_DIRECTORY");

	print "DEBUG end of count_ssh_attacks "; $TMP=`date`;print $TMP;
} # end of sub count_ssh_attacks
	
sub todays_assorted_stats {
	my $MONTH_COUNT=0;
	my $MONTH_SUM=0;
	my $MONTH_AVERAGE=0;
	my $MONTH_STD=0;
	my $MONTH_MEDIAN=0;
	my $MONTH_MAX=0;
	my $MONTH_MIN=0;
	my $MONTH_STD=0;

	my $LAST_MONTH_COUNT=0;
	my $LAST_MONTH_SUM=0;
	my $LAST_MONTH_AVERAGE=0;
	my $LAST_MONTH_STD=0;
	my $LAST_MONTH_MEDIAN=0;
	my $LAST_MONTH_MAX=0;
	my $LAST_MONTH_MIN=0;
	my $LAST_MONTH_STD=0;

	my $YEAR_COUNT=0;
	my $YEAR_SUM=0;
	my $YEAR_AVERAGE=0;
	my $YEAR_STD=0;
	my $YEAR_MEDIAN=0;
	my $YEAR_MAX=0;
	my $YEAR_MIN=0;
	my $YEAR_STD=0;

	my $YEAR=0; # I am setting this because I set $YEAR later, but I have no idea what I REALLY was trying to set.

	my $EVERYTHING_COUNT=0;
	my $EVERYTHING_SUM=0;
	my $EVERYTHING_AVERAGE=0;
	my $EVERYTHING_STD=0;
	my $EVERYTHING_MEDIAN=0;
	my $EVERYTHING_MAX=0;
	my $EVERYTHING_MIN=0;
	my $EVERYTHING_STD=0;

	my $NORMALIZED_COUNT=0;
	my $NORMALIZED_SUM=0;
	my $NORMALIZED_AVERAGE=0;
	my $NORMALIZED_STD=0;
	my $NORMALIZED_MEDIAN=0;
	my $NORMALIZED_MAX=0;
	my $NORMALIZED_MIN=0;
	my $NORMALIZED_STD=0;

	my $TODAY=0;

	my $file=shift;
	my $outputfile=shift;
	if ( $DEBUG  == 1 ) { print "============================================\n"; }
	if ( $DEBUG  == 1 ) { print  "DEBUG-in todays_assorted_stats/This Month now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }

	#
	# TODAY
	#
	if ( -e "$TMP_HTML_DIR/$file" ) {
		$TODAY=`cat $TMP_HTML_DIR/$file`;
	}
	else {
		print "$TMP_HTML_DIR/$file does not exist yet\n";
		$TODAY=0;
	}

	#
	# THIS MONTH
	#
	$TMP_MONTH=`date "+%m"`;
	$TMP_YEAR=`date "+%Y"`;
	chomp $TMP_MONTH;
	chomp $TMP_YEAR;

	chdir ("$TMP_HTML_DIR/historical/");
	if ( $DEBUG  == 1 ) { print "DEBUG-in todays_assorted_stats-This Month now\n" ; }

	$TMP=0;

	#for FILE in  `find $TMP_YEAR/$TMP_MONTH -name $file` ; do
	#	COUNT=`cat $FILE`
	#	(( TMP += $COUNT ))
	#done
	open (FIND, "find \"$TMP_YEAR/$TMP_MONTH\" -name $file |");
	$tmp_count=0;
	while (<FIND>){
		chomp;
		open (FILE, "$_");
		while (<FILE>){
			chomp;
			$COUNT=$_;
			$tmp_count++;
		}
		close (FILE);
		$TMP+=$COUNT;
	}


	$THIS_MONTH=$TMP + $TODAY;
	# OK, this may not be 100% secure, but it's close enough for now
	if ( $DEBUG  == 1 ) { print  "DEBUG this month statistics\n" ;}
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	if ( -e "$TMP_YEAR/$TMP_MONTH" ) { 
		if ( $DEBUG  == 1 ) { print   "DEBUG-in todays_assorted_stats/This Month/Statistics now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ;}
		@a=();
$TMP=`pwd`;
#print "DEBUG pwd is $TMP\n";
#print "DEBUG FFF Find $TMP_YEAR/$TMP_MONTH/*/$file\n";
		open (FIND, "find $TMP_YEAR/$TMP_MONTH/*/ -name $file|");
		$tmp_count=0;
		while(<FIND>){
			open (FILE, $_);
			while (<FILE>){
				$sqsum+=$_*$_; push(@a,$_)
			}
			$tmp_count++;
			close (FILE);
		};
		if ($tmp_count >0){
		$n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort { $a <=> $b } @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}; $n;
		$MONTH_COUNT=$n;;
		$MONTH_SUM=$s;;
		$MONTH_AVERAGE=$a;
		$MONTH_STD=$std;
		$MONTH_MEDIAN=$med;
		$MONTH_MAX=$m;
		$MONTH_MIN=$mm;

		
		# Now we "clean up" the average and STD deviation
		$MONTH_AVERAGE=sprintf "%.2f",0;
		$MONTH_STD=sprintf "%.2f",0;
	} else {
		$MONTH_COUNT=1;
		$MONTH_SUM=$TODAY;
		$MONTH_AVERAGE=$TODAY;
		$MONTH_STD=0;
		$MONTH_MEDIAN=$TODAY;
		$MONTH_MAX=$TODAY;
		$MONTH_MIN=$TODAY;
		$MONTH_AVERAGE=sprintf "%.2f",0;
		$MONTH_STD=sprintf "%.2f",0;
	} 
	} else {
    $MONTH_COUNT=1;
    $MONTH_SUM=$TODAY;
    $MONTH_AVERAGE=$TODAY;
    $MONTH_STD=0;
    $MONTH_MEDIAN=$TODAY;
    $MONTH_MAX=$TODAY;
    $MONTH_MIN=$TODAY;
    $MONTH_AVERAGE=sprintf "%.2f",0;
    $MONTH_STD=sprintf "%.2f",0;
  }


	$MONTH_COUNT=&commify( $MONTH_COUNT );
	$MONTH_SUM=&commify( $MONTH_SUM );
	$MONTH_AVERAGE=&commify( $MONTH_AVERAGE );
	$MONTH_STD=&commify( $MONTH_STD );
	$MONTH_MEDIAN=&commify( $MONTH_MEDIAN );
	$MONTH_MAX=&commify( $MONTH_MAX );
	$MONTH_MIN=&commify( $MONTH_MIN );


	#
	# LAST MONTH
	#
	chdir ("$TMP_HTML_DIR/historical/");
		if ( $DEBUG  == 1 ) { print "DEBUG-in todays_assorted_stats/REALLY in Last Month now\n" ; }
#
# Gotta fix this for the year boundary
#
	$TMP_LAST_MONTH=`date "+%m" --date="last month"`;
	chomp $TMP_LAST_MONTH;
	$TMP_LAST_MONTH_YEAR=`date "+%Y" --date="last month"`;
	chomp $TMP_LAST_MONTH_YEAR;
	$TMP=0;
	#for FILE in  `find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name $file` ; do
	#	COUNT=`cat $FILE`
	#	(( TMP += $COUNT ))
	#done
	open (FIND, "find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH -name $file |");
	$tmp_count=0;
	while (<FIND>){
		chomp;
		open (FILE, "$_");
		while (<FILE>){
			chomp;
			$COUNT=$_;
		}
		$tmp_count++;
		close (FILE);
		$TMP+=$COUNT;
	}
	
	$LAST_MONTH=$TMP;
	# OK, this may not be 100% secure, but it's close enough for now
	if ( $DEBUG  == 1 ) { print  "DEBUG-2 Last month statistics\n" ;}
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# Gotta do the date calculation to figure out "When" is last month
	#
	if ( -d "$TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH" ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-in todays_assorted_stats/Last Month/statistics now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; };

    @a=();
    open (FIND, "find $TMP_LAST_MONTH_YEAR/$TMP_LAST_MONTH/*/ -name $file|");
		$tmp_count=0;
    while(<FIND>){
      open (FILE, $_);
      while (<FILE>){
        $sqsum+=$_*$_; push(@a,$_)
      }
			$tmp_count++;
      close (FILE);
    }
    close (FIND);
		if ($tmp_count>0){
    $n=@a;
    $s=sum(@a);
    if ( @a) {$a=$s/@a }else{$a="NA";}
    $m=max(@a);
    $mm=min(@a);
    if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
    $mid=int @a/2;
    @srtd=sort { $a <=> $b } @a;
    if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
    $LAST_MONTH_COUNT=$n;
    $LAST_MONTH_SUM=$s;
    $LAST_MONTH_AVERAGE=$a;
    $LAST_MONTH_STD=$std;
    $LAST_MONTH_MEDIAN=$med;
    $LAST_MONTH_MAX=$m;
    $LAST_MONTH_MIN=$mm;

		# Now we "clean up" the average and STD deviation
		$LAST_MONTH_AVERAGE=sprintf '%.2f',$LAST_MONTH_AVERAGE ;
		$LAST_MONTH_STD=sprintf '%.2f',$LAST_MONTH_STD ;
	}
	else{
		$LAST_MONTH_COUNT="N/A";
		$LAST_MONTH_SUM="N/A";
		$LAST_MONTH_AVERAGE="N/A";
		$LAST_MONTH_STD="N/A";
		$LAST_MONTH_MEDIAN="N/A";
		$LAST_MONTH_MAX="N/A";
		$LAST_MONTH_MIN="N/A";
		$LAST_MONTH_STD="N/A";
	} 
	}else {
    $LAST_MONTH_COUNT="N/A";
    $LAST_MONTH_SUM="N/A";
    $LAST_MONTH_AVERAGE="N/A";
    $LAST_MONTH_STD="N/A";
    $LAST_MONTH_MEDIAN="N/A";
    $LAST_MONTH_MAX="N/A";
    $LAST_MONTH_MIN="N/A";
    $LAST_MONTH_STD="N/A";

	} 

	$LAST_MONTH_COUNT=&commify( $LAST_MONTH_COUNT );
	$LAST_MONTH_SUM=&commify( $LAST_MONTH_SUM );
	$LAST_MONTH_AVERAGE=&commify( $LAST_MONTH_AVERAGE );
	$LAST_MONTH_STD=&commify( $LAST_MONTH_STD );
	$LAST_MONTH_MEDIAN=&commify( $LAST_MONTH_MEDIAN );
	$LAST_MONTH_MAX=&commify( $LAST_MONTH_MAX );
	$LAST_MONTH_MIN=&commify( $LAST_MONTH_MIN );
	#
	# THIS YEAR
	#
	# This was tested and works with 365 files :-)

	#
	# THIS YEAR
	#
	chdir ("$TMP_HTML_DIR/historical/");
		if ( $DEBUG  == 1 ) { print "DEBUG-in todays_assorted_stats/Last Year now\n" ; }
#
# Gotta fix this for the year boundary  Huh? What was I talking about?
#
	$TMP_YEAR=`date "+%Y" `;
	chomp $TMP_YEAR;
	$TMP=0;

#
# What the hell does this code do?  It looks like a holdover that was never deleted?
#

	open (FIND, "find $TMP_YEAR -name $file |");
	$tmp_count=0;
	while (<FIND>){
		chomp;
		open (FILE, "$_");
		while (<FILE>){
			chomp;
			$COUNT=$_;
		}
		$tmp_count++;
		close (FILE);
		$TMP+=$COUNT;
	}
print "DEBUG THIS IS A BUG $YEAR=$TMP; What the hell am I using $YEAR for????\n";	
	$YEAR=$TMP;
	if ( $DEBUG  == 1 ) { print  "DEBUG-2 this year's statistics\n" ;}
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# Gotta do the date calculation to figure out "When" is last month
	#
	if ( -d "$TMP_YEAR" ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-in todays_assorted_stats/Last Month/statistics now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; };

    @a=();
    open (FIND, "find $TMP_YEAR/*/*/ -name $file|");
		$tmp_count=0;
    while(<FIND>){
      open (FILE, $_);
      while (<FILE>){
        $sqsum+=$_*$_; push(@a,$_)
      }
			$tmp_count++;
      close (FILE);
    }
    close (FIND);
		if ($tmp_count>0){
    $n=@a;
    $s=sum(@a);
    if ( @a) {$a=$s/@a }else{$a="NA";}
    $m=max(@a);
    $mm=min(@a);
    if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
    $mid=int @a/2;
    @srtd=sort { $a <=> $b } @a;
    if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
    $YEAR_COUNT=$n;
    $YEAR_SUM=$s;
    $YEAR_AVERAGE=$a;
    $YEAR_STD=$std;
    $YEAR_MEDIAN=$med;
    $YEAR_MAX=$m;
    $YEAR_MIN=$mm;

		# Now we "clean up" the average and STD deviation
		$YEAR_AVERAGE=sprintf '%.2f',$YEAR_AVERAGE ;
		$YEAR_STD=sprintf '%.2f',$YEAR_STD ;
	}
	else{
		$YEAR_COUNT="N/A";
		$YEAR_SUM="N/A";
		$YEAR_AVERAGE="N/A";
		$YEAR_STD="N/A";
		$YEAR_MEDIAN="N/A";
		$YEAR_MAX="N/A";
		$YEAR_MIN="N/A";
		$YEAR_STD="N/A";
	} 
	}else {
    $YEAR_COUNT="N/A";
    $YEAR_SUM="N/A";
    $YEAR_AVERAGE="N/A";
    $YEAR_STD="N/A";
    $YEAR_MEDIAN="N/A";
    $YEAR_MAX="N/A";
    $YEAR_MIN="N/A";
    $YEAR_STD="N/A";

	} 

	$YEAR_COUNT=&commify( $YEAR_COUNT );
	$YEAR_SUM=&commify( $YEAR_SUM );
	$YEAR_AVERAGE=&commify( $YEAR_AVERAGE );
	$YEAR_STD=&commify( $YEAR_STD );
	$YEAR_MEDIAN=&commify( $YEAR_MEDIAN );
	$YEAR_MAX=&commify( $YEAR_MAX );
	$YEAR_MIN=&commify( $YEAR_MIN );

	#
	# EVERYTHING
	#
	# I have no idea where this breaks, but it's a big-ass number of files
#print "DEBUG before EVERYTHING\n";

	#
	# THIS EVERYTHING
	#
	chdir ("$TMP_HTML_DIR/historical/");
		if ( $DEBUG  == 1 ) { print "DEBUG-in todays_assorted_stats/Everything now\n" ; }
#
# Gotta fix this for the year boundary
#
	$TMP_EVERYTHING=`date "+%Y" --date="last month"`;
	chomp $TMP_EVERYTHING;
	$TMP=0;

	open (FIND, "find \".\" -name $file |");
	$tmp_count=0;
	while (<FIND>){
		chomp;
		open (FILE, "$_");
		while (<FILE>){
			chomp;
			$COUNT=$_;
		}
		$tmp_count++;
		close (FILE);
		$TMP+=$COUNT;
	}
	
	$EVERYTHING=$TMP;
	if ( $DEBUG  == 1 ) { print  "DEBUG-2 everything statistics\n" ;}
	#
	# So there's a problem if it's the first day of the month and there's
	# No real statistics yet.
	#
	# Gotta do the date calculation to figure out "When" is last month
	#
	if ( -d "$TMP_EVERYTHING" ) {
		if ( $DEBUG  == 1 ) { print  "DEBUG-in todays_assorted_stats/Last Month/statistics now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; };

    @a=();
    open (FIND, "find $TMP_EVERYTHING/*/*/ -name $file|");
		$tmp_count=0;
    while(<FIND>){
      open (FILE, $_);
      while (<FILE>){
        $sqsum+=$_*$_; push(@a,$_)
      }
			$tmp_count++;
      close (FILE);
    }
    close (FIND);
		if ($tmp_count>0){
    $n=@a;
    $s=sum(@a);
    if ( @a) {$a=$s/@a }else{$a="NA";}
    $m=max(@a);
    $mm=min(@a);
    if ($n){$std=sqrt($sqsum/$n-($s/$n)*($s/$n))}else{$std="NA";}
    $mid=int @a/2;
    @srtd=sort { $a <=> $b } @a;
    if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;}
    $EVERYTHING_COUNT=$n;
    $EVERYTHING_SUM=$s;
    $EVERYTHING_AVERAGE=$a;
    $EVERYTHING_STD=$std;
    $EVERYTHING_MEDIAN=$med;
    $EVERYTHING_MAX=$m;
    $EVERYTHING_MIN=$mm;

		# Now we "clean up" the average and STD deviation
		$EVERYTHING_AVERAGE=sprintf '%.2f',$EVERYTHING_AVERAGE ;
		$EVERYTHING_STD=sprintf '%.2f',$EVERYTHING_STD ;
	}
	else{
		$EVERYTHING_COUNT="N/A";
		$EVERYTHING_SUM="N/A";
		$EVERYTHING_AVERAGE="N/A";
		$EVERYTHING_STD="N/A";
		$EVERYTHING_MEDIAN="N/A";
		$EVERYTHING_MAX="N/A";
		$EVERYTHING_MIN="N/A";
		$EVERYTHING_STD="N/A";
	} 
	}else {
    $EVERYTHING_COUNT="N/A";
    $EVERYTHING_SUM="N/A";
    $EVERYTHING_AVERAGE="N/A";
    $EVERYTHING_STD="N/A";
    $EVERYTHING_MEDIAN="N/A";
    $EVERYTHING_MAX="N/A";
    $EVERYTHING_MIN="N/A";
    $EVERYTHING_STD="N/A";

	} 

	$EVERYTHING_COUNT=&commify( $EVERYTHING_COUNT );
	$EVERYTHING_SUM=&commify( $EVERYTHING_SUM );
	$EVERYTHING_AVERAGE=&commify( $EVERYTHING_AVERAGE );
	$EVERYTHING_STD=&commify( $EVERYTHING_STD );
	$EVERYTHING_MEDIAN=&commify( $EVERYTHING_MEDIAN );
	$EVERYTHING_MAX=&commify( $EVERYTHING_MAX );
	$EVERYTHING_MIN=&commify( $EVERYTHING_MIN );

	#
	# Normalized data
	#
print "DEBUG before Normalized data\n";
print "THIS STILL needs to be converted to perl\n\n\n\n";
#NOTYETCONVERTED	if ( "x$HOSTNAME" eq "x" ) {
#NOTYETCONVERTED		print -n  "IN Normalized data, no hostname set" ; date
#NOTYETCONVERTED		# I have no idea where this breaks, but it's a big-ass number of files
#NOTYETCONVERTED		chdir ("$HTML_DIR
#NOTYETCONVERTED		# OK, this may not be 100% secure, but it's close enough for now
#NOTYETCONVERTED		if ( $DEBUG  == 1 ) { echo "DEBUG ALL Normalized statistics" ; }
#NOTYETCONVERTED		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
#NOTYETCONVERTED		for FILE in  `find historical -name $file ` ; do if ( ! -e $FILE.notfullday ) { cat $FILE ; } ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
#NOTYETCONVERTED		. $TMPFILE
#NOTYETCONVERTED		rm $TMPFILE
#NOTYETCONVERTED		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
#NOTYETCONVERTED		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
#NOTYETCONVERTED	else
#NOTYETCONVERTED		print -n "IN Normalized data, hostname was set" ; date
#NOTYETCONVERTED		# I have no idea where this breaks, but it's a big-ass number of files
#NOTYETCONVERTED		chdir ("$HTML_DIR
#NOTYETCONVERTED		# OK, this may not be 100% secure, but it's close enough for now
#NOTYETCONVERTED		if ( $DEBUG  == 1 ) { echo "DEBUG Hostname only ALL  statistics" ; }
#NOTYETCONVERTED		TMPFILE=$(mktemp $TMP_DIRECTORY/output.XXXXXXXXXX)
#NOTYETCONVERTED		for FILE in  `find ./historical -name $file ` ; do if ( ! -e $FILE.notfullday ) { cat $FILE ; } ; done |perl -e 'use List::Util qw(max min sum); @a=();while(<>){$sqsum+=$_*$_; push(@a,$_)}; $n=@a;$s=sum(@a);$a=$s/@a;$m=max(@a);$mm=min(@a);$std=sqrt($sqsum/$n-($s/$n)*($s/$n));$mid=int @a/2;@srtd=sort @a;if(@a%2){$med=$srtd[$mid];}else{$med=($srtd[$mid-1]+$srtd[$mid])/2;};print "NORMALIZED_COUNT=$n\nNORMALIZED_SUM=$s\nNORMALIZED_AVERAGE=$a\nNORMALIZED_STD=$std\nNORMALIZED_MEDIAN=$med\nNORMALIZED_MAX=$m\nNORMALIZED_MIN=$mm";'  > $TMPFILE
#NOTYETCONVERTED		. $TMPFILE
#NOTYETCONVERTED		rm $TMPFILE
#NOTYETCONVERTED		NORMALIZED_AVERAGE=`printf '%.2f' $NORMALIZED_AVERAGE`
#NOTYETCONVERTED		NORMALIZED_STD=`printf '%.2f' $NORMALIZED_STD`
#NOTYETCONVERTED	}
#NOTYETCONVERTED	print -n "Done with normalized data"; date

#NOTYETCONVERTED	NORMALIZED_COUNT=&commify( $NORMALIZED_COUNT );
#NOTYETCONVERTED	NORMALIZED_SUM=&commify( $NORMALIZED_SUM );
#NOTYETCONVERTED	NORMALIZED_AVERAGE=&commify( $NORMALIZED_AVERAGE );
#NOTYETCONVERTED	NORMALIZED_STD=&commify( $NORMALIZED_STD );
#NOTYETCONVERTED	NORMALIZED_MEDIAN=&commify( $NORMALIZED_MEDIAN );
#NOTYETCONVERTED	NORMALIZED_MAX=&commify( $NORMALIZED_MAX );
#NOTYETCONVERTED	NORMALIZED_MIN=&commify( $NORMALIZED_MIN );

	#
	# Assorted header stuff
	#
#was	DESCRIPTION=`echo $file |sed 's/_/ /g' |sed 's/\./ /g' |sed 's/todays//' |sed -r 's/\b(.)/\U\1/g' |sed 's/ Ips / IP Address /'`
	$DESCRIPTION =  $file;
	$DESCRIPTION =~ s/_/ /g;
	$DESCRIPTION =~ s/\./ /g;
	$DESCRIPTION =~ s/todays//g;
	$DESCRIPTION =~ s/([\w']+)/\u\L$1/g;
	$DESCRIPTION =~ s/ Ips / IP Address /;
print "\n\nDEBUG statistics output file is $outputfile\n\n";
	open (OUTPUT, ">>$outputfile");
	print (OUTPUT "<TABLE border=1><!--HEADERLINE -->\n");
	print (OUTPUT "<TR><TH colspan=8>$DESCRIPTION</TH></TR><!--HEADERLINE -->\n");
	print (OUTPUT "<TR><TH>Time<BR>Frame</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Number<BR>of Days</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Count</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Average<BR>Per Day</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Std. Dev.</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Median</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Max</TH><!--HEADERLINE -->\n");
	print (OUTPUT "<TH>Min</TH><!--HEADERLINE -->\n");
	print (OUTPUT "</TR><!--HEADERLINE -->\n");

	print (OUTPUT "<TR><TD>So Far Today</TD><TD>1</TD><TD>$TODAY</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD><TD>N/A</TD></TR>\n");
	print (OUTPUT "<TR><TD>This Month</TD><TD> $MONTH_COUNT</TD><TD>N/A</TD><TD> $MONTH_AVERAGE</TD><TD> $MONTH_STD</TD><TD> $MONTH_MEDIAN</TD><TD> $MONTH_MAX</TD><TD> $MONTH_MIN\n");
	print (OUTPUT "<TR><TD>Last Month</TD><TD> $LAST_MONTH_COUNT</TD><TD>N/A</TD><TD> $LAST_MONTH_AVERAGE</TD><TD> $LAST_MONTH_STD</TD><TD> $LAST_MONTH_MEDIAN</TD><TD> $LAST_MONTH_MAX</TD><TD> $LAST_MONTH_MIN\n");
	print (OUTPUT "<TR><TD>This Year</TD><TD> $YEAR_COUNT</TD><TD>N/A</TD><TD> $YEAR_AVERAGE</TD><TD> $YEAR_STD</TD><TD> $YEAR_MEDIAN</TD><TD> $YEAR_MAX</TD><TD> $YEAR_MIN\n");
	print (OUTPUT "<TR><TD>Since Logging Started</TD><TD> $EVERYTHING_COUNT</TD><TD>N/A</TD><TD> $EVERYTHING_AVERAGE</TD><TD> $EVERYTHING_STD</TD><TD> $EVERYTHING_MEDIAN</TD><TD> $EVERYTHING_MAX</TD><TD> $EVERYTHING_MIN\n");
	print (OUTPUT "<TR><TD>Normalized Since Logging Started</TD><TD> $NORMALIZED_COUNT</TD><TD>N/A</TD><TD> $NORMALIZED_AVERAGE</TD><TD> $NORMALIZED_STD</TD><TD> $NORMALIZED_MEDIAN</TD><TD> $NORMALIZED_MAX</TD><TD> $NORMALIZED_MIN\n");
	print (OUTPUT "\n");
	print (OUTPUT "</TABLE><!--HEADERLINE -->\n");
	print (OUTPUT "Done with  todays_assorted_stats\n");
	close  (OUTPUT);
}


############################################################################
# Current ssh attacks
#
# Called as ssh_attacks             $TMP_HTML_DIR $YEAR $PATH_TO_VAR_LOG DATE "messages*"
#
sub ssh_attacks {
	my $TMP_HTML_DIR=shift;
	my $DEBUG_DATE;
	&is_directory_good ("$TMP_HTML_DIR");
	my $YEAR=shift;
	if ($YEAR < 2014){print "BAD YEAR, Year is less than 2014.  YEAR is $YEAR\n";exit;}
	if ($YEAR < 2016){print "BAD YEAR, Year is greater than 2016.  YEAR is $YEAR\n";exit;}
	my $PATH_TO_VAR_LOG=shift;
	my $DATE=shift;
	my $MESSAGES=shift;
	my $FILE_PREFIX=shift;
	my $print_line=1;
	if (  $DEBUG  == 1 ) {
		print "\n============================================================\n";
		$DEBUG_DATE=`date`;
		print "$DEBUG_DATE";
		print "DEBUG TMP_HTML_DIR=$TMP_HTML_DIR, YEAR=$YEAR, PATH_TO_VARLOG=$PATH_TO_VAR_LOG, DATE=$DATE, MESSAGES=$MESSAGES, FILE_PREFIX=$FILE_PREFIX\n" ; 
	}

	#
	# I do a chdir ("tp $PATH_TO_VAR_LOG to reduce the commandline length.  If the 
	# commandline is too long and breaks on your system due to there being 
	# way too many files in the directory,  you should probably be using
	# some other tool.
	my $ORIGINAL_DIRECTORY=`pwd`;
	chdir ("$PATH_TO_VAR_LOG");

	#
	# I hate making temporary files, but I have to so this doesn't take forever to run
	#
	# NOTE: Sometimes attackers use a malformed attack and don't specify
	# a username, so I am changing the Username field to NO-USERNAME-PROVIDED those attacks now
	# Example: 2015-02-26T12:46:40.500085-05:00 shepherd sshd-2222[28001]: IP: 107.150.35.218 Pass2222Log: Username:  Password: qwe123
	# So we grep out Username:\ \  so my reports work
	# It took 55 days for this bug to show up

	if ( $DEBUG  == 1 ) { print  "DEBUG-Making temp file now "  ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }

	if ( "x$HOSTNAME" eq "x/" ) {
		if ( $DEBUG  == 1 ) {
			print "hostname is not set\n";
			print "PROTOCOL is $PROTOCOL\n";
			print "Making tmp file $TMP_DIRECTORY/LongTail-messages.$$ now\n";
		}
		#
		# Because $MESSAGES can be several files, some compressed
		# I can't use the perl 'seek' command to speed things up
		# this sucks.
		open (FILE, "$SCRIPT_DIR/catall.sh $MESSAGES|");
		open (OUTPUT, ">$TMP_DIRECTORY/LongTail-messages.$$");
		$print_line=1;
		my $re_date= qr/^$DATE/;
		my $re_protocol =qr/$PROTOCOL/;
		if ($DATE eq "\."){ # We are looking for all dates.  This means we are using pre-built and filtered files :-)
			while (<FILE>){
				print (OUTPUT "$_");
			}
		}
		else {
			while (<FILE>){
				# How am I searching for multiple dates?  I better be using the 
				# premade data files
				if (/^$DATE/){
					if (/$PROTOCOL/){
						if (/ Password: /){ # OK, this is probably a LongTail line
							$_ =~ s/Username:\ \ $/Username: NO-USERNAME-PROVIDED /;
							foreach $key (keys %LongTail_exclude_IPs_ssh_grep){
								if ($_ =~ $key){$print_line=0;last;}  
							}
							if ($print_line){
								foreach $key (keys %LongTail_exclude_accounts_ssh_grep){
									if ($_ =~ $key){$print_line=0;last;}  
								}
							}
							if ($print_line){
								print (OUTPUT "$_");
							}
							$print_line=1;
						}
					}
				}
			}
		}
		close (FILE);
		close (OUTPUT);
		if ( $DEBUG  == 1 ) { print  "DEBUG-Done Making temp file now "  ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		if ( $KIPPO == 1 ) {
#NOTYETCONVERTED			$SCRIPT_DIR/catall.sh $MESSAGES |grep ssh |grep "$DATE"|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep | grep login\ attempt | sed -e 's/ /T/' \
#NOTYETCONVERTED  -e 's/.SSHService ssh-userauth on HoneyPotTransport,.*,//' \
#NOTYETCONVERTED  -e 's/\]/ /' \
#NOTYETCONVERTED  -e 's/\] failed$//' \
#NOTYETCONVERTED  -e 's/\[//' \
#NOTYETCONVERTED  -e 's/ / LOCALHOST sshd-22[9999]: IP: /' \
#NOTYETCONVERTED  -e 's/login attempt/PassLog: Username:/' \
#NOTYETCONVERTED  -e 's/\// Password: /' \
#NOTYETCONVERTED  > $TMP_DIRECTORY/LongTail-messages.$$
#NOTYETCONVERTEDls -l $TMP_DIRECTORY/LongTail-messages.$$
		}


		if ( $REBUILD  != 1 ) {
			if ( $DEBUG  == 1 ) { print  "DEBUG-Making all_messages file now "  ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			`$SCRIPT_DIR/catall.sh $MESSAGES | grep ssh |grep "$DATE"  > $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages`;

			&touch ("$TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz");
			unlink ("$TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz");
			`gzip $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages`;
			`chmod 0000 $TMP_HTML_DIR/historical/$YEAR_AT_START_OF_RUNTIME/$MONTH_AT_START_OF_RUNTIME/$DAY_AT_START_OF_RUNTIME/all_messages.gz`;
			if ( $DEBUG  == 1 ) { print  "DEBUG-Done Making all_messages file now "  ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		}
	}
	else {
		print "hostname IS set to $HOSTNAME.\n";
		print "THIS CODE SUCKS, Please fix it!!!!\n\n";
		print "THIS CODE SUCKS, Please fix it!!!!\n\n";
		print "THIS CODE SUCKS, Please fix it!!!!\n\n";
	if ( $DEBUG  == 1 ) { print  "DEBUG-Making temp file for HOSTNAME:$HOSTNAME now "  ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		`$SCRIPT_DIR/catall.sh $MESSAGES |awk '\$2 == \"$HOSTNAME\" {print}' |grep $PROTOCOL |grep "$DATE"|grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep | grep Password |sed 's/Username:\ \ /Username: NO-USERNAME-PROVIDED /'  > $TMP_DIRECTORY/LongTail-messages.$$`;
	}

	#-------------------------------------------------------------------------
	# Root
	#
	# This takes longer to run than "admin" passwords because there are so 
	# many more root passwords to look at.
	#
	if ( $DEBUG  == 1 ) {  print  "DEBUG-ssh_attack 1:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml", "Root Passwords", " ", "Count", "Password");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml", "Admin Passwords", " ", "Count", "Password");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml", "Non Root Passwords", " ", "Count", "Password");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml", "Non Root Accounts", " ", "Count", "Password");

	open (INPUT, "$TMP_DIRECTORY/LongTail-messages.$$");
	open (OUTPUT_ROOT_PASSWORDS_TO_BE_SORTED, ">>$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.tmp.data");
	open (OUTPUT_ADMIN_PASSWORDS_TO_BE_SORTED, ">>$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.tmp.data");
	open (OUTPUT_NON_ROOT_PASSWORDS_TO_BE_SORTED, ">>$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.tmp.data");
	open (OUTPUT_NON_ROOT_ACCOUNTS_TO_BE_SORTED, ">>$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.tmp.data");
	open (OUTPUT_IP_ADDRESSES, ">$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.tmp.txt");
	open (OUTPUT_PAIRS_ADDRESSES, ">$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.tmp.data");
	while (<INPUT>){
		$original_line=$_;
		#
		# Figure out the hour of attack and store it
		#
		if (/Username\:\ /){
			($hour,$trash)=split(/:/,$original_line);
			$hour =~ s/^..*://;
			$hour =~ s/^.*T//;
			$attacks_by_hour[$hour]++;
		}
		if (/Username\:\ /){
			$tmp_ip=$original_line;
			$tmp_ip =~ s/^..*IP: //;
			$tmp_ip =~ s/ Pass..*//;
			print (OUTPUT_IP_ADDRESSES "$tmp_ip");
		}
		# 
		# Get the IP addresses
		#
		#
		# Figure out root and admin passwords attempted
		#
		if (/Username\:\ root/){
			$_ =~ s/^..*Password: //;
			$_ =~ s/^..*Password:$/ /;
			$_ =~ s/ /\&nbsp;/g;
			print (OUTPUT_ROOT_PASSWORDS_TO_BE_SORTED $_);
		}
		elsif (/Username\:\ admin/){
#print "DEBUG admin password found\n";
      $_ =~ s/^..*Password: //;
      $_ =~ s/^..*Password:$/ /;
      $_ =~ s/ /\&nbsp;/g;
      print (OUTPUT_ADMIN_PASSWORDS_TO_BE_SORTED $_);
    } else { # This is non root and non admin account territory...
			$tmp_account=$original_line;
			$tmp_account =~ s/^..*Username: //;
			$tmp_account =~ s/ Password: .*$//;
			print (OUTPUT_NON_ROOT_ACCOUNTS_TO_BE_SORTED $tmp_account);

			$tmp_password=$original_line;
			$tmp_password =~ s/..* Password: //;
			print (OUTPUT_NON_ROOT_PASSWORDS_TO_BE_SORTED $tmp_password);

			$tmp_line=$original_line;
			$tmp_line =~ s/^...*Username: //;
			$tmp_line =~ s/ Password: /:/;
			$tmp_line =~ s/ /\&nbsp/g;
			print (OUTPUT_PAIRS_ADDRESSES $tmp_line);
		}

	}
	close (INPUT);
	close (OUTPUT_ROOT_PASSWORDS_TO_BE_SORTED);
	close (OUTPUT_ADMIN_PASSWORDS_TO_BE_SORTED);
	close (OUTPUT_NON_ROOT_PASSWORDS_TO_BE_SORTED);
	close (OUTPUT_NON_ROOT_ACCOUNTS_TO_BE_SORTED);
	close (OUTPUT_IP_ADDRESSES);
	close (OUTPUT_PAIRS_ADDRESSES);

	#
	# Temporary data accounts are made, not to make reports from them
	#

	#
	# Root passwords first
	#
	open (INPUT, "sort -T $TMP_DIRECTORY $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.tmp.data |uniq -c|sort -T $TMP_DIRECTORY -nr |");
	open (OUTPUT_ROOT_PASSWORDS, ">>$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml")||die "Can't open $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml, exiting now!\n";
	while (<INPUT>){
		chomp;
		$_ =~ s/^\s+//; #Clear all the leading spaces :-)
		@tmp=split(/ /,$_,2);
		print (OUTPUT_ROOT_PASSWORDS "<TR><TD>$tmp[0]</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">$tmp[1]</a> </TD></TR>\n");
	}
	close (INPUT);
	close (OUTPUT_ROOT_PASSWORDS);
	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.tmp.data");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml", "Top 20 Root Passwords", "", "Count", "Password");
	`grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml | head -21   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml`;
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml");
	`cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.shtml |grep -v HEADERLINE|sed -r 's\/^<TR><TD>\/\/' |sed 's\/<.a> <.TD><.TR>\/\/' |sed 's\/<.TD><TD><a..*34">\/ \/' |grep -v \^\$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.data`;
print "DEBUG Just made $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.data\n";
#$tmp=`ls -l $TMP_HTML_DIR/$FILE_PREFIX-top-20-root-passwords.data`;
#print $tmp;

	&touch ("$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml.gz");
	unlink("$TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml.gz");
	`gzip $TMP_HTML_DIR/$FILE_PREFIX-root-passwords.shtml`;


	#
	# admin passwords next
	#
	if ( $DEBUG  == 1 ) {print "DEBUG Doing admin passwords now\n";}
#$tmp=`ls -l $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.tmp.data`;
#print $tmp;

	open (INPUT, "sort -T $TMP_DIRECTORY $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.tmp.data |uniq -c|sort -T $TMP_DIRECTORY -nr |");
	open (OUTPUT_ADMIN_PASSWORDS, ">>$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml")||die "Can't open $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml, exiting now!\n";
	while (<INPUT>){
		chomp;
		$_ =~ s/^\s+//; #Clear all the leading spaces :-)
		@tmp=split(/ /,$_,2);
		print (OUTPUT_ADMIN_PASSWORDS "<TR><TD>$tmp[0]</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">$tmp[1]</a> </TD></TR>\n");
	}
	close (INPUT);
	close (OUTPUT_ADMIN_PASSWORDS);

	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.tmp.data");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml", "Top 20 Admin Passwords", "", "Count", "Password");
	`grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml | head -21   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml`;
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml");
	`cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.shtml |grep -v HEADERLINE|sed -r 's\/^<TR><TD>\/\/' |sed 's\/<.a> <.TD><.TR>\/\/' |sed 's\/<.TD><TD><a..*34">\/ \/' |grep -v \^\$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.data`;
#print "\n============================================================\n";
#$tmp=`ls -l $TMP_HTML_DIR/$FILE_PREFIX-top-20-admin-passwords.data`;
#print $tmp;

#	&touch ("$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml.gz");
#	unlink("$TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml.gz");
#	`gzip $TMP_HTML_DIR/$FILE_PREFIX-admin-passwords.shtml`;



	#
	# non-Root non-admin passwords 
	#
	open (INPUT, "sort -T $TMP_DIRECTORY $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.tmp.data |uniq -c|sort -T $TMP_DIRECTORY -nr |");
	open (OUTPUT_ROOT_PASSWORDS, ">>$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml")||die "Can't open $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml, exiting now!\n";
	while (<INPUT>){
		chomp;
		$_ =~ s/^\s+//; #Clear all the leading spaces :-)
		@tmp=split(/ /,$_,2);
		print (OUTPUT_ROOT_PASSWORDS "<TR><TD>$tmp[0]</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">$tmp[1]</a> </TD></TR>\n");
	}
	close (INPUT);
	close (OUTPUT_ROOT_PASSWORDS);

	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.tmp.data");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml", "Top 20 Non-Root Passwords", "", "Count", "Password");
	`grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml | head -21   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml`;
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-passwords.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml");
	`cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.shtml |grep -v HEADERLINE|sed -r 's\/^<TR><TD>\/\/' |sed 's\/<.a> <.TD><.TR>\/\/' |sed 's\/<.TD><TD><a..*34">\/ \/' |grep -v \^\$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-passwords.data`;

#print "DEBUG-done with non-root passwords\n";



	#
	# non Root and non admin accounts 
	#
	open (INPUT, "sort -T $TMP_DIRECTORY $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.tmp.data |uniq -c|sort -T $TMP_DIRECTORY -nr |");
	open (OUTPUT_ROOT_PASSWORDS, ">>$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml")||die "Can't open $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml, exiting now!\n";
	while (<INPUT>){
		chomp;
		$_ =~ s/^\s+//; #Clear all the leading spaces :-)
		@tmp=split(/ /,$_,2);
		print (OUTPUT_ROOT_PASSWORDS "<TR><TD>$tmp[0]</TD><TD><a href=\"https://www.google.com/search?q=&#34default+password+%s&#34\">$tmp[1]</a> </TD></TR>\n");
	}
	close (INPUT);
	close (OUTPUT_ROOT_PASSWORDS);

	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.tmp.data");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml", "Top 20 Non Root/Admin accounts", "", "Count", "Password");
	`grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml | head -21   >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml`;
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-accounts.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml");
	`cat $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.shtml |grep -v HEADERLINE|sed -r 's\/^<TR><TD>\/\/' |sed 's\/<.a> <.TD><.TR>\/\/' |sed 's\/<.TD><TD><a..*34">\/ \/' |grep -v \^\$ > $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-accounts.data`;

#print "DEBUG-done with non-root accounts\n";

	#-------------------------------------------------------------------------
	# This works but gives only IP addresses
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5 " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml", "IP Addresses", " ", "Count", "IP Address", "Country", "WhoIS", "Blacklisted", "Attack Patterns");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml", "Top 20 IP Addresses", " ", "Count", "IP Address", "Country", "WhoIS", "Blacklisted", "Attack Patterns");
	# I need to make a temp file for this

	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-a " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	if ( "x$HOSTNAME" eq "x/" ) {
		open (OUTPUT, ">$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt");
		print (OUTPUT "# http://longtail.it.marist.edu \n");
		print (OUTPUT "# This is a sorted list of IP addresses that have tried to login\n" );
		print (OUTPUT "# to a server related to LongTail.\n" );
		print (OUTPUT "# \n" );
		print (OUTPUT "# LEGAL DISCLAIMER\n" );
		print (OUTPUT "# This list is provided for research only.  We do not recommend or\n" );
		print (OUTPUT "# suggest importing this list into fail2ban, denyhosts, or any\n" );
		print (OUTPUT "# other tool that might block access.\n" );
		print (OUTPUT "# \n" );
		print (OUTPUT "# The format of the data is number of times seen, followed by the IP address\n" );
		print (OUTPUT "# \n" );
		$RIGHT_NOW=`date`;
		chomp $RIGHT_NOW;
		print (OUTPUT "# This list was created on: $RIGHT_NOW\n" );
		print (OUTPUT "# \n"  );
		close (OUTPUT);

	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-b " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
		`cat  $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.tmp.txt |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr >> $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt`;
		`mv $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp`;
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-c " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }

		`$SCRIPT_DIR/LongTail_add_country_to_ip.pl $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp > $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt`;
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-d " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
		`$SCRIPT_DIR/LongTail_make_map.pl $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt > $TMP_HTML_DIR/$FILE_PREFIX-map.html`;
		print "DEBUG $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp\n";
		print "DEBUG $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.tmp.txt\n";
	}
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-e " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }

	#
	# Code to try and add the country to the ip-addresses.shtml page
	`cat $TMP_DIRECTORY/LongTail-messages.$$  | grep IP: |grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | sed 's\/^.*IP: \/\/'|sed 's\/ Pass..*$\/\/' |sort -T $TMP_DIRECTORY |uniq -c |sort -T $TMP_DIRECTORY -nr   > $TMP_DIRECTORY/Longtail.tmpIP.$$`;

	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-f " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	open (INPUT, "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt");
	open (OUTPUT, ">>$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml");
	while (<INPUT>){
		if (/#/){next;}
		chomp;
		$_ =~ s/^\s+//;
		($count,$ip,$country)=split(/ /,$_,3);
		print (OUTPUT "<TR><TD>$count</TD><TD>$ip</TD><TD>$country</TD><TD><a href=\"http://whois.urih.com/record/$ip\">Whois lookup</A></TD><TD><a href=\"http://www.dnsbl-check.info/?checkip=$ip\">Blacklisted?</A></TD><TD><a href=\"/$HTML_TOP_DIR/ip_attacks.shtml#$ip\">Attack Patterns</A></TD></TR>\n");
	}
	close (INPUT);
	close (OUTPUT);
	
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-g " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }

	unlink("$TMP_DIRECTORY/Longtail.tmpIP.$$");
	unlink ("$TMP_DIRECTORY/Longtail.tmpIP.$$-2");
	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt.tmp");
	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.tmp.txt");

	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-h " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	`sed -i s\/HONEY\/$HTML_TOP_DIR\/g $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml`;

	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-i " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	`grep -v HEADERLINE $TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml |head -20 |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml`;
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-j " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }

	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-ip-addresses.shtml");

	#-------------------------------------------------------------------------
	# This translates IPs to countries
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 6, doing whois.pl lookups " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml", "Attacks by Country", " ", "Count", "Country");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml", "Top 20 Countries", " ", "Count", "Country");
	# I need to make a temp file for this


#WHOIS.PL

	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-k " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	open (FILE2, "$TMP_HTML_DIR/$FILE_PREFIX-ip-addresses.txt");
	open (FILE3, ">$TMP_DIRECTORY/$FILE_PREFIX-ip-addresses.txt.$$");
	while (<FILE2>){
		if (/#/){next;}
		chomp;
		$_ =~ s/\s+//;
		$_ =~ s/\(.+$//;
		($count, $ip_address,$country)=split(/\s+/,$_);
		print (FILE3 "$country\n");
		
	}
	close (FILE2);
	close (FILE3);
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-l " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	`sort $TMP_DIRECTORY/$FILE_PREFIX-ip-addresses.txt.$$ |uniq -c |sort -nr > $TMP_DIRECTORY/$FILE_PREFIX-ip-addresses.txt.$$.2`;
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-m " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	unlink ("$TMP_DIRECTORY/$FILE_PREFIX-ip-addresses.txt.$$");
	open (FILE2, "$TMP_DIRECTORY/$FILE_PREFIX-ip-addresses.txt.$$.2");
	open (FILE3, ">>$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml");
	while (<FILE2>){
		chomp;
		$_ =~ s/^\s+//;
		($count,$country)=split (/ /,$_,2);
		print (FILE3 "<TR><TD>$count</TD><TD>$country</TD></TR>\n");
	}
	close (FILE2);
	close (FILE3);
	unlink ("$TMP_DIRECTORY/$FILE_PREFIX-ip-addresses.txt.$$.2");
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-n " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }

	`sed -i -f $SCRIPT_DIR/translate_country_codes.sed  $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml`;
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-o " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	`tail -20 $TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml |grep -v HEADERLINE >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml`
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-attacks-by-country.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-attacks-by-country.shtml");
	
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 5-p " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; ; }
	#-------------------------------------------------------------------------
	# Figuring out most common non-root pairs
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 7 Figuring out most common non-root pairs " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml", "Non Root Pairs", " ", "Count", "Account:Password");
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs.shtml", "Top 20 Non Root Pairs", " ", "Count", "Account:Password");
	if ( $DEBUG  == 1 ) { print "DEBUG current non-root-pairs\n"; }
	if ( $DEBUG  == 1 ) { print "DEBUG Non-current non-root-pairs, DATE is $DATE\n"; }
	open (INPUT, "sort -T $TMP_DIRECTORY $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.tmp.data | uniq -c|sort -T $TMP_DIRECTORY -nr|");
	open (OUTPUT, ">> $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml");
	while (<INPUT>){
		$_=~ s/^\s*//;
		chomp;
		($tmp1,$tmp2)=split(/\s/,$_);
		print (OUTPUT "<TR><TD>$tmp1</TD><TD>$tmp2</TD></TR>\n");
	}
	close (INPUT);
	close (OUTPUT);

	`cat  $TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml |grep -v HEADERLINE |head -20 >> $TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs.shtml`;

	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.shtml");
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-top-20-non-root-pairs.shtml");
	unlink ("$TMP_HTML_DIR/$FILE_PREFIX-non-root-pairs.tmp.data");

	#-------------------------------------------------------------------------
	# Report ssh-attacks-by-time-of-day (Data collected earlier)
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 7B Figuring out ssh-attacks-by-time-of-day " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	&make_header ("$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day.shtml", "Historical SSH Attacks By Time Of Day", "", "Hour of Day", "Count");
	open (OUTPUT, ">>$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day.shtml");
	my $hour_counter=0;
	while ($hour_counter<24){
		print (OUTPUT "<TR><TD>$hour_counter</TD><TD>$attacks_by_hour[$hour_counter]</TD></TR>\n");
		$attacks_by_hour[$hour_counter]=0;
		$hour_counter++;
	}
	close (OUTPUT);
	&make_footer ("$TMP_HTML_DIR/$FILE_PREFIX-ssh-attacks-by-time-of-day.shtml");

	#-------------------------------------------------------------------------
	# raw data compressed 
	# This only prints the account and the password
	# This is different from the temp file I make earlier as it does
	# a grep for both Password AND password (Note the capitalization differences).
	if ( $DEBUG  == 1 ) { print  "DEBUG-ssh_attack 8, gathering data for raw-data.gz " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	if ( $FILE_PREFIX eq "current" ) {
		if ( $OBFUSCATE_IP_ADDRESSES > 0 ) {
#NOTYETCONVERTED			cat $TMP_DIRECTORY/LongTail-messages.$$  |sed -r 's/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)[0-9]{1,3}/\1127/g'  |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz
		print "DEBUG OBFUSCATE_IP_ADDRESSES disabled for now\n";
		} else{
			`cat $TMP_DIRECTORY/LongTail-messages.$$ |gzip -c > $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz`;
			}
		}
		# Code do avoid doing this if REBUILD is set
		if ( $REBUILD  != 1 ) {
			print "REBUILD NOT SET, copying .gz file now\n";
			# Lets make sure we have one for today and this month and this year
			# I added this code on 2015-03-17, Lets see if it breaks anything...
			$TMP_YEAR=`date +%Y`;
			$TMP_MONTH=`date +%m`;
			$TMP_DAY=`date +%d`;
			chomp $TMP_YEAR;
			chomp $TMP_MONTH;
			chomp $TMP_DAY;
	
			$TMP_DIR="$TMP_HTML_DIR";
			if ( ! -d $TMP_DIR  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR`; }
			$TMP_DIR="$TMP_HTML_DIR/historical";
			if ( ! -d $TMP_DIR  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR`; }
			$TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR";
			if ( ! -d $TMP_DIR  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR`; }
			$TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH";
			if ( ! -d $TMP_DIR  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR`; }
			$TMP_DIR="$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY";
			if ( ! -d $TMP_DIR  ) { `mkdir $TMP_DIR ; chmod a+rx $TMP_DIR`; }
			`cp $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz`;
			`chmod a+r $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-raw-data.gz`;
			@tmp_array=split(/ /,$HOSTS_PROTECTED);
			foreach (@tmp_array){
				if ("x$HOSTNAME" eq "x$dir" ) {
					&touch ("$TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday");
					print "Touching $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday\n";
				}
			}
		} else {
			print "REBUILD SET, NOT copying .gz file now\n"
		} 

	if ( $DEBUG ) { print  "Wrote to $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz "; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	#
	# I only need the count data for today, so there's no point counting 7, 30, or historical
	#
	if ( $FILE_PREFIX eq "current" ) {
		$TODAY=`$SCRIPT_DIR/catall.sh $TMP_HTML_DIR/$FILE_PREFIX-raw-data.gz  |grep $PROTOCOL | grep -F -vf $SCRIPT_DIR/LongTail-exclude-IPs-ssh.grep | grep -F -vf $SCRIPT_DIR/LongTail-exclude-accounts.grep  |egrep Password|wc -l`;
		chomp $TODAY;
		open (OUTPUT, ">$TMP_HTML_DIR/$FILE_PREFIX-attack-count.data");
		print (OUTPUT "$TODAY");
		close (OUTPUT);
	}

	#
	# read and run any LOCALLY WRITTEN reports
	# 2015-12-28 NOT going to support this anymore.
	#
	# if ( $DEBUG ) { print "Running ssh-local-reports\n"; }
	#. $SCRIPT_DIR/Longtail-ssh-local-reports

	# chdir ("back to the original directory.  this should be the last command in 
	# the function.
	chdir ("$ORIGINAL_DIRECTORY");
#	unlink("$TMP_DIRECTORY/LongTail-messages.$$");
	if ( $DEBUG  == 1 ) { print  "DEBUG-Done with ssh_attack: " ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	`date > $TMP_HTML_DIR/date_updated.txt`;
}

sub really_make_trends {
	#
	# Called as really_make_trends ("input_filname","output_file");
	my $TMPFILE=`mktemp $TMP_DIRECTORY/output.XXXXXXXXXX`;
	chomp $TMPFILE;
	my $TMPFILE2=`mktemp $TMP_DIRECTORY/output.XXXXXXXXXX`;
	my $input_filename=shift;
	my $output_filename=shift;
	print "$input_filename\n";
	print "$output_filename\n";
	chomp $TMPFILE2;
	chdir ("$HTML_DIR/historical");
	open (INPUT, "find . -name $input_filename|sort -T $TMP_DIRECTORY -nr|");
	open (OUTPUT, ">$TMPFILE");
	if ( $DEBUG  == 1 ) { print "DEBUG tmpfile is $TMPFILE\n";}
	while (<INPUT>){
		chomp;
		$FILE=$_;
		if (/HEADERLINE/){next;}
		print (OUTPUT "<TR>\n");
		print (OUTPUT "<TD>\n"); 
		$TMP= "$FILE $FILE";
		$TMP =~ s/$input_filename//g;
		$TMP =~ s/\.\///g;
		$TMP =~ s/^/<A HREF=\"historical\//;
		$TMP =~ s/\/ /\/\">/;
		$TMP =~ s/$/ <\/a>/;
		print (OUTPUT "$TMP\n");
		print (OUTPUT "</TD>\n");
		open (INPUT_2, $FILE);
		while (<INPUT_2>){
			if (/HEADERLINE/){next;}
			chomp;
			if (/TR/){
				$_ =~ s/<TR><TD>/<TD>/;
				$_ =~ s/<.TD><TD>/:/;
				$_ =~ s/<.TR>//;
				print (OUTPUT "$_\n");
			}
		}
				print (OUTPUT "<\/TR>\n");
		close (INPUT_2);
	}
	close (OUTPUT);
	#
	# code to color code NEW entries
	#
	$password{"<TD>"}=1;
	open (FILE, "tac $TMPFILE|");
	open (FILE2, ">$TMPFILE2");
	while (<FILE>){
	chomp;
		if (/<A HREF="historical/){print (FILE2 "$_\n"); }
		else {
			if (/^<TD/){
				$line=$_;
				$tmp_line=$_;
				$tmp_line =~ s/^..*">//;
				$tmp_line =~ s/<\/a>.*$//;
				if (defined $password{"$tmp_line"}){
					print (FILE2 "$line\n");
				}
				else {
					$line =~ s/<TD/<TD bgcolor=#FF0000/;
					$password{"$tmp_line"}=1;
					print (FILE2 "$line\n");
				}
			}
			else {
				print (FILE2 "$_\n");
			}
		}
	}
	close (FILE);
	close (FILE2);
	`tac $TMPFILE2 >> $HTML_DIR/$output_filename`;
	unlink("$TMPFILE");
	unlink("$TMPFILE2");
}

#########################################################################
sub make_trends {	
	if ( $DEBUG  == 1 ) { print "\n\n\nDEBUG in make_trends\n";}
	if ( $START_HOUR == $MIDNIGHT ) {
	#if ( 23  == 23 ) {
		if ( $DEBUG  == 1 ) { print "DEBUG-doing trends\n" ; }
		#-----------------------------------------------------------------
		# Now lets do some long term ssh reports....  Lets do a comparison of 
		# top 20 non-root-passwords and top 20 root passwords
		#-----------------------------------------------------------------
		&make_header ("$HTML_DIR/trends-in-non-root-passwords.shtml", "Trends In Non Root Passwords From Most Common To 20th",  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20.", "Date", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20");
		&really_make_trends("current-top-20-non-root-passwords.shtml","trends-in-non-root-passwords.shtml");
		&make_footer ("$HTML_DIR/trends-in-non-root-passwords.shtml");
		`sed -i 's\/<TD>\/<TD class="td-some-name">\/g' $HTML_DIR/trends-in-non-root-passwords.shtml`;
	
		&make_header ("$HTML_DIR/trends-in-root-passwords.shtml", "Trends In Root Passwords From Most Common To 20th",  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20.", "Date", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20");
		&really_make_trends("current-top-20-root-passwords.shtml","trends-in-root-passwords.shtml");
		&make_footer ("$HTML_DIR/trends-in-non-root-passwords.shtml");
		`sed -i 's\/<TD>\/<TD class="td-some-name">\/g' $HTML_DIR/trends-in-root-passwords.shtml`;
	
		&make_header ("$HTML_DIR/trends-in-admin-passwords.shtml", "Trends In Admin Passwords From Most Common To 20th",  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20.", "Date", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20");
		&really_make_trends("current-top-20-admin-passwords.shtml","trends-in-admin-passwords.shtml");
		&make_footer ("$HTML_DIR/trends-in-non-root-passwords.shtml");
		`sed -i 's\/<TD>\/<TD class="td-some-name">\/g' $HTML_DIR/trends-in-admin-passwords.shtml`;
	
		&make_header ("$HTML_DIR/trends-in-accounts.shtml", "Trends In Accounts From Most Common To 20th",  "Format is number of tries : password tried.  Entries In red are the first time that entry was seen in the top 20.", "Date", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20");
		&really_make_trends("current-top-20-non-root-accounts.shtml","trends-in-accounts.shtml");
		&make_footer ("$HTML_DIR/trends-in-accounts.shtml");
		`sed -i 's\/<TD>\/<TD class="td-some-name">\/g' $HTML_DIR/trends-in-accounts.shtml`;
	}
}
#
############################################################################
#
# Example input line: 
# 2015-02-26T12:46:40.500085-05:00 shepherd sshd-2222[28001]: IP: 107.150.35.218 Pass2222Log: Username:  Password: qwe123
# 2015-02-26T12:46:40.500085-05:00 shepherd sshd-22[28001]: IP: 107.150.35.218 PassLog: Username:  Password: qwe123
# 2015-02-26T12:46:40.500085-05:00 shepherd sshd[28001]: STUFF
# 2015-02-26T12:46:40.500085-05:00 shepherd telnet-honeypot[28001]: IP: 107.150.35.218 TelnetLog: Username:  Password: qwe123

sub do_ssh {
	if ( $DEBUG  == 1 ) { print "DEBUG-in do_ssh now\n" ; }
	#-----------------------------------------------------------------
	# Lets check the ssh logs
	&ssh_attacks ("$HTML_DIR", "$YEAR", "$PATH_TO_VAR_LOG", "$DATE", "$LOGFILE*", "current");

	# Lets count the ssh attacks
	&count_ssh_attacks ("$HTML_DIR", "$PATH_TO_VAR_LOG", "$LOGFILE*");
	

	if ( $START_HOUR == $MIDNIGHT ) {
		if ( $DEBUG  == 1 ) { print "DEBUG-in do_ssh/last 7 days  now\n" ; }
		#----------------------------------------------------------------
		# Lets check the ssh logs for the last 7 days
		$LAST_WEEK="";
		$i=1;
		while ($i < 8) {
			$TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`;
			chomp $TMP_DATE;
print "DEBUG looking for $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz\n";
			if ( -e "$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz" ) {
				if ( "$LAST_WEEK" eq "" ) {
					$LAST_WEEK="$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz";
				} else {
					$LAST_WEEK="$LAST_WEEK $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz";
				}
			}
			$i++;
		}
		if ( $DEBUG  == 1 ) { print "DEBUG-done with do_ssh/last 7 days  now\n" ; }
		$TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG;
		if ( $DEBUG  == 1 ) { print "DEBUG-calling last 7 days report now\n" ;;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
#print "\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
#print "Calling ssh attacks with HTML_DIR=$HTML_DIR, YEAR=$YEAR, /, ., $LAST_WEEK, last-7-days\n";
		&ssh_attacks ($HTML_DIR, $YEAR, "/", ".", "$LAST_WEEK", "last-7-days");
		$PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG;
	
		#----------------------------------------------------------------
		# Lets check the ssh logs for the last 30 days
		if ( $DEBUG  == 1 ) { print "DEBUG-in do_ssh/last 30 days  now\n" ; }
		$LAST_MONTH="";
		$i=1;
		while ($i < 31) {
			$TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`;
			chomp $TMP_DATE;
			if ( -e "$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz" ) {
				if ( "$LAST_MONTH" eq "" ) {
					$LAST_MONTH="$HTML_DIR/historical/$TMP_DATE/current-raw-data.gz";
				} else {
					$LAST_MONTH="$LAST_MONTH $HTML_DIR/historical/$TMP_DATE/current-raw-data.gz";
				}
			}
			$i++;
		}
		$TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG;
		if ( $DEBUG  == 1 ) { print "DEBUG-calling last 30 days report now\n" ;;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		&ssh_attacks ($HTML_DIR, $YEAR, "/", ".", "$LAST_MONTH", "last-30-days");
		$PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG;

		if ( $DEBUG  == 1 ) { print "DEBUG-in do_ssh/historical  now\n" ;;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		$TMP_PATH_TO_VAR_LOG=$PATH_TO_VAR_LOG;
		if ( $DEBUG  == 1 ) { print "DEBUG-calling historical report now\n" ;;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
		&ssh_attacks ($HTML_DIR, $YEAR, "/$HTML_DIR/historical/", ".",      "*/*/*/current-raw-data.gz", "historical");
		$PATH_TO_VAR_LOG=$TMP_PATH_TO_VAR_LOG;
		#----------------------------------------------------------------
		# Lets make zero out the last-30-days-attack-count.data
		open (TMP_FILE,">$HTML_DIR/last-30-days-attack-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-sshpsycho-attack-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-sshpsycho-2-attack-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-todays-uniq-passwords-txt-count.data"); close (TMP_FILE);
		open (TMP_FILE,">$HTML_DIR/last-30-days-todays-uniq-usernames-txt-count.data"); close (TMP_FILE);
		$i=1;
		while ($i < 31){
			#if ( $DEBUG  == 1 ) { print "DEBUG-i is set to $i\n" ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			#if ( $DEBUG  == 1 ) { print "DEBUG-in do_ssh/last 30 days misc stuff  now\n" ; }
			$TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`;
			chomp $TMP_DATE;
			$TMP_DATE2=`date "+%m/%d" --date="$i day ago"`;
			chomp $TMP_DATE2;
#print "DEBUG-da"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-attack-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/current-attack-count.data" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-attack-count.data`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} 
			else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-db"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">>  $HTML_DIR/last-30-days-sshpsycho-attack-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-attack-count.data" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-attack-count.data`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-dc"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-2-attack-count.data" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-sshpsycho-2-attack-count.data`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-dd"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">>$HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/current-friends_of_sshpsycho-attack-count.data" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-friends_of_sshpsycho-attack-count.data`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-de"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/current-associates_of_sshpsycho-attack-count.data" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/current-associates_of_sshpsycho-attack-count.data`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-df"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/todays-uniq-ips.txt.count" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-ips.txt.count`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-dg"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-todays-uniq-passwords-txt-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/todays-uniq-passwords.txt.count" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-passwords.txt.count`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

#print "DEBUG-dh"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-todays-uniq-usernames-txt-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/todays-uniq-usernames.txt.count" ) {
				$tmp_attack_count=`cat /$HTML_DIR/historical/$TMP_DATE/todays-uniq-usernames.txt.count`;
				chomp ($tmp_attack_count);
				print (TMP_OUTPUT "$tmp_attack_count $TMP_DATE2\n");
			} else {
				#echo "Can't find /$HTML_DIR/historical/$TMP_DATE/todays-uniq-usernames.txt.count "
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);
			$i++;
		} # End of if ( $START_HOUR == $MIDNIGHT )

#print "DEBUG-"; $DEBUG_DATE=`date`; print "$DEBUG_DATE";
		
			if ( $DEBUG  == 1 ) { print "DEBUG-reversing files  now\n" ; }
		foreach (split (/\s+/,"$HTML_DIR/last-30-days-sshpsycho-attack-count.data $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-todays-uniq-usernames-txt-count.data $HTML_DIR/last-30-days-todays-uniq-passwords-txt-count.data $HTML_DIR/last-30-days-todays-uniq-ips-txt-count.data $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data") ){
			print "DEBUG reversing file $_ now\n";
			$file =$_;
			`cp $file $file.tmp`;
			`tac $file.tmp > $file`;
			`rm $file.tmp`;
		}


		#----------------------------------------------------------------
		# Lets make last-30-days-ips-count.data, last-30-days-password-count.data, last-30-days-username-count.data
		# This makes files with the COUNT of the last 30 days attacks, or whatever 
		# and these files are used for making the 30 day graphs.
		open (TMP_FILE,">$HTML_DIR/last-30-days-ips-count.data");
		close (TMP_FILE);
		open (TMP_FILE," > $HTML_DIR/last-30-days-username-count.data");
		close (TMP_FILE);
		open (TMP_FILE, "> $HTML_DIR/last-30-days-password-count.data");
		close (TMP_FILE);
		$i=1;
		while ($i < 31){
			#if ( $DEBUG  == 1 ) { print "DEBUG-i is set to $i\n" ;$DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			#if ( $DEBUG  == 1 ) { print "DEBUG-in do_ssh/last 30 days misc stuff  now\n" ; }
			$TMP_DATE=`date "+%Y/%m/%d" --date="$i day ago"`;
			chomp $TMP_DATE;
			$TMP_DATE2=`date "+%m/%d" --date="$i day ago"`;
			chomp $TMP_DATE2;

			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-password-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/todays_password.count" ) {
				$tmp_password=`cat /$HTML_DIR/historical/$TMP_DATE/todays_password.count`;
				chomp ($tmp_password);
				print (TMP_OUTPUT "$tmp_password $TMP_DATE2\n" );
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-username-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/todays_username.count" ) {
				$tmp_username=`cat /$HTML_DIR/historical/$TMP_DATE/todays_username.count`;
				chomp ($tmp_username);
				print (TMP_OUTPUT "$tmp_username $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);

			open (TMP_OUTPUT, ">> $HTML_DIR/last-30-days-ips-count.data");
			if ( -e "/$HTML_DIR/historical/$TMP_DATE/todays_ips.count" ) {
				$tmp_ips=`cat /$HTML_DIR/historical/$TMP_DATE/todays_ips.count`;
				chomp ($tmp_ips);
				print (TMP_OUTPUT "$tmp_ips $TMP_DATE2\n");
			} else {
				print (TMP_OUTPUT "0 $TMP_DATE2\n");
			}
			close (TMP_OUTPUT);
			$i++;
		} # end of while ($i < 31)

		`cp $HTML_DIR/last-30-days-password-count.data $HTML_DIR/last-30-days-password-count.data.tmp`;
		`tac $HTML_DIR/last-30-days-password-count.data.tmp > $HTML_DIR/last-30-days-password-count.data`;
		`rm $HTML_DIR/last-30-days-password-count.data.tmp`;

		`cp $HTML_DIR/last-30-days-username-count.data $HTML_DIR/last-30-days-username-count.data.tmp`;
		`tac $HTML_DIR/last-30-days-username-count.data.tmp > $HTML_DIR/last-30-days-username-count.data`;
		`rm $HTML_DIR/last-30-days-username-count.data.tmp`;

		`cp $HTML_DIR/last-30-days-ips-count.data $HTML_DIR/last-30-days-ips-count.data.tmp`;
		`tac $HTML_DIR/last-30-days-ips-count.data.tmp > $HTML_DIR/last-30-days-ips-count.data`;
		`rm $HTML_DIR/last-30-days-ips-count.data.tmp`;

	} # end of if ( $START_HOUR == $MIDNIGHT )


	# This is an example of how to call ssh_attacks for past dates and 
	# put the reports in the $HTML_DIR/historical/Year/month/date directory
	# Make sure you edit the date in BOTH places in the line.
	#

	# Example of getting a single date.  Make sure you edit the date in BOTH places in the line.
	#	ssh_attacks $HTML_DIR/historical/2015/02/24 $YEAR $PATH_TO_VAR_LOG "2015-02-24"      "$LOGFILE*" "current"
	
	
	#-----------------------------------------------------------------
	chdir ("$HTML_DIR/");
	if ( $DEBUG  == 1 ) { print "DEBUG-Making Graphics now\n" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	if ( $GRAPHS == 1 ) {
	#
	# Deal with creating empty 7-day, 30-day and historical files the 
	# first time this is run
	print "\nMaking Graphics now\n\n";
	if ( ! -e "last-7-days-top-20-admin-passwords.data" ) {
		&touch ("current-attack-count.data");
		&touch ("current_attackers_lifespan.data");
		&touch ("current-top-20-admin-passwords.data");
		&touch ("current-top-20-non-root-accounts.data");
		&touch ("current-top-20-non-root-passwords.data");
		&touch ("current-top-20-root-passwords.data");
		&touch ("historical-top-20-admin-passwords.data");
		&touch ("historical-top-20-non-root-accounts.data");
		&touch ("historical-top-20-non-root-passwords.data");
		&touch ("historical-top-20-root-passwords.data");
		&touch ("last-30-days-top-20-admin-passwords.data");
		&touch ("last-30-days-top-20-non-root-accounts.data");
		&touch ("last-30-days-top-20-non-root-passwords.data");
		&touch ("last-30-days-top-20-root-passwords.data");
		&touch ("last-7-days-top-20-admin-passwords.data");
		&touch ("last-7-days-top-20-non-root-accounts.data");
		&touch ("last-7-days-top-20-non-root-passwords.data");
		&touch ("last-7-days-top-20-root-passwords.data");
		&touch ("last-30-days-attack-count.data");
		&touch ("last-30-days-ips-count.data");
	}

print "DEBUG-Graphics-looking for data files\n";
	open (LS, "/bin/ls current*.data|");
	while (<LS>){
		chomp;
#print "\n\n\n";
#print "DEBUG file is $_\n";
		if (/tmp.data/){next;}
		$FILE=$_;
#print "DEBUG AAAAA  FILE is -->$FILE<--\n";
		if ( "$FILE" ne "current-attack-count.data" ) {
#print "DEBUG BBBBB found a good file-->$FILE<--\n";
			$MAP=$FILE; 
			$MAP =~ s/\.data/\.map/; 

			$GRAPHIC_FILE=$FILE; 
			$GRAPHIC_FILE=~ s/\.data/\.png/;

			$TITLE=$FILE;
			$TITLE =~ s/non-root-passwords/non-root-non-admin-passwords/;
			$TITLE =~  s/last/Prior/;
			$TITLE =~ s/-/ /g;
			$TITLE =~ s/.data//;

			#capitalize the first letter in each word
			$TITLE=~ s/([\w']+)/\u\L$1/g;

			#$TITLE=$TMP_TITLE;

			$TITLE=~ s/Top 20 Admin Passwords/Top 20 Username \"admin\" Passwords/;
#print "DEBUG FILE is $FILE, TITLE is $TITLE, GRAPHIC_FILE is $GRAPHIC_FILE\n";

			if ( -s "$FILE" ) {
				# Hack to make sure we use the real "top 20 non root accounts"
				if ( "$FILE" eq "current-top-20-non-root-accounts.data" ) {
					$FILE="current-top-20-non-root-accounts-real.data";
				}
				if ($FILE =~ /accounts/ ) {
#print "DEBUG-11111-accounts file is $FILE\n";
					$tmp=`php /usr/local/etc/LongTail_make_graph.php "$FILE" "$TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE`;
					#print "php output is: $tmp\n";
					`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  "$FILE"  >$MAP`;
				}
				if ($FILE =~ /password/) {
#print "DEBUG-2222-password file is $FILE\n";
					$tmp=`php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE`;
					`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  "$FILE"  >$MAP`;
				}
			} else { #We have an empty file, deal with it here
				open (TMPFILE, ">$TMP_DIRECTORY/LongTail.data.$$");
				print (TMPFILE "0 0\n");
				close (TMPFILE);
				if ( $FILE =~ /accounts/ ) {
					$tmp=`php /usr/local/etc/LongTail_make_graph.php "$TMP_DIRECTORY/LongTail.data.$$" "Not Enough Data Today For $TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE`;
					#print "php output is: $tmp\n";
					open (TMPFILE, ">$MAP");
					close (TMPFILE);
				}
				if ( $FILE =~ /password/ ) {
					$tmp=`php /usr/local/etc/LongTail_make_graph.php "$TMP_DIRECTORY/LongTail.data.$$" "Not Enough Data Today For $TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE`;
					#print "php output is: $tmp\n";
					open (TMPFILE, ">$MAP");
					close (TMPFILE);
				}
				if ( -e "$TMP_DIRECTORY/LongTail.data.$$"){
					unlink ("$TMP_DIRECTORY/LongTail.data.$$");
				}
			}
		}
	} # end of while (<LS>)         

#print "DEBUG - exiting now while I get graphics to work properly!\n";
#exit;
		
	print "\n";
	print "checking to see if we need to make midnight Graphics now\n";
	print "midnight is set to $MIDNIGHT\n";
	print "\n";;
	if ( $START_HOUR == $MIDNIGHT ) {
	#if ( $START_HOUR == 16 ) {
		print "\nMaking midnight Graphics now\n\n";
		open (LS, "/bin/ls historical*.data last-*.data |");
		while (<LS>){
			chomp;
			$FILE=$_;
			if ( "$FILE" ne "current-attack-count.data" ) {
				$MAP=$FILE;
				$MAP =~ s/\.data/\.map/;

				$GRAPHIC_FILE=$FILE;
				$GRAPHIC_FILE=~ s/\.data/\.png/;

				$TITLE=$FILE;
				$TITLE =~ s/non-root-passwords/non-root-non-admin-passwords/;
				$TITLE =~ s/last/Prior/;
				$TITLE =~ s/-/ /g;
				$TITLE =~ s/.data//;
				$TITLE=~ s/([\w']+)/\u\L$1/g;
				$TITLE=~ s/Top 20 Admin Passwords/Top 20 Username \"admin\" Passwords/;

				if ( -s "$FILE" ) {
#					# Hack to make sure we use the real "top 20 non root accounts"
					if ( "$FILE" eq "current-top-20-non-root-accounts.data" ) {
						$FILE="current-top-20-non-root-accounts-real.data";
					}
					if ( "$FILE" eq "last-7-days-top-20-non-root-accounts.data" ) {
						$FILE="last-7-days-top-20-non-root-accounts-real.data";
					}
					if ( "$FILE" eq "last-30-days-top-20-non-root-accounts.data" ) {
						$FILE="last-30-days-top-20-non-root-accounts-real.data";
					}
					if ( "$FILE" eq "historical-top-20-non-root-accounts.data" ) {
						$FILE="historical-top-20-non-root-accounts-real.data";
					}
print "FILE is $FILE, TITLE is $TITLE, GRAPHIC_FILE is $GRAPHIC_FILE\n\n";
					if ( $FILE =~ "accounts" ) {
print "accounts\n";
						`php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE`;
						`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP`;
					}
					if ( $FILE =~ "password" ) {
print "password\n";
						`php /usr/local/etc/LongTail_make_graph.php $FILE "$TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE`;
						`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP`;
					}
					if ( $FILE =~ "last-30-days-username-count.data" ) {
print "\n\n30 days username\n";
						`php /usr/local/etc/LongTail_make_graph.php $FILE "Last 30 Days Count of Unique Usernames" "" "" "wide"> $GRAPHIC_FILE`;
						`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP`;
					}
					if ( $FILE =~ "last-30-days-password-count.data" ) {
print "\n\n30 days passwords\n";
						`php /usr/local/etc/LongTail_make_graph.php $FILE "Last 30 Days Count of Unique Passwords" "" "" "wide"> $GRAPHIC_FILE`;
						`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP`;
					}
					if ( $FILE =~ "last-30-days-ips-count.data" ) {
#print "\n\n30 days ip\n";
#print "FILE is $FILE\n";
#$tmp=`ls -l $FILE`;
#print "$tmp\n";
#$tmp=`pwd`;
#print "$tmp\n";
						`php /usr/local/etc/LongTail_make_graph.php $FILE "Last 30 Days Count of Unique IP addresses" "" "" "wide"> $GRAPHIC_FILE`;
						`$SCRIPT_DIR/LongTail_make_top_20_imagemap.pl  $FILE  >$MAP`;
#exit;
					}
					if ( $FILE =~ "last-30-days-attack-count.data" ) {
#print "\n\n30 days attack count\n";
						# This works but I want to show sshPsycho data now
						if ( "x$HOSTNAME" eq "x/" ) {
							`php /usr/local/etc/LongTail_make_graph_sshpsycho.php $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data  $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data "Last 30 Days Attacks (Red=sshPsycho-2, Yellow=Friends of sshPsycho, Green=Associates of sshPsycho, Blue=others)" "" "" "wide" > $GRAPHIC_FILE`;
						} else {
							`php /usr/local/etc/LongTail_make_graph_sshpsycho.php $HTML_DIR/last-30-days-attack-count.data $HTML_DIR/last-30-days-sshpsycho-2-attack-count.data $HTML_DIR/last-30-days-friends-of-sshpsycho-attack-count.data  $HTML_DIR/last-30-days-associates-of-sshpsycho-attack-count.data "Last 30 Days Attacks (Red=sshPsycho-2, Yellow=Friends of sshPsycho, Blue=others)" "" "" "wide" > $GRAPHIC_FILE`;
						}

					}
				} else { #We have an empty file, deal with it here
					open (TMPFILE, ">$TMP_DIRECTORY/LongTail.data.$$");
					print (TMPFILE "0 0\n");
					close (TMPFILE);

					open (TMPFILE, ">$file.map");
					close (TMPFILE);
					if ( $FILE =~ "accounts" ) {
						`php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Accounts" "Number of Tries" "standard"> $GRAPHIC_FILE`;
						open (TMPFILE, ">$MAP");
						close (TMPFILE);
					}
					if ( $FILE =~ "password" ) {
						`php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today For $TITLE" "Passwords" "Number of Tries" "standard"> $GRAPHIC_FILE`;
						open (TMPFILE, ">$MAP");
						close (TMPFILE);
					}
					if ( $FILE =~ "last-30-days-username-count.data") {
						`php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today for Unique Usernames" "" "" "wide"> $GRAPHIC_FILE`;
						open (TMPFILE, ">$MAP");
						close (TMPFILE);
					}
					if ( $FILE =~ "last-30-days-password-count.data") {
						`php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today for Unique Passwords" "" "" "wide"> $GRAPHIC_FILE`;
						open (TMPFILE, ">$MAP");
						close (TMPFILE);
					}
					if ( $FILE =~ "last-30-days-ips-count.data") {
						`php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "Not Enough Data Today for Unique IP addresses" "" "" "wide"> $GRAPHIC_FILE`;
						open (TMPFILE, ">$MAP");
						close (TMPFILE);
					}
					if ( $FILE =~ "last-30-days-attack-count.data" ) {
						`php /usr/local/etc/LongTail_make_graph.php $TMP_DIRECTORY/LongTail.data.$$ "$TITLE" "" "" "wide"> $GRAPHIC_FILE`;
						open (TMPFILE, ">$MAP");
						close (TMPFILE);
					}
					unlink ("$TMP_DIRECTORY/LongTail.data.$$");
				}
			}
		}        
	} # end of if ( $START_HOUR == $MIDNIGHT ) 
	if ( $DEBUG  == 1 ) { print "DEBUG-Done Making Graphics now\n" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	} # end of if ( $GRAPHS == 1 )     
} # End of do_ssh

sub make_daily_attacks_chart {
	$DEBUG_DATE=`date`;
	if ( $DEBUG  == 1 ) { print "DEBUG-make_daily_attacks_chart: $DEBUG_DATE"  }
	chdir ("$HTML_DIR/historical");
	&make_header ("$HTML_DIR/attacks_by_day.shtml", "Attacks By Day",  "" );
	`$SCRIPT_DIR/LongTail_make_daily_attacks_chart.pl "$HTML_DIR/historical" >> $HTML_DIR/attacks_by_day.shtml `;
	&make_footer ("$HTML_DIR/attacks_by_day.shtml");
	$DEBUG_DATE=`date`;
	if ( $DEBUG  == 1 ) { print "DEBUG-Done make_daily_attacks_chart: $DEBUG_DATE" }
}

############################################################################
# Set permissions so everybody can read the files
#
sub set_permissions {
	$TMP_HTML_DIR=shift;
	`chmod a+r $TMP_HTML_DIR/*`;
}

############################################################################
#
# Protect raw data for $NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA
#
sub protect_raw_data {
	my $TMP_HTML_DIR=shift;
	my $count;
	&is_directory_good ($TMP_HTML_DIR);
	if ( $START_HOUR ==  $MIDNIGHT ) {
		if ( $PROTECT_RAW_DATA == 1 ) {
			chdir ("$TMP_HTML_DIR");

			$count=`find . -name current-raw-data.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -print -quit | wc -l`;
			chomp $count;
			if ( $count > 0 ) {
				`find . -name current-raw-data.gz -mtime -$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA |xargs chmod go-r`;
			}

			$count=`find . -name current-raw-data.gz -mtime +$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA -print -quit | wc -l`;
			chomp $count;
			if ( $count > 0 ) {
				`find . -name current-raw-data.gz -mtime +$NUMBER_OF_DAYS_TO_PROTECT_RAW_DATA |xargs chmod go+r`;
			}
		}
	}
}

############################################################################
# Create historical copies of the data
#
# This creates yesterdays data, once "yesterday" is over
#
sub create_historical_copies {
	$TMP_HTML_DIR=shift;
	$REBUILD=1;
	if ( $DEBUG  == 1 ) { print "DEBUG-In create_historical_copies:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }

	if ( $START_HOUR == $MIDNIGHT ) {
		if ( $DEBUG  == 1 ) { print "DEBUG-Actually running create_historical_copies $START_HOUR == $MIDNIGHT\n" ; }
		$YESTERDAY_YEAR=`date  +"%Y" --date="1 day ago"`;
		$YESTERDAY_MONTH=`date  +"%m" --date="1 day ago"`;
		$YESTERDAY_DAY=`date  +"%d" --date="1 day ago"`;
		chomp $YESTERDAY_YEAR;
		chomp $YESTERDAY_MONTH;
		chomp $YESTERDAY_DAY;

		chdir ("$TMP_HTML_DIR");

		`mkdir -p $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY`;
#NOTYETCONVERTED		for dir in $HOSTS_PROTECTED $BLACKRIDGE ; do
#NOTYETCONVERTED			if ( "x$HOSTNAME" eq "x$dir" ) {
#NOTYETCONVERTED				&touch $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/current-attack-count.data.notfullday
#NOTYETCONVERTED				print $TMP_HTML_DIR/historical/$TMP_YEAR/$TMP_MONTH/$TMP_DAY/
#NOTYETCONVERTED			}
#NOTYETCONVERTED		done
		if ( -e "$TMP_HTML_DIR/index-historical.shtml" ) {
			`cp $TMP_HTML_DIR/index-historical.shtml $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/index.shtml`;
		} else {
			if ( -e "$HTML_DIR/index-historical.shtml" ) {
				`cp $HTML_DIR/index-historical.shtml $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/index.shtml`;
			} else { 
				print "WARNING! CAN NOT FIND $TMP_HTML_DIR/index-historical.shtml OR $HTML_DIR/index-historical.shtml\n";
				print "This is not a deal breaker but your historical directories\n";
				print "will not have an index.shtml file\n";
			}
		}
		# I do individual chmods so I don't do chmod's of thousands of files...
		`chmod a+rx $TMP_HTML_DIR/historical`;
		`chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR`;
		`chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH`;
		`chmod a+rx $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY`;
		`chmod a+r  $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/*`;
		`echo "$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY" > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/date.html`;

		if ( $LONGTAIL == 1 ) {
			`grep ssh $PATH_TO_VAR_LOG/$LOGFILE* | grep $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages`;
		}
		if ( $KIPPO == 1 ) {
			`grep ssh $PATH_TO_VAR_LOG/$LOGFILE* | grep $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY > $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages`;
		}

		&touch ("$TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz");
		unlink ("$TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz");
		`gzip $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages`;
		`chmod 0000 $TMP_HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/all_messages.gz`;


#print "\n\n\nDEBUG Making yesterday's reports\n";
#print "output dir is $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY, year is $YESTERDAY_YEAR path to var log is  $PATH_TO_VAR_LOG,  date is $YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY, logfile is $LOGFILE*, prefix is current\n";
		&ssh_attacks ("$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY", "$YESTERDAY_YEAR", "$PATH_TO_VAR_LOG", "$YESTERDAY_YEAR-$YESTERDAY_MONTH-$YESTERDAY_DAY", "$LOGFILE*", "current");

		#
		# Make IPs table and count for this day
		#todays_ips.count
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed "s\/^..*IP: /\/\" |sed "s/\ .*\$/\/\"|sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips `;
		`cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips.count`;

		# Make todays_password.count
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's/\^.\*Password:/\/\'|sed 's/\^ /\/\'| sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password `;
	`cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password.count`;
		# Make todays_username.count
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP:|sed 's/\^.\*Username: /\/\' |sed 's/\ Password..\*\$/\/\'|uniq |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username`;
		`cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username.count`;

		# Make current-sshpsycho-attack-count.data
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-attack-count.data`;

		# Make current-sshpsycho-2-attack-count.data
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-2-attack-count.data`;

		# Make current-friends_of_sshpsycho-attack-count.data
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-friends_of_sshpsycho-attack-count.data`;

		# Make current-associates_of_sshpsycho-attack-count.data
		`zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-associates_of_sshpsycho-attack-count.data`;

    #
    # Make IPs table and count for this day
    #todays_ips.count
    `zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's\/^..*IP: \/\/' |sed 's\/ .*$\/\/'|sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips`;
    `cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips.count`;

    # Make todays_password.count
    `zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |sed 's\/^.*Password:\/\/'|sed 's\/^ \/\/'| sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//todays_password`;
  `cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//todays_password.count`;

    # Make todays_username.count
    `zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//current-raw-data.gz |grep IP:|sed 's\/^.*Username: \/\/' |sed 's\/ Password..*$\/\/'|uniq |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username`;
    `cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY//todays_username | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username.count`;
# NEW STUFF May 27th...
#
# Lets hope this is run before all-ips, all-password, and all-username are run
	`awk 'FNR==NR{a[\$0]++;next}(!(\$0 in a))' $HTML_DIR/all-ips       $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_ips >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt`;


	`awk 'FNR==NR{a[\$0]++;next}(!(\$0 in a))' $HTML_DIR/all-password $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_password >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-passwords.txt`;

	`awk 'FNR==NR{a[\$0]++;next}(!(\$0 in a))'  $HTML_DIR/all-username $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays_username >$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-usernames.txt`;

		`cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-passwords.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-passwords.txt.count`;
		`cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-usernames.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-usernames.txt.count`;
		`cat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/todays-uniq-ips.txt.count`;


	}
	if ( $DEBUG  == 1 ) { print "DEBUG-DONE with create_historical_copies\n" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
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

sub rebuild { 
	if ( $DEBUG  == 1 ) { print "DEBUG-In Rebuild now\n" ; }
	$REBUILD=1;
  chdir ("$HTML_DIR/historical/");
# ssh_attacks $HTML_DIR/historical/2015/02/24 $YEAR $PATH_TO_VAR_LOG "2015-02-24"      "$LOGFILE*" "current"
#	ssh_attacks $HTML_DIR/historical/2015/03/14 $YEAR $PATH_TO_VAR_LOG "2015-03-14"      "$LOGFILE*" "current"
# ssh_attacks /var/www/html/honey///historical/2015/01/04 2015 /var/www/html/honey///historical/2015/01/04 2015-01-04 current-raw-data.gz current

	#
	# Make blank files so we can determine on a daily basis
	# Which IPs, usernames, passwords are NEW for that day
	#	
	&touch ("/tmp/LongTail.$$.ips");
	&touch ("/tmp/LongTail.$$.passwords");
	&touch ("/tmp/LongTail.$$.usernames");
	unlink ("/tmp/LongTail.$$.ips");
	unlink ("/tmp/LongTail.$$.passwords");
	unlink ("/tmp/LongTail.$$.usernames");

	open (FILE, ">/tmp/LongTail.$$.ips");
	print (FILE "THISisAbogusFILLERline\n");
	close (FILE);
	open (FILE, ">/tmp/LongTail.$$.passwords");
	print (FILE "THISisAbogusFILLERline\n");
	close (FILE);
	open (FILE, ">/tmp/LongTail.$$.usernames");
	print (FILE "THISisAbogusFILLERline\n");
	close (FILE);

	open (FIND, "find \"*/*/*/current-raw-data.gz\"|");
	while (<FIND>){
		chomp $_;
		$FILE=$_;
		print "$FILE\n";
		$DIRNAME=`dirname $FILE`;
		print "DIRNAME is $DIRNAME\n";
		$YEAR=`dirname $DIRNAME`;
		chomp $YEAR;
		$YEAR=`dirname $YEAR`;
		chomp $YEAR;
		# WAS In the original LongTail.sh --> $DATE=`echo $DIRNAME |sed 's/\//-/g';`
		$DATE =~ s/\//-/g ;
		print "DATE is $DATE\n";
		print "YEAR IS $YEAR\n";

		print "ssh_attacks $HTML_DIR/historical/$DIRNAME $YEAR $HTML_DIR/historical/$DIRNAME $DATE      current-raw-data.gz current \n";

		&ssh_attacks ("$HTML_DIR/historical/$DIRNAME", "$YEAR $HTML_DIR/historical/$DIRNAME", "$DATE", "current-raw-data.gz", "current");

		# Make current-sshpsycho-attack-count.data
		`zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l > $HTML_DIR/historical/$DIRNAME/current-sshpsycho-attack-count.data`;

		# Make current-sshpsycho-2-attack-count.data
		`zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l > $HTML_DIR/historical/$DIRNAME/current-sshpsycho-2-attack-count.data`;

		# Make current-friends_of_sshpsycho-attack-count.data
		`zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$DIRNAME/current-friends_of_sshpsycho-attack-count.data`;

		# Make current-associates_of_sshpsycho-attack-count.data
		`zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$DIRNAME/current-associates_of_sshpsycho-attack-count.data`;

		#
		# Make IPs table and count for this day
		#todays_ips.count
		`zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |sed 's\/^..*IP: \/\/' |sed 's\/ .*$\/\/'|sort -T $TMP_DIRECTORY -u  > $HTML_DIR/historical/$DIRNAME/todays_ips `;
		`cat $HTML_DIR/historical/$DIRNAME/todays_ips |wc -l > $HTML_DIR/historical/$DIRNAME//todays_ips.count`;

		# Make todays_password.count
		`zcat $HTML_DIR/historical/$DIRNAME/current-raw-data.gz |grep IP: |sed 's\/^.*Password:\/\/'|sed 's\/^ \/\/'| sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$DIRNAME//todays_password `;
	`cat $HTML_DIR/historical/$DIRNAME/todays_password | wc -l > $HTML_DIR/historical/$DIRNAME//todays_password.count`;

		# Make todays_username.count
		`zcat $HTML_DIR/historical/$DIRNAME//current-raw-data.gz |grep IP:|sed 's\/^.*Username: \/\/' |sed 's\/ Password..*$\/\/'|uniq |sort -T $TMP_DIRECTORY -u > $HTML_DIR/historical/$DIRNAME/todays_username`;
		`cat $HTML_DIR/historical/$DIRNAME//todays_username | wc -l > $HTML_DIR/historical/$DIRNAME//todays_username.count`;


#NOTYETCONVERTED		`awk 'FNR==NR{a[$0]++;next}(!($0 in a))' /tmp/LongTail.$$.ips       $HTML_DIR/historical/$DIRNAME/todays_ips >$HTML_DIR/historical/$DIRNAME/todays-uniq-ips.txt`;

#NOTYETCONVERTED		`awk 'FNR==NR{a[$0]++;next}(!($0 in a))' /tmp/LongTail.$$.passwords $HTML_DIR/historical/$DIRNAME/todays_password >$HTML_DIR/historical/$DIRNAME/todays-uniq-passwords.txt`;

#		print "looking at $HTML_DIR/historical/$DIRNAME/todays_username\n";
#		`ls -l $HTML_DIR/historical/$DIRNAME/todays_username`;
#		`wc -l $HTML_DIR/historical/$DIRNAME/todays_username`;

#NOTYETCONVERTED		`awk 'FNR==NR{a[$0]++;next}(!($0 in a))' /tmp/LongTail.$$.usernames $HTML_DIR/historical/$DIRNAME/todays_username >$HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt`;

#		`ls -l $HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt`;

		`cat $HTML_DIR/historical/$DIRNAME/todays_password > /tmp/LongTail.$$.passwords`;
		`sort -T $TMP_DIRECTORY -u /tmp/LongTail.$$.passwords > /tmp/LongTail.$$.passwords.tmp`;
		`mv /tmp/LongTail.$$.passwords.tmp /tmp/LongTail.$$.passwords`;

		`cat $HTML_DIR/historical/$DIRNAME/todays_ips > /tmp/LongTail.$$.ips`;
		`sort -T $TMP_DIRECTORY -u /tmp/LongTail.$$.ips > /tmp/LongTail.$$.ips.tmp`;
		`mv /tmp/LongTail.$$.ips.tmp /tmp/LongTail.$$.ips`;

		`cat $HTML_DIR/historical/$DIRNAME/todays_username > /tmp/LongTail.$$.usernames`;
		`sort -T $TMP_DIRECTORY -u /tmp/LongTail.$$.usernames > /tmp/LongTail.$$.usernames.tmp`;
		`mv /tmp/LongTail.$$.usernames.tmp /tmp/LongTail.$$.usernames`;

		`cat $HTML_DIR/historical/$DIRNAME/todays-uniq-passwords.txt |wc -l > $HTML_DIR/historical/$DIRNAME/todays-uniq-passwords.txt.count`;
		`cat $HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt |wc -l > $HTML_DIR/historical/$DIRNAME/todays-uniq-usernames.txt.count`;
		`cat $HTML_DIR/historical/$DIRNAME/todays-uniq-ips.txt |wc -l > $HTML_DIR/historical/$DIRNAME/todays-uniq-ips.txt.count`;
	
	}
}

############################################################################
# This creates a file current-attack-count.data.notfullday in all the
# hosts historical directories that shows the host is protected by
# a firewall 
#
sub set_hosts_protected_flag {
	if ( "x$HOSTNAME" eq "x/" ) {
	foreach (split (/ /,"$HOSTS_PROTECTED $BLACKRIDGE") ){
		print "Host is $_\n";
		$host=$_;
		chdir ("/var/www/html/honey/$host/historical")||die "Can not chdir to /var/www/html/honey/$host/historical\n";
		open (FIND, "find */*/* -type d|");
		while (<FIND>){
			chomp;
			&touch ("$_/current-attack-count.data.notfullday");
		}
		close (FIND);
	}
	}
}

sub recount_last_30_days_sshpsycho_attacks {

	my $days_ago=0;
	if ( $DEBUG  == 1 ) { print  "DEBUG-In recount_last_30_days_sshpsycho_attacks" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
	while ( $days_ago < 31){
		$days_ago++;
		$YESTERDAY_YEAR=`date "+%Y" --date="$days_ago day ago"`;
		chomp $YESTERDAY_YEAR;
		$YESTERDAY_MONTH=`date "+%m" --date="$days_ago day ago"`;
		chomp $YESTERDAY_MONTH;
		$YESTERDAY_DAY=`date "+%d" --date="$days_ago day ago"`;
		chomp $YESTERDAY_DAY;

		# Make current-sshpsycho-attack-count.data
		if ( -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ) {
			system ("zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-attack-count.data");
		}

		# Make current-sshpsycho-2-attack-count.data
		if ( -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ) {
			system ("zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses |wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-sshpsycho-2-attack-count.data");
		}


		# Make current-friends_of_sshpsycho-attack-count.data
		if ( -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ) { 
		system ("zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-friends_of_sshpsycho-attack-count.data");
		}

		# Make current-associates_of_sshpsycho-attack-count.data
		if ( -e "$HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz" ) { 
		system ("zcat $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-raw-data.gz |grep IP: |grep -F -f $SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses | wc -l > $HTML_DIR/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-associates_of_sshpsycho-attack-count.data");
		}

	}
}


###########################################################################
sub really_count_sshpsycho_attacks {	
	print "DEBUG in really_count_sshpsycho_attacks\n";
	my $TMP_DATE=`date +"%Y-%m-%d"`;
	chomp ($TMP_DATE);
	my $TMP_YEAR=`date +%Y`;
	chomp $TMP_YEAR;
	my $TMP_MONTH=`date +%m`;
	chomp $TMP_MONTH;
	my $TMP_DAY=`date +%d`;
	chomp $TMP_DAY;

	my $name=shift; # "SSHPsycho"
	my $ip_file=shift; # $SCRIPT_DIR/LongTail_sshPsycho_IP_addresses"
	my $count_data_filename=shift; #"current-sshpsycho-attack-count.data"

	if ( "x$HOSTNAME" eq "x/" ) {
		$TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep "$TMP_DATE" |grep IP:  | grep -F -f $ip_file |wc -l`;
	}
	else {
		$TODAY=`zcat $HTML_DIR/current-raw-data.gz |grep $PROTOCOL |grep $HOSTNAME |grep "$TMP_DATE" |grep IP:  | grep -F -f $ip_file |wc -l`
	}
	chomp $TODAY;

	# This month
	$TMP=0;
	open (FIND,  "find \"$TMP_YEAR/$TMP_MONTH\" -name $count_data_filename |");
	while (<FIND>){
		open (FILE, $_);
		while (<FILE>){
			$TMP+=$_;
		}
		close (FILE);
	}
	$THIS_MONTH=`expr $TMP + $TODAY`;

	# This year
	$TMP=0;
	open (FIND,  "find $TMP_YEAR -name $count_data_filename |");
	while (<FIND>){
		open (FILE, $_);
		while (<FILE>){
			$TMP+=$_;
		}
		close (FILE);
	}
	$THIS_YEAR=`expr $TMP + $TODAY`;

	# Since logging started 
	$TMP=0;
	open (FIND,  "find $TMP_YEAR -name $count_data_filename |");
	while (<FIND>){
		open (FILE, $_);
		while (<FILE>){
			$TMP+=$_;
		}
		close (FILE);
	}
	$TOTAL=`expr $TMP + $TODAY`;
	
	$TODAY=&commify( $TODAY);
	$THIS_MONTH=&commify( $THIS_MONTH );
	$THIS_YEAR=&commify( $THIS_YEAR );
	$TOTAL=&commify( $TOTAL );
	#print "TODAY is $TODAY, THIS_MONTH is $THIS_MONTH, this year is $THIS_YEAR";
	`sed -i "s\/$name Today.*\$\/$name Today:--> $TODAY\/" $HTML_DIR/index.shtml`;
	`sed -i "s\/$name This Month.*\$\/$name This Month:--> $THIS_MONTH\/" $HTML_DIR/index.shtml`;
	`sed -i "s\/$name This Year.*\$\/$name This Year:--> $THIS_YEAR\/" $HTML_DIR/index.shtml`;
	`sed -i "s\/$name Since Logging Started.*\$\/$name Since Logging Started:--> $TOTAL\/" $HTML_DIR/index.shtml`;
	`sed -i "s\/$name Today.*\$\/$name Today:--> $TODAY\/" $HTML_DIR/index-long.shtml`;
	`sed -i "s\/$name This Month.*\$\/$name This Month:--> $THIS_MONTH\/" $HTML_DIR/index-long.shtml`;
	`sed -i "s\/$name This Year.*\$\/$name This Year:--> $THIS_YEAR\/" $HTML_DIR/index-long.shtml`;
	`sed -i "s\/$name Since Logging Started.*\$\/$name Since Logging Started:--> $TOTAL\/" $HTML_DIR/index-long.shtml`;
}

###########################################################################
#
# Lets count all the sshpsycho (and friends, etc) attacks
#

sub count_sshpsycho_attacks {

	print "DEBUG in count_sshpsycho_attacks\n";
	chdir ("$HTML_DIR/historical");
	my $TMP_DATE=`date +"%Y-%m-%d"`;
	chomp ($TMP_DATE);

#	print "DEBUG-Counting sshpsycho attacks now\n";
	&really_count_sshpsycho_attacks ("SSHPsycho", "$SCRIPT_DIR/LongTail_sshPsycho_IP_addresses", "current-sshpsycho-attack-count.data");

#	print "DEBUG-Counting sshpsycho-2 attacks now\n";
	&really_count_sshpsycho_attacks ("SSHPsycho-2", "$SCRIPT_DIR/LongTail_sshPsycho_2_IP_addresses", "current-sshpsycho-2-attack-count.data");

#	print "DEBUG-Counting sshpsycho friends attacks now\n"; date;
	&really_count_sshpsycho_attacks ("SSHfriendsPsycho", "$SCRIPT_DIR/LongTail_friends_of_sshPsycho_IP_addresses", "current-friends_of_sshpsycho-attack-count.data");

#	print "DEBUG-Counting sshpsycho associates attacks now\n";
	&really_count_sshpsycho_attacks ("SSHassociatesPsycho", "$SCRIPT_DIR/LongTail_associates_of_sshPsycho_IP_addresses", "current-associates_of_sshpsycho-attack-count.data");

}

############################################################################
# Main 
#
my $CONFIG_FILE="/usr/local/etc/LongTail.config";

$DEBUG_DATE=`date`;
print "Started LongTail.pl at: $DEBUG_DATE";

&init_variables;
&load_exclude_files;
$DEBUG=1;
#print "DEBUG DANGER MIDNIGHT IS SET TO 6\n";
$MIDNIGHT=0;

$SEARCH_FOR="sshd";
#
# My processing of arguments sucks and needs to be fixed

if ( @ARGV == 0 ){
	print "No parameters passed, assuming search for all ssh tries on all hosts\n";
	$SEARCH_FOR="sshd";
	$HTML_DIR="$HTML_DIR/$SSH_HTML_TOP_DIR";
	$HTML_TOP_DIR=$SSH_HTML_TOP_DIR;
}
else{
	while ( @ARGV > 0 ) {
		if (( $ARGV[0] eq "-h" ) || ( $ARGV[0] eq "-help" )) {
			print "\n";
			print "\n";
			print "Help screen\n";
			print "$0 -host <hostname> -midnight -debug -rebuild -protocol <protocol_to_search_for> -f <configuration_file>\n";
			print "Supported protocols are:\n";
			print "   ssh (All ports for ssh)\n";
			print "   22 (ssh only on port 22)\n";
			print "   2222 (ssh only on port 2222)\n";
			print "   http (apache honeypot)\n";
			print "   telnet (telnet on port 23)\n";
			print "-midnight runs and acts like it is now midnight and will create all of \n";
			print "   yesterdays files\n";
			print "-debug turns on extra debugging output\n";
			print "-rebuild Possibly dangerous, please create a backup of your entire \n";
			print "   /var/www/html/ directory first!\n";
			print "   rebuild recreates all files in the ssh (ONLY) historical directories.  \n";
			print "   This is mainly a development option.\n";
			print "-host <hostname> creates reports only for <hostname>.\n";
			print "   There must already be a /var/www/html/<protocol>/<hostname> directory\n";
			print "-f <configuration_file> Use <configuration_file> instead of \n";
			print "   /usr/local/etc/LongTail.config\n";
			print "\n";
			print "\n";
			exit;
		}
		if ( $ARGV[0] eq "-f" ) {
			shift;
			$CONFIG_FILE=$ARGV[0];
			if ( -e "$CONFIG_FILE" ) {
			}
			else  {
				print "Configuration file you specified does not exist, exiting now\n";
				exit;
			}
			shift;
			next;
		}
		if ( $ARGV[0] eq "-host" ) {
			shift;
			#print "Setting hostname to $ARGV[0]\n";
			$HOSTNAME=$ARGV[0];
			shift;
			next;
		}
		if ( $ARGV[0] eq "-midnight" ) {
			shift;
			$MIDNIGHT=$START_HOUR;
			next;
		}
		if ( $ARGV[0] eq "-debug" ) {
			shift;
			$DEBUG=1;
			next;
		}
		if ( $ARGV[0] eq "-rebuild" ) {
			shift;
			$REBUILD=1;
			next;
		}
		if ( $ARGV[0] eq "-protocol" ) {
			shift;
			if ( $ARGV[0] eq "ssh" ) {
				$SEARCH_FOR="sshd";
				$HTML_DIR="$HTML_DIR/$SSH_HTML_TOP_DIR";
				$HTML_TOP_DIR=$SSH_HTML_TOP_DIR;
				shift;
				next;
			}
			if ( $ARGV[0] eq "22" ) {;
				$SEARCH_FOR="sshd-22";
				$HTML_DIR="$HTML_DIR/$SSH22_HTML_TOP_DIR";
				$HTML_TOP_DIR=$SSH22_HTML_TOP_DIR;
				shift;
				next;
			}
			if ( $ARGV[0] eq "2222" ) {
				$SEARCH_FOR="sshd-2222";
				$HTML_DIR="$HTML_DIR/$SSH2222_HTML_TOP_DIR";
				$HTML_TOP_DIR=$SSH2222_HTML_TOP_DIR;
				shift;
				next;
			}
			if ( $ARGV[0] eq "telnet" ) {
				$SEARCH_FOR="telnet-honeypot";
				$HTML_DIR="$HTML_DIR/$TELNET_HTML_TOP_DIR";
				$HTML_TOP_DIR=$TELNET_HTML_TOP_DIR;
				shift;
				next;
			}
			if ( $ARGV[0] eq "http" ) {
				$SEARCH_FOR="http";
				$HTML_DIR="$HTML_DIR/$HTTP_HTML_TOP_DIR";
				$HTML_TOP_DIR=$HTTP_HTML_TOP_DIR;
				shift;
				next;
			}

			print "Option $ARGV[0] for protocol not found, exiting now\n";
			exit;;
		} # end of if -protocol
		if ( $ARGV[0] =~ /^-/){
			print "BAD option -->$ARGV[0]<--, exiting now\n";
			exit;
		}
		# Falls through to here, it must be a hostname
		#print "Fell through, setting hostname to $ARGV[0]\n";
		$HOSTNAME=$ARGV[0];
		$SEARCH_FOR="sshd";
		$HTML_DIR="$HTML_DIR/$SSH_HTML_TOP_DIR";
		$HTML_TOP_DIR=$SSH_HTML_TOP_DIR;
		shift;
	} #end of while
	if ( "x$HOSTNAME" ne "x" ){
		print "hostname set to $HOSTNAME\n";
	} else {
		# I'm relying on "//" being the same as "/"
		# in unix :-)
		$HOSTNAME="/";
	}
}
&read_local_config_file;
&check_config;
if ( "x$SEARCH_FOR" eq "x" ){
	print "You did not specify a protocol to search for, exiting now\n";
	exit;
}

print "opts are hostname=$HOSTNAME, midnight=$MIDNIGHT, search for=$SEARCH_FOR, debug=$DEBUG\n";
print "HTML_DIR =$HTML_DIR HTML_TOP_DIR=$HTML_TOP_DIR\n";


print "HTML_DIR/HOSTNAME is set to $HTML_DIR/$HOSTNAME\n";

if ( ! -d "$HTML_DIR/$HOSTNAME" ) {
	print "Can not find $HTML_DIR/$HOSTNAME making it  now\n";
	`mkdir $HTML_DIR/$HOSTNAME`;
	`chmod a+rx $HTML_DIR/$HOSTNAME`;
	`cp $HTML_DIR/index.shtml $HTML_DIR/$HOSTNAME`;
	`chmod a+r $HTML_DIR/$HOSTNAME/index.shtml`;
	`cp $HTML_DIR/index-long.shtml $HTML_DIR/$HOSTNAME`;
	`chmod a+r $HTML_DIR/$HOSTNAME/index-long.shtml`;
	`cp $HTML_DIR/graphics.shtml $HTML_DIR/$HOSTNAME`;
	`chmod a+r $HTML_DIR/$HOSTNAME/graphics.shtml`;
}

$HTML_DIR="$HTML_DIR/$HOSTNAME";
print "HTML_DIR is $HTML_DIR\n";


# CREATE A BACKUP OF /var/www/html/honey FIRST, just in case.
# chdir ("/var/www/html/honeyl tar -cf $TMP_DIRECTORY/honey.tar  .
if ( "x$1" eq "xREBUILD" ) {
	print "Running rebuild now\n";
	$PROTOCOL=$SEARCH_FOR;
	#&rebuild;
	print "REBUILD is not functional right now, check github for a more recent version\n";
	exit;
}

&change_date_in_index ("$HTML_DIR", "$YEAR");

$DATE=`date +"%Y-%m-%d"`; # THIS IS TODAY
chomp $DATE;

#
# This sets up a default search in case nothing was passed
#
$PROTOCOL=$SEARCH_FOR;

#This is a manual re-creation of a dated directory
#$PROTOCOL=$SEARCH_FOR;
#ssh_attacks $HTML_DIR/historical/2015/03/29 $YEAR "/var/www/html/honey/syrtest/historical/2015/03/29" "2015-03-29"      "$LOGFILE" "current"


# Recounting needs to be done here so that the numbers
# show up in this day's graphs made at midnight
if ( $START_HOUR == $MIDNIGHT ) {
	&recount_last_30_days_sshpsycho_attacks ;
}

# NOTE: I have to make historical copies (if appropriate) BEFORE
# I call do_ssh so that the reports properly create the
# last 30 days of data charts 
print "SEARCH_FOR is $SEARCH_FOR\n";
if ( $SEARCH_FOR eq "sshd" ) {
	print "Searching for ssh attacks\n";
	$PROTOCOL=$SEARCH_FOR;
	&create_historical_copies  ($HTML_DIR);
	&make_trends;
	&do_ssh;
}
if ( $SEARCH_FOR eq "sshd-2222" ) {
	print "Searching for ssh 2222 attacks\n";
	$PROTOCOL=$SEARCH_FOR;
	&create_historical_copies  ($HTML_DIR);
	&make_trends;
	&do_ssh;
}
if ( $SEARCH_FOR eq "telnet-honeypot" ) {
	print "Searching for telnet attacks\n";
	$PROTOCOL=$SEARCH_FOR;
	&create_historical_copies  ($HTML_DIR);
	&make_trends;
	&do_ssh;
}

print "DEBUG- Calling set_permissions\n";
&set_permissions  ($HTML_DIR );
print "DEBUG- Calling protect_raw_data\n";
&protect_raw_data ($HTML_DIR);
print "DEBUG- Calling set_hosts_protected_flag\n";
&set_hosts_protected_flag;

print "DEBUG- Calling make_daily_attacks_chart\n";
&make_daily_attacks_chart;

if ( "x$HOSTNAME" eq "x/" ) {
	if ( $SEARCH_FOR eq "sshd" ) {
		print "Doing blacklist efficiency tests now\n";
		&make_header ("$HTML_DIR/blacklist_efficiency.shtml", "Blacklist Efficiency",  "" );

print "DEBUG blacklist_efficiency disabled for testing, turn this on again later\n";
		#`/usr/local/etc/LongTail_compare_IP_addresses.pl >> $HTML_DIR/blacklist_efficiency.shtml`;
		&make_footer ("$HTML_DIR/blacklist_efficiency.shtml");
	
		&make_header ("$HTML_DIR/password_analysis_todays_passwords.shtml", "Password Analysis of Today's Passwords",  "" );
		`$SCRIPT_DIR/LongTail_password_analysis_part_1.pl $HTML_DIR/todays_passwords >> $HTML_DIR/password_analysis_todays_passwords.shtml`;
		&make_footer ("$HTML_DIR/password_analysis_todays_passwords.shtml");
	
		if ( $START_HOUR == $MIDNIGHT ) {
			`/usr/local/etc/LongTail_make_30_days_imagemap.pl >$HTML_DIR/30_days_imagemap.html`;
		}

		if ( $START_HOUR == $MIDNIGHT ) {
			
			if ( $DEBUG  == 1 ) { print "DEBUG-Finding 2000 longest passwords now:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			`awk '{print length, \$0}' $HTML_DIR/all-password | sort -n | cut -d " " -f2- |tail -2000 >$HTML_DIR/2000-longest-passwords.txt`;

			if ( $DEBUG  == 1 ) { print "DEBUG-Password Analysis of All Passwords now\n" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			&make_header ( "$HTML_DIR/password_analysis_all_passwords.shtml", "Password Analysis of All Passwords" , "" );
			`$SCRIPT_DIR/LongTail_password_analysis_part_1.pl $HTML_DIR/all-password >> $HTML_DIR/password_analysis_all_passwords.shtml`;
			&make_footer  ("$HTML_DIR/password_analysis_all_passwords.shtml");
	
			&make_header  ("$HTML_DIR/password_list_analysis_all_passwords.shtml", "Password vs Wordlist Analysis",  "" );
	
			open (FILE, ">> $HTML_DIR/password_list_analysis_all_passwords.shtml");
			print (FILE "<P>This is a comparison of passwords used vs several publicly available\n");
			print (FILE "lists of passwords.");
			print (FILE "<BR><BR>");
			close (FILE);
			`$SCRIPT_DIR/LongTail_password_analysis_part_2.pl $HTML_DIR/all-password >> $HTML_DIR/password_list_analysis_all_passwords.shtml`;
			&make_footer  ("$HTML_DIR/password_list_analysis_all_passwords.shtml");

			if ( $DEBUG  == 1 ) { print "DEBUG-First Occurence of an IP Address:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			&make_header  ("$HTML_DIR/first_seen_ips.shtml", "First Occurence of an IP Address",  "" );
			open (FILE, ">>$HTML_DIR/first_seen_ips.shtml");
			print (FILE "</TABLE>\n");
			close (FILE);
			`$SCRIPT_DIR/LongTail_find_first_password_use.pl ips >> $HTML_DIR/first_seen_ips.shtml`;
			&make_footer  ("$HTML_DIR/first_seen_ips.shtml");

			if ( $DEBUG  == 1 ) { print "DEBUG-First Occurence of an username:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			&make_header  ("$HTML_DIR/first_seen_usernames.shtml", "First Occurence of an Username", "" );
			open (FILE, " >> $HTML_DIR/first_seen_usernames.shtml");
			print (FILE "</TABLE>\n");
			close (FILE);
			`$SCRIPT_DIR/LongTail_find_first_password_use.pl usernames >> $HTML_DIR/first_seen_usernames.shtml`;
			&make_footer  ("$HTML_DIR/first_seen_usernames.shtml");

			if ( $DEBUG  == 1 ) { print "DEBUG-First Occurence of an password:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			open (FILE, ">> $HTML_DIR/first_seen_passwords.shtml");
			print (FILE "<PRE>\n");
			close (FILE);
			`$SCRIPT_DIR/LongTail_find_first_password_use.pl passwords >> $HTML_DIR/first_seen_passwords.shtml`;
			open (FILE, ">> $HTML_DIR/first_seen_passwords.shtml");
			print (FILE "<\PRE>\n");
			close (FILE);

			&touch  ("$HTML_DIR/first_seen_passwords.shtml.gz");
			unlink ("$HTML_DIR/first_seen_passwords.shtml.gz");

			`gzip $HTML_DIR/first_seen_passwords.shtml`;
			if ( $DEBUG  == 1 ) { print "DEBUG-Class C Hall Of Shame:" ; $DEBUG_DATE=`date`; print "$DEBUG_DATE"; }
			&make_header  ("$HTML_DIR/class_c_hall_of_shame.shtml", "Class C Hall Of Shame",  "Top 10 worst offending Class C subnets sorted by the number of attack patterns.  Class C subnets must have over 10,000 login attempts to make this list." );
			`$SCRIPT_DIR/LongTail_class_c_hall_of_shame.pl >>/$HTML_DIR/class_c_hall_of_shame.shtml`;
			&make_footer  ("$HTML_DIR/class_c_hall_of_shame.shtml" );

			&make_header  ("$HTML_DIR/class_c_list.shtml", "List of Class C ",  "Class C subnets sorted by the number of attack patterns.");
			`$SCRIPT_DIR/LongTail_class_c_hall_of_shame.pl  "ALL" >>/$HTML_DIR/class_c_list.shtml`;
			&make_footer  ("$HTML_DIR/class_c_list.shtml" );
		}
	}

	if ( $START_HOUR == $MIDNIGHT ) {
		print "Starting midnight LongTail_class_c_hall_of_shame.pl now \n"; 
		&make_header ("$HTML_DIR/class_c_list.shtml", "List of Class C ",  "Class C subnets sorted by the number of attack patterns.");
		`$SCRIPT_DIR/LongTail_class_c_hall_of_shame.pl  "ALL" >>/$HTML_DIR/class_c_list.shtml`;
		&make_footer ("$HTML_DIR/class_c_list.shtml") 
	}
}

if ( "x$HOSTNAME" eq "x/" ) {
	if ( $SEARCH_FOR eq "sshd" ) {
		$DEBUG_DATE=`date`;
		print "Starting sshPsycho analysis now :-) : $DEBUG_DATE" ; 
		if ( $DEBUG  == 1 ) { print "DEBUG-Doing SSHPsycho report now\n" ; }
		if ( ! -e "$HTML_DIR/SSHPsycho.shtml") {print "Warning: $HTML_DIR/SSHPsycho.shtml does not exist, this is ok.\n"; }
		if ( ! -e "$HTML_DIR/attacks/sum2.data") {print "Warning: $HTML_DIR/SSHPsycho.shtml does not exist\nSSHPsycho counting will not be done\n"; }
		if ((stat("$HTML_DIR/SSHPsycho.shtml"))[9] < (stat("$HTML_DIR/attacks/sum2.data"))[9]){
			print "$HTML_DIR/SSHPsycho.shtml is older than $HTML_DIR/attacks/sum2.data, running SSHPsycho.shtml\n";
			&make_header ("$HTML_DIR/SSHPsycho.shtml", "SSHPsycho Attacks\n");
			#/usr/local/etc/LongTail_local_reports/SSHPsycho.pl >> $HTML_DIR/SSHPsycho.shtml
			&make_footer ("$HTML_DIR/SSHPsycho.shtml");
		}
		else {
			print "$HTML_DIR/SSHPsycho.shtml is younger than $HTML_DIR/attacks/sum2.data, not running SSHPsycho.shtml\n"
		}
		$DEBUG_DATE=`date`;
		print "Done with sshPsycho analysis now: $DEBUG_DATE"; 
	}
} 


chdir ("$HTML_DIR/historical");

$DEBUG_DATE=`date`;
print "Calling count_sshpsycho_attacks:$DEBUG_DATE "; 
&count_sshpsycho_attacks;
$DEBUG_DATE=`date`;
print "Back from Calling count_sshpsycho_attacks: $DEBUG_DATE"; 

$DEBUG_DATE=`date`;
print "Calling lock_down_files: $DEBUG_DATE"; 
&lock_down_files ;
$DEBUG_DATE=`date`;
print "Back from lock_down_files: $DEBUG_DATE";

unlink("$TMP_DIRECTORY/LongTail-messages.$$");
$DEBUG_DATE=`date`;
print "Done with LongTail.pl at:$DEBUG_DATE"

