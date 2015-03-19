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
	$DEBUG=0;
	$honey_dir="/var/www/html/honey/";
	$attacks_dir="/var/www/html/honey/attacks/";
	$DATE=`date`;
}

########################################################################
# Get rid of all the old files
#
sub cleanup_old_files {
	if ($DEBUG){print "Deleting old analysis files.\n";}
	if (-d "$attacks_dir" ){
		chdir ("$attacks_dir");
		open (PIPE, "find . -type f |") || die "can not open pipe to cleanup files\n";
		while (<PIPE>){
			chomp;
			if (/dict-/){next;}
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
	if ($DEBUG){print "Creating new analysis files(/tmp/tmp.data) .\n";}
	#
	# Ok, find does NOT work in the proper order....  Gotta use the ls command.
	#
	# This is ugly and will break once I get a ton of data
	#
	unlink ("/tmp/tmp.data");
	chdir ("$honey_dir/historical/");
	open (LS, "/bin/ls */*/*/current-raw-data.gz |") || 
		die "Can not run /bin/ls command on $honey_dir/historical/\n";
	while (<LS>){
		chomp;
		system ("/usr/local/etc/catall.sh $_ >> /tmp/tmp.data");
	}
	close (LS);

	#
	# This is ugly and will break once I get a ton of data
	#
	if ($DEBUG){print "DEBUG Done making /tmp/tmp.data\n";}
	open (FILE, "/usr/local/etc/catall.sh /tmp/tmp.data |") || 
		die "Can not open /tmp/tmp.data for reading\n";
	while (<FILE>){
		chomp;
		$good_line=0;
		$username="";
		$password="";
		if ((/ IP: /o) && (/ PassLog: /o)){
			#if ($DEBUG){print "P";}
			($timestamp,$hostname,$process,$IP_FLAG,$ip,$PASSLOG_FLAG,$USERNAME_FLAG,$username,$PASSWORD_FLAG,$password)=split(/ +/,$_);
			($date,$time)=split(/T/,$timestamp);
			($year,$month,$day)=split(/-/,$date);
			($time,$trash)=split(/\./,$time);
			($hour,$minute,$second)=split(/:/,$time);
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
				if ($DEBUG){$TRASH=system("date"); print $TRASH; print "DEBUG - new attack from $ip\n";}
				if ($DEBUG){print "DEBUG - Date is $year,$month,$day,$hour,$minute,$second\n";}
				$ip_epoch{$ip}=$epoch;
				$ip_number_of_attacks{$ip}+=1;
				$ip_date_of_attacks{$ip}="$year.$month.$day.$hour.$minute.$second";
				#if ($DEBUG){print "count is $ip $ip_number_of_attacks{$ip},$month,$day,$time\n";}
			}
			else {
				$ip_epoch{$ip}=$epoch;
			}
			if (length($username)>0){
				#if ($DEBUG){print "W";}
#print "DEBUG-Appending to file $attacks_dir/$ip.$hostname.$ip_number_of_attacks{$ip}-$ip_date_of_attacks{$ip}\n";
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
	if ($DEBUG){print "Analyzing now.\n";}
	if ( ! -d $attacks_dir ) { print "Something bad has happened, can not chdir to $attacks_dir, exiting now\n";exit;}
	chdir ("$attacks_dir");
	#
	# What I am doing is sorting the attack files to make them more the same.
	#
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
	if ($DEBUG){print "Trying md5sum for multiple attacks  now\n";}
	system ("md5sum *.*.*.*-* |sort -nr |awk \'{print \$1}\' |uniq -c |grep -v '  1 '> sum.data");
	if ($DEBUG){print "Trying md5sum for single attacks  now\n";}
	system ("md5sum *.*.*.*-* |sort -nr |awk \'{print \$1}\' |uniq -c |grep '  1 '|grep -v sum.data |grep -v sum.data > sum.single.attack.data");
	if ($DEBUG){print "Trying md5sum all files  now\n";}
	system ("md5sum *.*.*.*-* |sort -n  > sum2.data");
	if ($DEBUG){print "Done making  md5sum all files  now\n";}
	
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
	print (FILE_FORMATTED "<P>This page is updated hourly.\n");
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
				print (FILE_FORMATTED "<A HREF=\"/honey/attacks/ip_attacks.shtml#$tmp\">$tmp</A> \n");
			}
		}
		$WC=`/usr/bin/wc -l $filename |awk '{print \$1}' `;
		print (FILE_FORMATTED "<BR><A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n");
#		if ($DEBUG){print "DEBUG Looking for file dict-$checksum.txt\n";}
		if ( ! -e "dict-$checksum.txt" ){
			#print "DEBUG Making dictionary dict-$checksum.txt\n";
			$temp=`cp $filename dict-$checksum.txt`;
			$temp=`cat dict-$checksum.txt |wc -l > dict-$checksum.txt.wc`;
			#print "DEBUG output is $temp\n";
		}
		#else {print "dict-$checksum.txt apparently exists?\n";}
		close (FILE2);
		
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
	print (FILE_FORMATTED "<P>This page is updated hourly.\n");
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
				print (FILE_FORMATTED "<A HREF=\"/honey/attacks/ip_attacks.shtml#$tmp\">$tmp</A> \n");
			}
		}
		$WC=`/usr/bin/wc -l $filename |awk '{print \$1}' `;
		print (FILE_FORMATTED "<BR><A href=\"attacks/dict-$checksum.txt\">$WC Lines, attack pattern $checksum</a>\n");
		if ($DEBUG){print "DEBUG Looking for file dict-$checksum.txt\n";}
		if ( ! -e "dict-$checksum.txt" ){
			#print "DEBUG Making dictionary dict-$checksum.txt\n";
			$temp=`cp $filename dict-$checksum.txt`;
			#DEBUG
			$temp=`/usr/bin/wc -l dict-$checksum.txt |awk '{print \$1}' > dict-$checksum.txt.wc`;
			#print "DEBUG output is $temp\n";
		}
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
#print "DEBUG In show_lifetime_of_ips\n";
	#print "DEBUG ===================================================\n\n";
	#print "DEBUG- Trying to sort by age of ip\n";
	open (FILE_DATA, "> $honey_dir/current_attackers_lifespan.data")||die "Can not write to $honey_dir/current_attackers_lifespan.data\n";
	open (FILE_FORMATTED, ">$honey_dir/current_attackers_lifespan.shtml") || die "Can not write to $honey_dir/current_attackers_lifespan.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Attackers Lifespan</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Attackers Lifespan</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated hourly.\n");
	print (FILE_FORMATTED "<P>Last updated on $DATE\n");
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR><TH>IP</TH><TH>Lifetime In Days</TH><TH>First Date Seen</TH><TH>Last Date Seen</TH><TH>Number of Attack<BR>Patterns Recorded</TH></TR>\n");

	foreach $key (sort {$ip_age{$b} <=> $ip_age{$a}} keys %ip_age){
		$days=$ip_age{$key}/60/60/24;
		$first_seen=scalar localtime($ip_earliest_seen_time{$key});
		$last_seen=scalar localtime($ip_latest_seen_time{$key});
		$attacks_recorded = `ls $honey_dir/attacks/$key* |wc -l 2>/dev/null `;
	  	printf(FILE_DATA "%d %s %.2f %s %s\n", $ip_age{$key}, $key, $days,$first_seen, $last_seen, $attacks_recorded);
	  	printf(FILE_FORMATTED "<TR><TD>%s</TD><TD>%.2f</TD><TD>%s</TD><TD>%s</TD><TD><a href=\"/honey/attacks/ip_attacks.shtml#%s\">%d</A></TD></TR>\n", $key, $days,$first_seen, $last_seen, $key, $attacks_recorded);
	}
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close(FILE_DATA);
	close(FILE_FORMATTED);
}

