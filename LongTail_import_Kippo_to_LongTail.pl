#!/usr/bin/perl
# You must be in the directory with the kippo logs in it.
#
# You must disable all LongTail jobs in crontab before you run this
#
# After you run this, then run /usr/local/etc/LongTail.sh REBUILD
#
#
#LONGTAIL: 2015-05-22T15:33:56-04:00 shepherd sshd-22[19597]: IP: 222.186.21.223 PassLog: Username: root Password: mtcl
#KIPPO:    2015-05-10 18:05:31-0400 [SSHService ssh-userauth on HoneyPotTransport,16534,58.218.204.52] login attempt [root/skata1] failed

sub init{
	if ( $ARGV[0] ne ""){
		print "$ARGV[0]\n";
		$new_hostname=$ARGV[0];
	}
	else {
		print "You forgot to specify a hostname, use  LongTail_convert_Kippo_to_LongTail.pl <HOSTNAME>\n";
		exit;
	}
	$date_right_now=`date +%Y.%m.%dT%H:%M`;
	chomp $date_right_now;
}

sub pass_1 {
	open (FIND, "find . -type f  |sort |")||die "Can not run find command\n";
	while (<FIND>){
		chomp;
		if (/kippo.log.1$/){next;}
		if (! /kippo.log/){next;}
		print "processing file $_ now\n";;
		$filename=$_;
		open (FILE, $filename) || die "Can not open $filename\n";
		while (<FILE>){
			if (/Sana/){print ;}
			if (/unauthorized login/){next;}
			if (/NEW KEYS/){next;}
			if (/^\t/){next;}
			if (/ \[-\] /){next;}
			if (/failed auth password/){next;}
			if (/starting service ssh-userauth/){next;}
			if (/login attempt/){
#print "DEBUG line is -->$_<--";
				($date,$time,$stuff)=split(/ /,$_,3);
				$time =~ s/00$/:00/;
# This is a hack for Bob M's condensed Kippo Logs
# Eric Wedaa, 2015-06-18
				if (/ \[H,/){
					$stuff =~ s/H,/SSHService ssh-userauth on HoneyPotTransport,/;
				}
				$stuff =~ s/,/ /g;
#print "DEBUG stuff is -->$stuff<--";
				($trash,$trash,$trash,$trash,$trash,$ip,$trash,$trash,$attempt,$trash)=split(/ /,$stuff);
				$ip =~ s/\]//;
				#print "$ip $attempt\n";
				$attempt =~ s/\[//;
				$attempt =~ s/\]//;
				$attempt =~ s/\// Password: /;
				($year,$month,$day)=split(/-/,$date,3);
				if (! -d "/var/www/html/honey/historical/$year/$month/$day"){
					`mkdir -p /var/www/html/honey/historical/$year/$month/$day`;
				}
				if ( -d "/var/www/html/honey/historical/$year/$month/$day"){
					open (OUT, ">>/var/www/html/honey/historical/$year/$month/$day/kippo.data");
					print (OUT "$date"."T"."$time $new_hostname sshd-22[KIPPO]: IP: $ip PassLog: Username: $attempt\n");
					print ("$date"."T"."$time $new_hostname sshd-22[KIPPO]: IP: $ip PassLog: Username: $attempt\n");
					close (OUT);
				}
				else {
					print "X01: This is bad, could not create /var/www/html/honey/historical/$year/$month/$day\n";
					print "Exiting now\n\n";
					exit;
				}
				if (! -d "/var/www/html/honey/$new_hostname/historical/$year/$month/$day"){
					`mkdir -p /var/www/html/honey/$new_hostname/historical/$year/$month/$day`;
				}
				if (! -d "/var/www/html/honey/$new_hostname/historical/$year/$month/$day"){
					print "X02: This is bad, could not create /var/www/html/honey/$new_hostname/historical/$year/$month/$day\n";
					print "Exiting now\n\n";
					exit;
				}
				open (OUT, ">>/var/www/html/honey/$new_hostname/historical/$year/$month/$day/kippo.data");
				print (OUT "$date"."T"."$time $new_hostname sshd-22[KIPPO]: IP: $ip PassLog: Username: $attempt\n");
				close (OUT);
			}
			else {
				($date,$time,$stuff)=split(/ /,$_,3);
				$time =~ s/00$/:00/;
				$_ = "$date"."T"."$time $new_hostname $stuff";
				($year,$month,$day)=split(/-/,$date,3);

				if (! -d "/var/www/html/honey/historical/$year/$month/$day"){
					`mkdir -p /var/www/html/honey/historical/$year/$month/$day`;
				}
				if ( -d "/var/www/html/honey/historical/$year/$month/$day"){
					open (OUT, ">>/var/www/html/honey/historical/$year/$month/$day/kippo.data");
					print (OUT $_ );
					close (OUT);
				}
				else {
					print "x03: This is bad, could not create /var/www/html/honey/historical/$year/$month/$day\n";
					print "Exiting now\n\n";
					exit;
				}


				if (! -d "/var/www/html/honey/$new_hostname/historical/$year/$month/$day"){
					`mkdir -p /var/www/html/honey/$new_hostname/historical/$year/$month/$day`;
				}
				if (! -d "/var/www/html/honey/$new_hostname/historical/$year/$month/$day"){
					print "X04: This is bad, could not create /var/www/html/honey/$new_hostname/historical/$year/$month/$day\n";
					print "Exiting now\n\n";
					exit;
				}
				open (OUT, ">>/var/www/html/honey/$new_hostname/historical/$year/$month/$day/kippo.data");
				print (OUT $_ );
				close (OUT);
			}
		}
		close (FILE);
#	print "sleep 10 now\n";
	#sleep(10);
	}
	close (FIND);
}

sub pass_2 {
	open (FIND, "find /var/www/html/honey/historical -type f -name kippo.data| ")||die "Can not run find command\n";
	while (<FIND>){
		print $_;
		chomp;
		$filename=$_;
		$existing_data=$_;
		$existing_data =~ s/kippo.data/current-raw-data.gz/;
		$filename_new= $existing_data;
		$filename_new=~ s/.gz//;
		`zcat $existing_data >$filename_new`;
		`mv $existing_data $existing_data.$date_right_now`;
		`cat  $filename  |sort  >> $filename_new`;
		`gzip $filename_new`;
		#`ls -l $filename_new $existing_data.backup`;
		`mv $filename $filename.$date_right_now`;
		 
	}
	close (FIND);
}

&init;
&pass_1;
&pass_2;

print "\n\n";
print "To finish importing your data, please perform the following actions:\n";
print "  1) Disable LongTail in your crontab file\n";
print "  2) run /usr/local/etc/LongTail.sh REBUILD\n";
print "  3) Re-enable LongTail in your crontab file\n";
print "Charts will be updated at midnight.\n";
