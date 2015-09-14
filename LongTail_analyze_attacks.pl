#!/usr/bin/perl
# /home/urew file
# I need to make sure I am properly handling blank passwords
# and passwords that have spaces properly
#
# I need to make the time comparison a little more fuzzy
# and dynamically compared, instead of just using a set
# number of seconds.
#
# I need to be able to figure out the year of the logfile entry
# instead of assuming 2015.  Not important now, but it will be
# in 2016
#

sub show_help {
print "
Execute this program as LongTail_analyze_attacks_v2.pl all|year|month|day

You MUST include one of the options all, year, month, or day.

\"all\" rebuilds all the attack patterns.
\"year\" rebuilds this year's attack patterns.
\"month\" rebuilds this months's attack patterns.
\"day\" rebuilds today's attack patterns.


";

}

sub init {
	if (($ARGV[0] eq "help" ) || 
		($ARGV[0] eq "-h" ) ||
		($ARGV[0] eq "--help" ) ){
		&show_help;
		exit;
	}
	use Time::Local;
	%mon2num = qw(
  	jan 1  feb 2  mar 3  apr 4  may 5  jun 6
  	jul 7  aug 8  sep 9  oct 10 nov 11 dec 12
	);
	$|=1;
	$GRAPHS=1;
	$DEBUG=1;
	$DO_SSH=1;
	$DO_HTTPD=0;
	$OBFUSCATE_IP_ADDRESSES=0;
	$OBFUSCATE_URLS=0;
	$PASSLOG="PassLog";
	$PASSLOG2222="Pass2222Log";
	$SCRIPT_DIR="/usr/local/etc/";
	$HTML_DIR="/var/www/html/honey/";
	$PATH_TO_VAR_LOG="/var/log/";
	$PATH_TO_VAR_LOG_HTTPD="/var/log/httpd/";
	$TMP_DIRECTORY="/data/tmp";

	if ( -e "/usr/local/etc/LongTail.config"){
		open (FILE, ">$TMP_DIRECTORY/LongTail.$$") || die "Can not open /$TMP_DIRECTORY/LongTail.$$, exiting now\n";
		open (CONFIG, "/usr/local/etc/LongTail.config");
		while (<CONFIG>){
			chomp;
			$_ =~ s/#.*//;
			if (/[A-Z]/){
				$_ =~ s/=/\t=> /;
				print (FILE "$_,\n");
			}
		}
		close (CONFIG);
		close (FILE);

		my %config = do "/$TMP_DIRECTORY/LongTail.$$";
		$GRAPHS=$config{GRAPHS};
		$DEBUG=$config{DEBUG};
		$DO_SSH=$config{DO_SSH};
		$DO_HTTPD=$config{DO_HTTPD};
		$OBFUSCATE_IP_ADDRESSES=$config{OBFUSCATE_IP_ADDRESSES};
		$OBFUSCATE_URLS=$config{OBFUSCATE_URLS};
		$PASSLOG=$config{PASSLOG};
		$PASSLOG2222=$config{PASSLOG2222};
		$SCRIPT_DIR=$config{SCRIPT_DIR};
		$HTML_DIR=$config{HTML_DIR};
		$PATH_TO_VAR_LOG=$config{PATH_TO_VAR_LOG};
		$PATH_TO_VAR_LOG_HTTPD=$config{PATH_TO_VAR_LOG_HTTPD};
		unlink ("/$TMP_DIRECTORY/LongTail.$$");
	}
	$honey_dir=$HTML_DIR;
	$attacks_dir="$HTML_DIR/attacks/";
	$DATE=`date`;
	$DEBUG=1;
	$REBUILD_ALL=0;
	$REBUILD_YEAR=0;
	$REBUILD_MONTH=0;
	$REBUILD_DAY=0;
	if (($ARGV[0] eq "all" ) || ($ARGV[0] eq "rebuild" )){
		$REBUILD_ALL=1;
		if ($DEBUG){print "rebuild all set, this may take some time\n";}
	}
	if (($ARGV[0] eq "year" ) ){
		$REBUILD_YEAR=1;
	}
	if (($ARGV[0] eq "month" ) ){
		$REBUILD_MONTH=1;
	}
	if (($ARGV[0] eq "day" ) ){
		$REBUILD_DAY=1;
	}
	if ( ($REBUILD_ALL==0 ) &&
        ( $REBUILD_YEAR==0 ) &&
        ( $REBUILD_MONTH==0 ) &&
        ( $REBUILD_DAY==0 )){
		print "You forgot an option.\n\n";
		&show_help;
		exit;
	}

}

