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

sub init {
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
}

########################################################################
# Get rid of all the old files
#
sub cleanup_old_files {
	if ($DEBUG){print "Deleting old analysis files.\n";}
	if (-d "$attacks_dir" ){
		chdir ("$attacks_dir");
		open (PIPE, "find . -type f -o -type l  |") || die "can not open pipe to cleanup files\n";
		while (<PIPE>){
			chomp;
			#if (/dict-/){next;}
			if (/.html/){next;}
			if (/.shtml/){next;}
			unlink ("$_");
			#if ($DEBUG){print ".";}
		}
		#if ($DEBUG){print "DONE\n";}
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
}

########################################################################
# Sort the data by IP, host, and add code to delimit attacks by
# some vague timeframe
#
# DATA line looks like the following:
#Feb 16 10:56:57 shepherd sshd-22[9306]: IP: 103.21.218.221 PassLog: Username: ubnt Password: ubnt
#
sub create_attack_logs {
	if ($DEBUG){print "starting create_attack_logs .\n";}
	if ($DEBUG){print "Creating new analysis files(/$TMP_DIRECTORY/tmp.data) .\n";}
	#
	# Ok, find does NOT work in the proper order....  Gotta use the ls command.
	#
	# This is ugly and will break once I get a ton of data
	#
	unlink ("/$TMP_DIRECTORY/tmp.data");
	chdir ("$honey_dir/historical/");
	open (LS, "/bin/ls */*/*/current-raw-data.gz /var/www/html/honey/current-raw-data.gz |") || 
		die "Can not run /bin/ls command on $honey_dir/historical/\n";
	while (<LS>){
		chomp;
		system ("/usr/local/etc/catall.sh $_ >> /$TMP_DIRECTORY/tmp.data");
	}
	close (LS);

	#
	# This is ugly and will break once I get a ton of data
	#
	if ($DEBUG){print "DEBUG Done making /$TMP_DIRECTORY/tmp.data\n";}
	open (FILE, "/usr/local/etc/catall.sh /$TMP_DIRECTORY/tmp.data |") || 
		die "Can not open /$TMP_DIRECTORY/tmp.data for reading\n";
	while (<FILE>){
		chomp;
		$good_line=0;
		$username="";
		$password="";
		if ((/ IP: /o) && ((/ PassLog: /o)   || (/ Pass2222Log: /o)  ) ){
			#if ($DEBUG){print "P";}
			($timestamp,$hostname,$process,$IP_FLAG,$ip,$PASSLOG_FLAG,$USERNAME_FLAG,$username,$PASSWORD_FLAG,$password)=split(/ +/,$_);
			($date,$time)=split(/T/,$timestamp);
			($year,$month,$day)=split(/-/,$date);
			($time,$trash)=split(/\./,$time);
			($hour,$minute,$second)=split(/:/,$time);
			if ($second =~ /-/){ ($second,$trash)=split(/-/,$second);}
			$good_line=1;
	 	}
		elsif (/Failed password/o){
			#if ($DEBUG){print "F";}
			# 2015-02-23T23:02:29.061917-05:00 shepherd sshd-22[5208]: Failed password for invalid user ubnt from 223.203.217.202 port 45769 ssh2
			# 2015-02-23T23:02:29.061917-05:00 shepherd sshd[7245]: Failed password for root from 61.234.146.22 port 52574 ssh2
			#if ($DEBUG){print "Failed password\n";}
			$good_line=1;
			# WAS ($month,$day,$time,$hostname,$process,$IP_FLAG,$ip,$PASSLOG_FLAG,$USERNAME_FLAG,$username,$PASSWORD_FLAG,$password)=split(/ +/,$_);
			($timestamp,$hostname,$process,$IP_FLAG,$ip,$PASSLOG_FLAG,$USERNAME_FLAG,$username,$PASSWORD_FLAG,$password)=split(/ +/,$_);
			$username="";
			$size=@my_array=split(/ +/,$_);
			$timestamp=$my_array[0];
			($date,$time)=split(/T/,$timestamp);
			($year,$month,$day)=split(/-/,$date);
			($time,$trash)=split(/\./,$time);
			($hour,$minute,$second)=split(/:/,$time);
			if ($second =~ /-/){ ($second,$trash)=split(/-/,$second);}
			$ip=$my_array[$size-4];
		}
 	
		if ($good_line){
			#if ($DEBUG){print ".";}
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
				#if ($DEBUG){$TRASH=system("date"); print $TRASH; print "DEBUG - new attack from $ip\n";}
				#if ($DEBUG){print "DEBUG - Date is $year,$month,$day,$hour,$minute,$second\n";}
				$ip_epoch{$ip}=$epoch;
				$ip_number_of_attacks{$ip}+=1;
				$ip_date_of_attacks{$ip}="$year.$month.$day.$hour.$minute.$second";
				#if ($DEBUG){print "count is $ip $ip_number_of_attacks{$ip},$month,$day,$time\n";}
			}
			else {
				$ip_epoch{$ip}=$epoch;
			}
			if (length($username)>0){
				open (IP_FILE,">>$attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip}") || die "Can not write to $attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip}\n";
				print (IP_FILE "$username ->$password<-\n");
				close (IP_FILE);
			}
		}
	}
	close (FILE);
	if ($DEBUG){print "done with create_attack_logs .\n";}
}