########################################################################
# Make a sorted list of IPs and the attacks they are using.
#

sub show_attacks_of_ips {

	chdir ("$honey_dir/attacks");

	open (FILE_FORMATTED, ">$honey_dir/attacks/ip_attacks.shtml") || die "Can not write to $honey_dir/attacks/ip_attacks.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis IP Attackers</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis IP Attacks</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated hourly.\n");
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
	my @sorted = map  { $_->[0] }
             	sort { $a->[1] <=> $b->[1] }
             	map  { [$_, int sprintf("%03.f%03.f%03.f%03.f", split(/\.+/, $_))] }
             	@ip_array;
	
	foreach (@sorted){
		#print "$_\n";;
		print (FILE_FORMATTED "<HR>\n");
		print (FILE_FORMATTED "<a name=\"$_\"></a>\n");
		print (FILE_FORMATTED "<B>$_</B>\n");
		#$line= system ("grep $_ sum2.data");
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
			#print (FILE_FORMATTED "<BR>$lines lines, <a href=\"dict-$checksum.txt\">dict-$checksum.txt</a> From: $ip_1.$ip_2.$ip_3.$ip_4 To: $host Attack #: $attack_number on $year/$month/$day $hour:$minute:$second\n");
			print (FILE_FORMATTED "<BR>$lines lines, <a href=\"dict-$checksum.txt\">dict-$checksum.txt</a> <!-- From: $ip_1.$ip_2.$ip_3.$ip_4--> To: $host Attack #: $attack_number started on $year/$month/$day $hour:$minute:$second\n");
		}
		close (GREP);
	}
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);
}