########################################################################
# Get rid of all the old files
#
sub cleanup_old_files {
	local $TMP;
	$tmp=`date`;

	local $YEAR;
	local $MONTH;
	local $DAY;
	$YEAR=`date +%Y`;
	chomp $YEAR;
	$MONTH=`date +%m`;
	chomp $MONTH;
	$DAY=`date +%d`;
	chomp $DAY;

	if ($DEBUG){print "Deleting old analysis files at $tmp.\n";}
	if (-d "$attacks_dir" ){
		chdir ("$attacks_dir");
		open (PIPE, "find . -type f -o -type l  |") || die "can not open pipe to cleanup files\n";
		while (<PIPE>){
			chomp;
			#if (/dict-/){next;}
			if (/.html/){next;}
			if (/.shtml/){next;}
			if ( $REBUILD_ALL == 1 ){
				unlink ("$_");
			}
			if ( $REBUILD_YEAR == 1 ){
				if (/-$YEAR./){unlink ("$_");}
			}
			if ( $REBUILD_MONTH == 1 ){
				if (/-$YEAR.$MONTH/){unlink ("$_");}
			}
			if ( $REBUILD_DAY == 1 ){
				if (/-$YEAR.$MONTH.$DAY/){unlink ("$_");}
			}
		}
		close (PIPE);
		chdir ("..");
	}
	else {
		print "$attacks_dir does not exist, trying to make it now\n";
		system ("mkdir $attacks_dir");
		if (-d "$attacks_dir" ){
			print "Made $attacks_dir\n";
		}
		else {
			print "Could not make $attacks_dir, exiting now!\n";
			exit 1;
		}
	}
	$tmp=`date`;
	if ($DEBUG){print "Done Deleting old analysis files at $tmp.\n";}
}

########################################################################
# Sort the data by IP, host, and add code to delimit attacks by
# some vague timeframe
#
# DATA line looks like the following:
#Feb 16 10:56:57 shepherd sshd-22[9306]: IP: 103.21.218.221 PassLog: Username: ubnt Password: ubnt
#
sub create_attack_logs {

	local $YEAR;
	local $MONTH;
	$YEAR=`date +%Y`;
	chomp $YEAR;
	$MONTH=`date +%m`;
	chomp $MONTH;

	$attack_filename= "";
	$tmp=`date`;
	if ($DEBUG){print "starting create_attack_logs at $tmp.\n";}
	if ($DEBUG){print "Creating new analysis files(/$TMP_DIRECTORY/tmp.data) .\n";}
	#
	# Ok, find does NOT work in the proper order....  Gotta use the ls command.
	#
	# This is ugly and will break once I get a ton of data
	#
	unlink ("/$TMP_DIRECTORY/tmp.data");
	chdir ("/var/www/html/honey/attacks");
	#
	# Hmmm, do I really need to 
	# include /var/www/html/honey/current-raw-data.gz ?
	#
	chdir ("$honey_dir/historical/");
	if ( $REBUILD_ALL == 1 ){
		print "rebuilding from all data sets\n";
		open (LS, "/bin/ls */*/*/current-raw-data.gz /var/www/html/honey/current-raw-data.gz |") || 
		die "Can not run /bin/ls command on $honey_dir/historical/\n";
	}
	if ( $REBUILD_YEAR == 1 ){
		print "rebuilding from $YEAR sets\n";
		open (LS, "/bin/ls $YEAR/*/*/current-raw-data.gz /var/www/html/honey/current-raw-data.gz |") || 
		die "Can not run /bin/ls command on $honey_dir/historical/\n";
	}
	if ( $REBUILD_MONTH == 1 ){
		print "rebuilding from $YEAR/$MONTH sets\n";
		open (LS, "/bin/ls $YEAR/$MONTH/*/current-raw-data.gz /var/www/html/honey/current-raw-data.gz |") || 
		die "Can not run /bin/ls command on $honey_dir/historical/\n";
	}
	if ( $REBUILD_DAY == 1 ){
		print "rebuilding from $YEAR/$MONTH/$DAY sets\n";
		open (LS, "/bin/ls $YEAR/$MONTH/$DAY/current-raw-data.gz /var/www/html/honey/current-raw-data.gz |") || 
		die "Can not run /bin/ls command on $honey_dir/historical/\n";
	}
	while (<LS>){
		chomp;
		system ("/usr/local/etc/catall.sh $_ >> /$TMP_DIRECTORY/tmp.data");
	}
	close (LS);

	#
	# This is ugly and will break once I get a ton of data
	#
	$tmp=`date`;
	if ($DEBUG){print "DEBUG Done making /$TMP_DIRECTORY/tmp.data at $tmp\n";}
	open (FILE, "/usr/local/etc/catall.sh /$TMP_DIRECTORY/tmp.data |") || 
		die "Can not open /$TMP_DIRECTORY/tmp.data for reading\n";
	while (<FILE>){
		chomp;
		$username="";
		$password="";
		if ((/ IP: /o) && ((/ PassLog: /o)   || (/ Pass2222Log: /o)  ) ){
			($timestamp,$hostname,$process,$IP_FLAG,$ip,$PASSLOG_FLAG,$USERNAME_FLAG,$username,$PASSWORD_FLAG,$password)=split(/ +/,$_);
			($date,$time)=split(/T/,$timestamp);
			($year,$month,$day)=split(/-/,$date);
			($time,$trash)=split(/\./,$time);
			($hour,$minute,$second)=split(/:/,$time);
			if ($second =~ /-/){ ($second,$trash)=split(/-/,$second);}

			if ($month > 11){print "month is > 12 for $_\n";}
			if ($month < 1){print "month is < 1 for $_\n";}
			$epoch=timelocal($second,$minute,$hour,$day,$month-1,$year);
			if (! defined $ip_epoch{$ip}) {
				$ip_earliest_seen_time{$ip}=$epoch;
				$ip_latest_seen_time{$ip}=$epoch;
			} 
			if ($epoch < $ip_earliest_seen_time{$ip}){ $ip_earliest_seen_time{$ip}=$epoch;}
			if ($epoch > $ip_latest_seen_time{$ip}){ $ip_latest_seen_time{$ip}=$epoch;}
			$ip_age{$ip}=$ip_latest_seen_time{$ip}-$ip_earliest_seen_time{$ip};
	
			$difference = $epoch - $ip_epoch{$ip};
			# 180 is hardcoded to be 180 seconds to speed things up
			if ( (($ip_epoch{$ip} + (180) ) < $epoch) || (! defined $ip_epoch{$ip}) ) {
				$ip_epoch{$ip}=$epoch;
				$ip_number_of_attacks{$ip}+=1;
				$ip_date_of_attacks{$ip}="$year.$month.$day.$hour.$minute.$second";
			}
			else {
				$ip_epoch{$ip}=$epoch;
			}
			if (length($username)>0){
				if ( $attack_filename ne $attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip} ){
					#print "n";
					close (IP_FILE);
					open (IP_FILE,">>$attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip}") || die "Can not write to $attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip}\n";
					$attack_filename = "$attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip}";
				}
				print (IP_FILE "$username ->$password<-\n");
			}
		}
	}
	close (FILE);
	$tmp=`date`;
	if ($DEBUG){print "done with create_attack_logs at $tmp.\n";}
}