########################################################################
# Look for common attack attempts
#
sub analyze {
	$DEBUG=1;
	if ($DEBUG){print "Analyzing now.\n";}
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

	#
	# This is freaking ugly and time consuming
	#

	if ($DEBUG){print "Trying md5sum all files  now\n";}
	system ("ls |grep - |grep -v dict |grep -v sshpsycho |xargs md5sum |sort -T $TMP_DIRECTORY -n  > sum2.data");

	if ($DEBUG){print "Trying md5sum for multiple attacks  now\n";}
	#system ("ls |grep - |grep -v dict |xargs md5sum  |sort -T $TMP_DIRECTORY -nr |awk \'{print \$1}\' |uniq -c |grep -v '  1 '> sum.data");
	system ("cat sum2.data |sort -T $TMP_DIRECTORY -nr |awk \'{print \$1}\' |uniq -c |grep -v '  1 '> sum.data");

	if ($DEBUG){print "Trying md5sum for single attacks  now\n";}
	#system ("ls |grep - |grep -v dict |xargs md5sum  |sort -T $TMP_DIRECTORY -nr |awk \'{print \$1}\' |uniq -c |grep '  1 '|grep -v sum.data |grep -v sum.data > sum.single.attack.data");
	system ("cat sum2.data |sort -T $TMP_DIRECTORY -nr |awk \'{print \$1}\' |uniq -c |grep '  1 '> sum.single.attack.data");

	if ($DEBUG){print "Done making  md5sum all files  now\n";}

	$tmp=`date`;
	print "DEBUG making dictionaries now: $tmp\n";
	open (FILE, "sum2.data");
	while (<FILE>){
		chomp;
		($checksum,$file)=split(/  /,$_);
		if ( ! -e "dict-$checksum.txt"){
			`cp $file dict-$checksum.txt`;
			`cat $file |wc -l > dict-$checksum.txt.wc`;
		}
	}
	close (FILE);
	$tmp=`date`;
	print "DEBUG Done making dictionaries now: $tmp\n";
	
	# Keep the interesting stuff near the top of the report
	if ($DEBUG){print "DEBUG Doing multiple attack data now\n";}
	open (FILE, "sum.data")||die "can not open sum.data\n";
	open (FILE_FORMATTED, ">$honey_dir/attack_patterns.shtml") || die "Can not write to $honey_dir/attack_patterns.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Multiple Use Of Same Dictionary Attacks</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Multiple Use Of Same Dictionary Attacks</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated daily.\n");
	print (FILE_FORMATTED "Last updated on $DATE\n");

	while (<FILE>){
		chomp;
		($tmp,$count, $checksum)=split(/ +/,$_);
		print (FILE_FORMATTED "<HR>\n");
		print (FILE_FORMATTED "<a name=\"$checksum\"></a>\n");
		print (FILE_FORMATTED "<P>IP addresses:\n");
		open (FILE2, "sum2.data");
		while (<FILE2>){
			if (/$checksum/){
				chomp;
				($trash,$filename)=split(/ +/,$_);
				($first,$second,$third,$fourth,$host)=split(/\./, $filename);
				$tmp="$first.$second.$third.$fourth";
				print (FILE_FORMATTED "<A HREF=\"/honey/ip_attacks.shtml#$tmp\">$tmp</A> \n");
			}
		}
		close (FILE2);

		$WC=`/usr/bin/wc -l $filename |awk '{print \$1}' `;
		print (FILE_FORMATTED "<BR><A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n");
		
	}
	close (FILE);
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);

	if ($DEBUG){print "DEBUG Doing single attack data now\n";}
	open (FILE, "sum.single.attack.data")||die "can not open sum.single.attack.data\n";
	open (FILE_FORMATTED, ">$honey_dir/attack_patterns_single.shtml") || die "Can not write to $honey_dir/attack_patterns_single.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Single Use Dictionary Attacks</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Single Use Dictionary Attacks</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated daily.\n");
	print (FILE_FORMATTED "Last updated on $DATE\n");

	while (<FILE>){
		chomp;
		($tmp,$count, $checksum)=split(/ +/,$_);
		print (FILE_FORMATTED "<HR>\n");
		print (FILE_FORMATTED "<P>IP addresses:\n");
		open (FILE2, "sum2.data");
		while (<FILE2>){
			if (/$checksum/){
				chomp;
				($trash,$filename)=split(/ +/,$_);
				($first,$second,$third,$fourth,$host)=split(/\./, $filename);
				$tmp="$first.$second.$third.$fourth";
				print (FILE_FORMATTED "<A HREF=\"/honey/ip_attacks.shtml#$tmp\">$tmp</A> \n");
			}
		}
		$WC=`/usr/bin/wc -l $filename |awk '{print \$1}' `;
		print (FILE_FORMATTED "<BR><A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n");
		close (FILE2);
		
	}
	close (FILE);
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);
}