#############################################################################3
#
# Make the dictionary webpage
#
sub create_dict_webpage {
	if ($DEBUG){print "DEBUG Making dict webpage now\n";}
	open (FILE_FORMATTED_TEMP, ">/tmp/dictionaries.temp") || die "Can not write to $honey_dir/dictionaries.temp\n";
	open (FILE_FORMATTED, ">$honey_dir/dictionaries.shtml") || die "Can not write to $honey_dir/dictionaries.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Dictionaries</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Dictionaries</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated hourly.\n");
	print (FILE_FORMATTED "Last updated on $DATE\n");
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR><TH>Number Of<BR>Times Used</TH><TH>Number of <BR>Entries</TH><TH>Checksum</TH><TH>Dictionary</TH><TH>First Seen</TH><TH>Last Seen</TH></TR>\n");
	chdir ("$honey_dir/attacks");
	
	open (PIPE, "/bin/ls dict-* |") || die "can not open pipe to cleanup files\n";
	while (<PIPE>){
		chomp;
		if (/\.txt\.wc/){next;}
		$dictionary_file=$_;

		$WC=`/usr/bin/wc -l $_ `;
		($WC,$tmp)=split(/ /,$WC);
		$SUM=`md5sum $_ `;
		($SUM,$tmp)=split(/ /,$SUM);
		$WC = $WC;
		$TIMES_USED=`grep $SUM sum2.data|grep -v dict- |wc -l |awk '{print \$1}'`;
		chomp $TIMES_USED;
		chomp $WC;

		$first_seen_epoch=0;
		$last_seen_epoch=0;
		$COUNT=0;
		open (SUM_FILE, "sum2.data") || die "Can not open sum2.data, this is bad\n";
		while (<SUM_FILE>){
			chomp;
			if (/dict-/){next;}
			if (/$SUM/){
				$COUNT++;
				($tmp,$date_string)=split(/-/,$_);
				#$year=2015;
				#2.16.16.38.53
			($year,$month,$day,$hour,$minute,$second)=split(/\./,$date_string);

			$epoch=timelocal($second,$minute,$hour,$day,$month-1,$year);
			if ($first_seen_epoch == 0){$first_seen_epoch=$epoch};
			if ($epoch > $last_seen_epoch ){$last_seen_epoch=$epoch};
			if ($epoch < $first_seen_epoch ){$first_seen_epoch=$epoch};
			}
		}
		close (SUM_FILE);
		$FIRST_SEEN=scalar localtime($first_seen_epoch);
		$LAST_SEEN=scalar localtime($last_seen_epoch);

		print (FILE_FORMATTED_TEMP "$TIMES_USED|$WC|$SUM|$dictionary_file|$FIRST_SEEN|$LAST_SEEN\n");
	}
	close (PIPE);
	close (FILE_FORMATTED_TEMP);

	system ("sort -nr /tmp/dictionaries.temp > /tmp/dictionaries.temp.sorted");
	open (FILE, "/tmp/dictionaries.temp.sorted");
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

	#
	# Now we sort by size of dictionary
	#
	open (FILE_FORMATTED, ">$honey_dir/dictionaries-k5.shtml") || die "Can not write to $honey_dir/dictionaries-k5.shtml\n";
	print (FILE_FORMATTED "<HTML>\n");
	print (FILE_FORMATTED "<HEAD>\n");
	print (FILE_FORMATTED "<TITLE>LongTail Log Analysis Dictionaries</TITLE>\n");
	print (FILE_FORMATTED "</HEAD>\n");
	print (FILE_FORMATTED "<BODY bgcolor=#00f0FF>\n");
	print (FILE_FORMATTED "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> \n");
	print (FILE_FORMATTED "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE_FORMATTED "<H1>LongTail Log Analysis Dictionaries</H1>\n");
	print (FILE_FORMATTED "<P>This page is updated hourly.\n");
	print (FILE_FORMATTED "Last updated on $DATE\n");
	print (FILE_FORMATTED "<TABLE border=1>\n");
	print (FILE_FORMATTED "<TR><TH>Number Of<BR>Times Used</TH><TH>Number of <BR>Entries</TH><TH>Checksum</TH><TH>Dictionary</TH><TH>First Seen</TH><TH>Last Seen</TH></TR>\n");
	close (FILE_FORMATTED);

	system ("grep '<TR>' $honey_dir/dictionaries.shtml   |sort -nrk5  >> $honey_dir/dictionaries-k5.shtml");

	open (FILE_FORMATTED, ">>$honey_dir/dictionaries-k5.shtml") || die "Can not write to $honey_dir/dictionaries-k5.shtml\n";
	print (FILE_FORMATTED "</TABLE>\n");
	print (FILE_FORMATTED "</BODY>\n");
	print (FILE_FORMATTED "</HTML>\n");
	close (FILE_FORMATTED);

}

#############################################################################3
#
# Mainline of code
#
#
$TMP=`date`;
print "Started at $TMP\n";
&init;
&cleanup_old_files;
&create_attack_logs;
&analyze;
&show_lifetime_of_ips;
&show_attacks_of_ips;
&create_dict_webpage;
$TMP=`date`;
print "Done at $TMP\n";
#
# Get rid of temp files
unlink ("/tmp/dictionaries.temp.sorted");
unlink ("/tmp/dictionaries.temp");
unlink ("/tmp/tmp.data");