########################################################################
# Look for common attack attempts
#
sub sort_attack_files {
	$tmp=`date`;
	if ($DEBUG){print "Sorting attack files now at $tmp.\n";}
	if ( ! -d $attacks_dir ) { print "Something bad has happened, can not chdir to $attacks_dir, exiting now\n";exit;}
	chdir ("$attacks_dir");
	#
	# What I am doing is sorting the attack files to make them more the same.
	#
	#$DEBUG=1;
	if ($DEBUG){print "DEBUG Sorting attack files now\n";}
	open (PIPE, "find . -type f |") || die "can not open pipe to cleanup files\n";
	while (<PIPE>){
		chomp;
		`sort $_ --output $_`;
	}
	close (PIPE);
	$tmp=`date`;
	if ($DEBUG){print "Done Sorting attack files now at $tmp.\n";}
}


########################################################################
# make md5 checksums.  This takes 1:45 to run with 13 million records
# and could probably be sped up somehow
#
sub make_md5_checksums{
	$tmp=`date`;
	if ($DEBUG){print "Making md5sum files now at $tmp.\n";}
	chdir ("$attacks_dir");
	print "DEBUG $attacks_dir\n";

	#
	# I always rebuild md5sum data since there might be
	# attacks that are no longer valid due to a partial
	# attack being previously recorded.
	#
	system ("ls |grep - |grep -v dict |grep -v sshpsycho |xargs md5sum |sort -T $TMP_DIRECTORY -n |uniq   > sum2.data");
	# sum2.data.wc is used by /usr/local/etc/bots/LongTail_get_botnet_stats.pl
	# Nope, not being used yet. #system ("ls |grep - |grep -v dict |grep -v sshpsycho |xargs wc -l |grep -v \ total > sum2.data.wc");

	if ($DEBUG){print "Trying md5sum for multiple attacks  now\n";}
	system ("cat sum2.data |sort -T $TMP_DIRECTORY -nr |awk \'{print \$1}\' |uniq -c |grep -v '  1 '> sum.data");

	if ($DEBUG){print "Trying md5sum for single attacks  now\n";}
	system ("cat sum2.data |sort -T $TMP_DIRECTORY -nr |awk \'{print \$1}\' |uniq -c |grep '  1 '> sum.single.attack.data");

	$tmp=`date`;
	if ($DEBUG){print "Done Making md5sum files now at $tmp.\n";}
}