# Lets try and print out the lifetimes of attackers
# I don't really care about sorting by IP address,
# especially since it doesn't seem to sort properly anyways
#
# printing out by sorting on AGE of IP address (How long it was alive)
sub show_lifetime_of_ips {
	$tmp=`date`;
print "DEBUG In show_lifetime_of_ips: $tmp\n";
	#print "DEBUG ===================================================\n\n";
	#print "DEBUG- Trying to sort by age of ip\n";
	#open (FILE_DATA, "> $honey_dir/current_attackers_lifespan.data")||die "Can not write to $honey_dir/current_attackers_lifespan.data\n";
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
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR><TH>IP</TH><TH>Lifetime In Days</TH><TH>First Date Seen</TH><TH>Last Date Seen</TH><TH>Number of Attack<BR>Patterns Recorded</TH></TR>\n");

	$tmp=`date`;
print "DEBUG In sorting by key now:$tmp\n";
print "DEBUG-I should do this with find . -name '$ip*' |sort -T $TMP_DIRECTORY -nk6 -t \. instead\n";
# and then pipe those shorter results to sort, and then print them out.

	foreach $key (keys %ip_age){
#print ".";
		$days=$ip_age{$key}/86400;
		$first_seen=scalar localtime($ip_earliest_seen_time{$key});
		$last_seen=scalar localtime($ip_latest_seen_time{$key});
		$attacks_recorded = `grep $key sum2.data |wc -l 2>/dev/null `;
	  	printf(FILE_UNFORMATTED "%s|%.2f|%s|%s|<a href=\"/honey/ip_attacks.shtml#%s\">%d</A>\n", $key, $days,$first_seen, $last_seen, $key, $attacks_recorded);
	}
	close (FILE_FORMATTED);

	$tmp=`date`;
print "DEBUG trying sort -T $TMP_DIRECTORY -nk2 now:$tmp\n";
	`sort -T $TMP_DIRECTORY -rnk2 -t\\| $honey_dir/current_attackers_lifespan.tmp > $honey_dir/current_attackers_lifespan.tmp2`;
print "DEBUG trying cat now\n";
	`cat $honey_dir/current_attackers_lifespan.tmp2 |sed 's/^/<TR><TD>/' |sed 's/|/<\\/TD><TD>/g'|sed 's/\$/<\\/TD><\\/TR>/' >> $honey_dir/current_attackers_lifespan.shtml`;
	open (FILE_FORMATTED, ">>$honey_dir/current_attackers_lifespan.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	
	print "DEBUG DONE sorting by key now\n";

	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	#close(FILE_DATA);
	close(FILE_FORMATTED);
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

	# Data format
	#[shepherd@shepherd attacks]$ head sum2.data 
	#00c5c88080c454cd587646ecb2320a91  122.225.97.84.shepherd.4-1.16.01.30.35
	#00ec2c6c48b95f9dce17cd85dff5154a  122.225.97.88.shepherd.1-1.5.07.18.58
	#0a2b14b5a46482433674508e8e182670  211.157.103.36.shepherd.3-1.31.08.40.28
	#
	open (FILE, "sum2.data");
	while (<FILE>){
		chomp;
		($checksum,$first,$second,$third,$fourth,$trash)=split(/ +|\./,$_);
		if (!( "$first.$second.$third.$fourth" ~~ @ip_array )) {
			push @ip_array , "$first.$second.$third.$fourth";
		}
	}
	close (FILE);
	
	#
	# Sort the IP array
	#
	$tmp=`date`;
print "DEBUG This is slow....: $tmp\n";
	my @sorted = map  { $_->[0] }
             	sort { $a->[1] <=> $b->[1] }
             	map  { [$_, int sprintf("%03.f%03.f%03.f%03.f", split(/\.+/, $_))] }
             	@ip_array;
	
$tmp=`date`;
print "DEBUG foreach sorted arracy....: $tmp\n";
	foreach (@sorted){
		print (FILE_FORMATTED "<HR>\n");
		print (FILE_FORMATTED "<a name=\"$_\"></a>\n");
		print (FILE_FORMATTED "<B>$_</B>\n");
		open (GREP, "grep $_ sum2.data|");
		while (<GREP>){
			($checksum, $file)=split (/ +/,$_,2);
			# 211.157.103.36.shepherd.3-2015.1.31.08.40.28
			($ip_and_host,$date)=split(/-/,$file,2);
			($year,$month,$day,$hour,$minute,$second)=split(/\./,$date);
			($ip_1,$ip_2,$ip_3,$ip_4,$host,$attack_number)=split(/\./,$ip_and_host);
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
		close (GREP);
	}
$tmp=`date`;
print "DEBUG done foreach sorted arracy....: $tmp\n";
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);
	$tmp=`date`;
print "DEBUG Done with show_attacks_of_ips:$tmp\n";
}


#############################################################################3
#
# Make the dictionary webpage
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
	
	# This breaks with too many files #open (PIPE, "/bin/ls dict-* |") || die "can not open pipe to cleanup files\n";
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
				$$dictionary_file="dict-$checksum.txt";
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
print "LongTail_analyze_attacks.pl Started at $TMP\n";
&init;
$TMP=`date`;chomp $TMP; print "done with init at $TMP, calling cleanup_old_files\n";
&cleanup_old_files;
$TMP=`date`;chomp $TMP; print "done with cleanup_old_files at $TMP, calling create_attack_logs\n";
&create_attack_logs;
$TMP=`date`;chomp $TMP; print "done with create_attack_logs at $TMP, calling analyze\n";
&analyze;
$TMP=`date`;chomp $TMP; print "done with analyze at $TMP, calling show_lifetime_of_ips\n";
&show_lifetime_of_ips;
$TMP=`date`;chomp $TMP; print "done with show_lifetime_of_ips at $TMP, calling show_attacks_of_ips\n";
&show_attacks_of_ips;
$TMP=`date`;chomp $TMP; print "done with show_attacks_of_ips at $TMP, calling create_dict_webpage\n";
&create_dict_webpage;
$TMP=`date`;chomp $TMP; print "done with create_dict_webpage at $TMP, getting rid of temp files now\n";
#
# Get rid of temp files
unlink ("/$TMP_DIRECTORY/dictionaries.temp.sorted");
unlink ("/$TMP_DIRECTORY/dictionaries.temp");
unlink ("/$TMP_DIRECTORY/tmp.data");
# I am using httpd.conf to protect this directory now
#if (-d "$attacks_dir" ){
#	chdir ("$attacks_dir");
#	$tmp=system("find . -type f -size -128c | xargs chmod go-rwx ");
#	$tmp=system("chmod a+r ip_attacks.shtml");
#	$tmp=system("chmod a+rx .");
#}

$TMP=`date`;
print "LongTail_analyze_attacks.pl Done at $TMP\n";