########################################################################
# make the dictionary files
# Why does this take longer than md5 checksuming all the files?
#
# Don't forget that there are LESS dictionaries than attacks
# because many attacks are duplicates.
#
sub make_dictionaries{
	local $lines_in_sum2_data;
	$lines_in_sum2_data=0;
	local $dictionaries_made;
	$dictionaries_made=0;
	$tmp=`date`;
	chdir ("$attacks_dir");
	print "DEBUG making dictionaries now: $tmp\n";
	
	open (FILE, "sum2.data");
	while (<FILE>){
		chomp;
		($checksum,$file)=split(/  /,$_);
		$lines_in_sum2_data++;
		if ( ! -e "dict-$checksum.txt"){
			$dictionaries_made++;
			#`ln -s  $file dict-$checksum.txt`; # linking is faster than copying (1:18)
			symlink ($file, "dict-$checksum.txt"); # and symlink is marginally faster (0:58)
			#`cat $file |wc -l > dict-$checksum.txt.wc`;
			# Hmm, I tested this, and dealing with counting lines
			# is faster in perl than using cat and wc
			open (FILE2, $file);
			while (<FILE2>){}
			$WC = $.;
			close (FILE2);
			open (FILE2, ">dict-$checksum.txt.wc");
			print (FILE2 "$WC\n");
			close (FILE2);
		}
	}
	close (FILE);
	#print "$lines_in_sum2_data, $dictionaries_made\n";
	$tmp=`date`;
	print "DEBUG Done making dictionaries now: $tmp\n";

}
	

########################################################################
# First pass at analyzing the attack files
#
sub analyze {
	# Keep the interesting stuff near the top of the report
	chdir ("$attacks_dir");
	$tmp=`date`;
	print "DEBUG doing analyze now: $tmp\n";
	open (FILE_FORMATTED_MULTI, ">$honey_dir/attack_patterns.shtml") || die "Can not write to $honey_dir/attack_patterns.shtml\n";
	print (FILE_FORMATTED_MULTI "<HTML>\n");
	print (FILE_FORMATTED_MULTI "<HEAD>\n");
	print (FILE_FORMATTED_MULTI "<TITLE>LongTail Log Analysis Multiple Use Of Same Dictionary Attacks</TITLE>\n");
	print (FILE_FORMATTED_MULTI "</HEAD>\n");
	print (FILE_FORMATTED_MULTI "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED_MULTI "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED_MULTI "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED_MULTI "<H1>LongTail Log Analysis Multiple Use Of Same Dictionary Attacks</H1>\n");
	print (FILE_FORMATTED_MULTI "<P>This page is updated daily.\n");
	print (FILE_FORMATTED_MULTI "Last updated on $DATE\n");

	open (FILE_FORMATTED_SINGLE, ">$honey_dir/attack_patterns_single.shtml") || die "Can not write to $honey_dir/attack_patterns_single.shtml\n";
	print (FILE_FORMATTED_SINGLE "<HTML>\n");
	print (FILE_FORMATTED_SINGLE "<HEAD>\n");
	print (FILE_FORMATTED_SINGLE "<TITLE>LongTail Log Analysis Single Use Dictionary Attacks</TITLE>\n");
	print (FILE_FORMATTED_SINGLE "</HEAD>\n");
	print (FILE_FORMATTED_SINGLE "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED_SINGLE "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED_SINGLE "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED_SINGLE "<H1>LongTail Log Analysis Single Use Dictionary Attacks</H1>\n");
	print (FILE_FORMATTED_SINGLE "<P>This page is updated daily.\n");
	print (FILE_FORMATTED_SINGLE "Last updated on $DATE\n");

	open (FILE, "sum2.data")||die "can not open sum2.data\n";
	$prior_checksum="";
	$checksum_occurences=0;
	$prior_checksum="";
	$prior_ip="";
	$checksum_seen=0;
	while (<FILE>){
		chomp;
		($checksum,$ip_1,$ip_2,$ip_3,$ip_4,$host,$attack_number,
		$year,$month,$day,$hour,$minute,$second )=split(/ +|\.|-/,$_);
		$current_checksum=$checksum;
		$current_ip="$ip_1.$ip_2.$ip_3.$ip_4";
		if ($prior_checksum ne $current_checksum){
			if ($prior_checksum eq ""){
				$prior_ip=$current_ip;
				$prior_checksum=$current_checksum;
				$WC=`cat dict-$prior_checksum.txt.wc`;
				chomp $WC;
				$print_string="<HR>\n<a name=\"$current_checksum\"></a>\n<A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n<P>IP addresses:\n<A HREF=\"/honey/ip_attacks.shtml#$current_ip\">$current_ip</A>\n";
				$checksum_occurences=1;
			}
			else {
				if ($checksum_occurences == 1 ){ #There was only one instance
					print (FILE_FORMATTED_SINGLE $print_string);
					$prior_ip=$current_ip;
					$prior_checksum=$current_checksum;
					$WC=`cat dict-$prior_checksum.txt.wc`;
					chomp $WC;
					$print_string="<HR>\n<a name=\"$current_checksum\"></a>\n<A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n<P>IP addresses:\n<A HREF=\"/honey/ip_attacks.shtml#$current_ip\">$current_ip</A>\n";
					$checksum_occurences=1;
				}
				elsif ($checksum_occurences > 1 ){#There was more than one instance
					print (FILE_FORMATTED_MULTI $print_string);
					$prior_ip=$current_ip;
					$prior_checksum=$current_checksum;
					$WC=`cat dict-$prior_checksum.txt.wc`;
					chomp $WC;
					$print_string="<HR>\n<a name=\"$current_checksum\"></a>\n<A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n<P>IP addresses:\n<A HREF=\"/honey/ip_attacks.shtml#$current_ip\">$current_ip</A>\n";
					$checksum_occurences=1;
				}
			}
		}
		else {  # Checksum is the same as the line before it
			$print_string=$print_string."<A HREF=\"/honey/ip_attacks.shtml#$current_ip\">$current_ip</A>\n";
			$checksum_occurences ++ ;
		}
	}
	close (FILE);

	print (FILE_FORMATTED_MULTI "</TABLE>\n");
	print (FILE_FORMATTED_MULTI "</BODY>\n");
	print (FILE_FORMATTED_MULTI "</HTML>\n");
	close (FILE_FORMATTED_MULTI);

	print (FILE_FORMATTED_SINGLE "</TABLE>\n");
	print (FILE_FORMATTED_SINGLE "</BODY>\n");
	print (FILE_FORMATTED_SINGLE "</HTML>\n");
	close (FILE_FORMATTED_SINGLE);
	$tmp=`date`;
	print "DEBUG Done doing analyze now: $tmp\n";
}

#####################################################################
# Lets try and print out the lifetimes of attackers
# I don't really care about sorting by IP address,
# especially since it doesn't seem to sort properly anyways
#
# printing out by sorting on AGE of IP address (How long it was alive)
# 
# This really needs to be sped up
sub show_lifetime_of_ips {
	$tmp=`date`;
	print "DEBUG In show_lifetime_of_ips: $tmp\n";
	open (FILE_FORMATTED, ">$honey_dir/current_attackers_lifespan.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	open (FILE_UNFORMATTED, ">$honey_dir/current_attackers_lifespan.tmp") || die "Can not write to $honey_dir/current_attackers_lifespan.tmp\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Attackers Lifespan</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Attackers Lifespan</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated daily.\n");
	print (FILE_FORMATTED "<P>Last updated on $DATE\n");
	print (FILE_FORMATTED "<P>Click the header to sort on that column\n");
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR>
<TH><a href=\"/honey/current_attackers_lifespan_ip.shtml\">IP</a></TH>
<TH><a href=\"/honey/current_attackers_lifespan.shtml\">Lifetime In Days</a></TH>
<TH><a href=\"/honey/current_attackers_lifespan_botnet.shtml\">Botnet</a></TH>
<TH><a href=\"/honey/current_attackers_lifespan_first.shtml\">First Date Seen</a></TH>
<TH><a href=\"/honey/current_attackers_lifespan_last.shtml\">Last Date Seen</a></TH>
<TH><a href=\"/honey/current_attackers_lifespan_number.shtml\">Number of Attack<BR>Patterns Recorded</a></TH></TR>\n");
	close (FILE_FORMATTED);
	`cp $honey_dir/current_attackers_lifespan.shtml $honey_dir/current_attackers_lifespan_ip.shtml`;
	`cp $honey_dir/current_attackers_lifespan.shtml $honey_dir/current_attackers_lifespan_botnet.shtml`;
	`cp $honey_dir/current_attackers_lifespan.shtml $honey_dir/current_attackers_lifespan_first.shtml`;
	`cp $honey_dir/current_attackers_lifespan.shtml $honey_dir/current_attackers_lifespan_last.shtml`;
	`cp $honey_dir/current_attackers_lifespan.shtml $honey_dir/current_attackers_lifespan_number.shtml`;


	if ( ! -e "/var/www/html/honey/attacks/sum2.data"){
		print "Can't find /var/www/html/honey/attacks/sum2.data, exiting now\n";
		exit;
	}
	open (FILE, "/var/www/html/honey/attacks/sum2.data");
	open (OUTPUT, ">$TMP_DIRECTORY/sum2.data_munged") || die "can not write to $TMP_DIRECTORY/sum2.data_munged, exiting now\n";;
	while (<FILE>){
		chomp;
		($checksum,$info)=split(/ +/,$_,2);
		($ip1,$ip2,$ip3,$ip4,$host,$attack_number,$year,$month,$day,$hour,$minute,$second)=split(/\.|-/,$info);
		print (OUTPUT "$ip1.$ip2.$ip3.$ip4.$year.$month.$day.$hour.$minute.$second\n");
	}
	close (FILE);
	close (OUTPUT);
	
	`sort $TMP_DIRECTORY/sum2.data_munged --output $TMP_DIRECTORY/sum2.data_munged`;
	
	$times_used=0;
	$prior_ip="";
	$first_used=0;
	$last_used=0;
	
	open (FILE, "$TMP_DIRECTORY/sum2.data_munged");
	open (FILE_UNFORMATTED, ">$TMP_DIRECTORY/current_attackers_lifespan.tmp") || die "Can not write to $TMP_DIRECTORY/current_attackers_lifespan.tmp\n";
	while (<FILE>){
		chomp;
		($ip1,$ip2,$ip3,$ip4,$line_year,$line_month,$line_day,$line_hour,$line_minute,$line_second)=split(/\.|-/,$_);
		$this_ip="$ip1.$ip2.$ip3.$ip4";
		if ( $this_ip ne $prior_ip){
			if ($prior_ip ne ""){
				($year,$month,$day,$hour,$minute,$second)=split(/\./,$first_used);
				$epoch_first=timelocal($second,$minute,$hour,$day,$month-1,$year);
				$first_used="$year/$month/$day $hour:$minute:$second";
	
				($year,$month,$day,$hour,$minute,$second)=split(/\./,$last_used);
				$epoch_last=timelocal($second,$minute,$hour,$day,$month-1,$year);
				$last_used="$year/$month/$day $hour:$minute:$second";
	
				$lifetime=$epoch_last-$epoch_first;
	
				$days=$lifetime/86400;
				if ( ( $prior_ip =~ /^43.255.190/) ||
					( $prior_ip =~ /^43.255.191/) ||
					( $prior_ip =~ /^103.41.124/) ||
					( $prior_ip =~ /^103.41.125/) ){
					$botnet="sshPsycho";
				}
				else {
					if (( $prior_ip =~ /^43.229.52/) ||
						( $prior_ip =~ /^43.255.188/) ||
						( $prior_ip =~ /^43.255.189/) ||
						( $prior_ip =~ /^43.229.53/) ){
						$botnet="sshPsycho-2";
					}
					else {
						$botnet=" : ";
						# This is UGLY and takes too long
						# It opens too many files and doesn't exit after it finds it
						$botnet=`grep ^$prior_ip /usr/local/etc/LongTail_botnets/* /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses  /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses |egrep -v accounts|grep -v 2015 2>/dev/null `;
						($botnet,$trash)=split(/:/,$botnet);
						$botnet =~ s/.usr.local.etc.//;
						$botnet =~ s/LongTail_botnets.//;
						$botnet =~ s/LongTail_//;
					}
				}
				

	
				printf(FILE_UNFORMATTED "%s|%.2f|%s|%s|%s|<a href=\"/honey/ip_attacks.shtml#%s\">%d</A>\n", $prior_ip, $days, $botnet, $first_used, $last_used, $prior_ip, $times_used);
			}
	
			$first_seen="$first_used";
			$last_seen="$last_used";
	
			$prior_ip=$this_ip;
			$times_used=1;
			$first_used="$line_year.$line_month.$line_day.$line_hour.$line_minute.$line_second";
			$last_used="$line_year.$line_month.$line_day.$line_hour.$line_minute.$line_second";
		}
		else {
			$times_used++;
			$last_used="$line_year.$line_month.$line_day.$line_hour.$line_minute.$line_second";
		}
		
	
	}
	close (FILE);
	close (FILE_UNFORMATTED);
	
	unlink ("$TMP_DIRECTORY/sum2.data_munged");

	$tmp=`date`; print "DEBUG trying sort -T $TMP_DIRECTORY -nk2 now:$tmp\n";

	#
	# Main lifetime page / Sorted by lifetime in days
	#
	`sort -T $TMP_DIRECTORY -rnk2 -t\\| $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_FORMATTED);

	#
	# Sorted by ip
	# sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n
	#`sort -T $TMP_DIRECTORY -rnk1 -t\\| $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`sort -T $TMP_DIRECTORY -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n  $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan_ip.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan_ip.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_FORMATTED);

	#
	# Sorted by botnet
	#
	`sort -T $TMP_DIRECTORY -k3 -t\\| $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan_botnet.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan_botnet.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_FORMATTED);

	#
	# Sorted by first date seen
	#
	`sort -T $TMP_DIRECTORY -k4 -t\\| $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan_first.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan_first.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_FORMATTED);

	#
	# Sorted by last date seen
	#
	`sort -T $TMP_DIRECTORY -k5 -t\\| $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan_last.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan_last.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_FORMATTED);

	#
	# Sorted by number of attacks
	#
print "DEBUG Trying to sort by number of attacks now\n";
	`sort -T $TMP_DIRECTORY -nrk2 -t\'>\' $TMP_DIRECTORY/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan_number.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan_ip.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_FORMATTED);

	$tmp=`date`;
	print "DEBUG done with show_lifetime_of_ips: $tmp\n";
}

########################################################################
# Make a sorted list of IPs and the attacks they are using.
#

sub show_attacks_of_ips {
	$tmp=`date`;
print "DEBUG In show_attacks_of_ips:$tmp\n";

	chdir ("$honey_dir/attacks");

	open (FILE_FORMATTED, ">$honey_dir/ip_attacks.shtml") || die "Can not write to $honey_dir/ip_attacks.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis IP Attackers</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis IP Attacks</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated daily.\n");
	print (FILE_FORMATTED "<P>Results are sorted by IP, and then by dictionary used.\n");
	print (FILE_FORMATTED "<P>Last updated on $DATE\n");

	open (FILE, "sort -k2 sum2.data |");
	$prior_ip="";
	while (<FILE>){
		chomp;
		($checksum,$ip_1,$ip_2,$ip_3,$ip_4,$host,$attack_number,
		$year,$month,$day,$hour,$minute,$second )=split(/ +|\.|-/,$_);
	
		$current_ip="$ip_1.$ip_2.$ip_3.$ip_4";
		if ($current_ip ne $prior_ip){
			print (FILE_FORMATTED "<HR>\n");
			print (FILE_FORMATTED "<a name=\"$_\"></a>\n");
			print (FILE_FORMATTED "<B>$current_ip</B>\n");
			$prior_ip=$current_ip;
		}
	
		# I shouldn't have to do this but it's faster than finding
		# the borked code
		if ( ! -e "dict-$checksum.txt.wc" ){
			$temp=`cat dict-$checksum.txt | wc -l  > dict-$checksum.txt.wc`;
		}
	
		open (FILE2, "dict-$checksum.txt.wc");
		while (<FILE2>){
			chomp;
			$lines=$_;
		}
		close (FILE2);
		print (FILE_FORMATTED "<BR>$lines lines, <a href=\"attacks/dict-$checksum.txt\">dict-$checksum.txt</a> <!-- From: $ip_1.$ip_2.$ip_3.$ip_4--> To: $host Attack #: $attack_number started on $year/$month/$day $hour:$minute:$second\n");
	}
	$tmp=`date`;
	print "DEBUG done foreach sorted array....: $tmp\n";
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);
	close (FILE);
	$tmp=`date`;
	print "DEBUG Done with show_attacks_of_ips:$tmp\n";
}


#############################################################################
#
# Make the dictionary webpages.  At 13 million records this takes 34 seconds
# and is "fast enough" for now.
#
sub create_dict_webpage {
	$tmp=`date`;
	if ($DEBUG){print "DEBUG Making dict webpage now:$tmp\n";}
	open (FILE_FORMATTED_TEMP, ">/$TMP_DIRECTORY/dictionaries.temp") || die "Can not write to $honey_dir/dictionaries.temp\n";
	open (FILE_FORMATTED, ">$honey_dir/dictionaries.shtml") || die "Can not write to $honey_dir/dictionaries.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Dictionaries</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Dictionaries</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated daily.\n");
	print (FILE_FORMATTED "Last updated on $DATE\n");
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR><TH>Number Of<BR>Times Used</TH><TH>Number of <BR>Entries</TH><TH>Checksum</TH><TH>Dictionary</TH><TH>First Seen</TH><TH>Last Seen</TH></TR>\n");
	chdir ("$honey_dir/attacks");
	
	$tmp=`date`;
	print "DEBUG Making temp files for dict webpage now : $tmp\n";
	open (FILE, "sum2.data") || die "can not open file sum2.data\n";
	$prior_checksum="";
	while (<FILE>){
		chomp;
		#0000b12b844d2e09b9d979e79b016242  221.146.74.146.edu_c.16-2015.06.10.14.41.35
		($checksum,$file)=split(/\s+/,$_);
		if ($checksum ne $prior_checksum){
			if ( $checksum ne ""){
				$FIRST_SEEN=scalar localtime($first_seen_epoch);
				$LAST_SEEN=scalar localtime($last_seen_epoch);
				$dictionary_file="dict-$prior_checksum.txt";
				print (FILE_FORMATTED_TEMP "$TIMES_USED|$WC|$SUM|$dictionary_file|$FIRST_SEEN|$LAST_SEEN\n");
			}
			$WC=`cat dict-$checksum.txt.wc`;
			chomp $WC;
			$prior_checksum=$checksum;
			$SUM=$checksum;
			$TIMES_USED=1;
			$COUNT=1;
			$first_seen_epoch=0;
			$last_seen_epoch=0;
			($tmp,$date_string)=split(/-/,$file);
			($year,$month,$day,$hour,$minute,$second)=split(/\./,$date_string);
			$epoch=timelocal($second,$minute,$hour,$day,$month-1,$year);
			if ($first_seen_epoch == 0){$first_seen_epoch=$epoch};
			if ($epoch > $last_seen_epoch ){$last_seen_epoch=$epoch};
			if ($epoch < $first_seen_epoch ){$first_seen_epoch=$epoch};
		}
		else { # Checksum is the same as the prior line
			$TIMES_USED++;	
			$COUNT++;
			($tmp,$date_string)=split(/-/,$file);
			($year,$month,$day,$hour,$minute,$second)=split(/\./,$date_string);
			$epoch=timelocal($second,$minute,$hour,$day,$month-1,$year);
			if ($first_seen_epoch == 0){$first_seen_epoch=$epoch};
			if ($epoch > $last_seen_epoch ){$last_seen_epoch=$epoch};
			if ($epoch < $first_seen_epoch ){$first_seen_epoch=$epoch};
		}
	}
	close (FILE);
	close (FILE_FORMATTED_TEMP);

	$tmp=`date`;
	print "DEBUG Done Making temp files for dict webpage now : $tmp\n";

	system ("sort -T $TMP_DIRECTORY -nr /$TMP_DIRECTORY/dictionaries.temp > /$TMP_DIRECTORY/dictionaries.temp.sorted");
	open (FILE, "/$TMP_DIRECTORY/dictionaries.temp.sorted");
	while (<FILE>){
		chomp;
		($TIMES_USED,$WC,$SUM,$file,$FIRST_SEEN,$LAST_SEEN)=split(/\|/,$_);
		if ($TIMES_USED > 1){
			print (FILE_FORMATTED "<TR><TD><A href=\"/honey/attack_patterns.shtml#$SUM\"> $TIMES_USED </A></TD><TD> $WC </TD><TD>$SUM</TD><TD><a href=\"attacks/$file\">$file</a></TD><TD>$FIRST_SEEN</TD><TD>$LAST_SEEN</TD></TR>\n");
		}
		else {
			print (FILE_FORMATTED "<TR><TD><A href=\"/honey/attack_patterns_single.shtml#$SUM\"> $TIMES_USED </A></TD><TD> $WC </TD><TD>$SUM</TD><TD><a href=\"attacks/$file\">$file</a></TD><TD>$FIRST_SEEN</TD><TD>$LAST_SEEN</TD></TR>\n");
		}
	}
	close (FILE);
	open (FILE_FORMATTED, ">>$honey_dir/dictionaries.shtml") || die "Can not write to $honey_dir/dictionaries.shtml\n";
		

	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);

	$tmp=`date`;
	print "DEBUG Done Making dict webpage now : $tmp\n";
	#
	# Now we sort by size of dictionary
	#
	print "DEBUG Making dictionaries-k5.shtml  now: $tmp\n";
	open (FILE_FORMATTED, ">$honey_dir/dictionaries-k5.shtml") || die "Can not write to $honey_dir/dictionaries-k5.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Dictionaries</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Dictionaries</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated daily.\n");
	print (FILE_FORMATTED "Last updated on $DATE\n");
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR><TH>Number Of<BR>Times Used</TH><TH>Number of <BR>Entries</TH><TH>Checksum</TH><TH>Dictionary</TH><TH>First Seen</TH><TH>Last Seen</TH></TR>\n");
	close (FILE_FORMATTED);

	system ("grep '<TR>' $honey_dir/dictionaries.shtml   |sort -T $TMP_DIRECTORY -nrk5  >> $honey_dir/dictionaries-k5.shtml");

	open (FILE_FORMATTED, ">>$honey_dir/dictionaries-k5.shtml") || die "Can not write to $honey_dir/dictionaries-k5.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);
	$tmp=`date`;
	print "DEBUG Done Making dictionaries-k5.shtml  now: $tmp\n";

}

#############################################################################3
#
# Mainline of code
#
#
$TMP=`date`;
print "######################################################################\n";
print "LongTail_analyze_attacks.pl Started at $TMP\n";
if ($DEBUG){print "----------------------------------------------\n";}
&init;
if ($DEBUG){print "----------------------------------------------\n";}
&cleanup_old_files;
if ($DEBUG){print "----------------------------------------------\n";}
&create_attack_logs;
if ($DEBUG){print "----------------------------------------------\n";}
&sort_attack_files;
if ($DEBUG){print "----------------------------------------------\n";}
&make_md5_checksums;
if ($DEBUG){print "----------------------------------------------\n";}
&make_dictionaries;
if ($DEBUG){print "----------------------------------------------\n";}
&analyze;
if ($DEBUG){print "----------------------------------------------\n";}
&show_lifetime_of_ips;
if ($DEBUG){print "----------------------------------------------\n";}
&show_attacks_of_ips;
if ($DEBUG){print "----------------------------------------------\n";}
&create_dict_webpage;
if ($DEBUG){print "----------------------------------------------\n";}
#
# Get rid of temp files
unlink ("/$TMP_DIRECTORY/dictionaries.temp.sorted");
unlink ("/$TMP_DIRECTORY/dictionaries.temp");
unlink ("/$TMP_DIRECTORY/tmp.data");

$TMP=`date`;
print "LongTail_analyze_attacks.pl Done at $TMP\n";
