#!/usr/bin/perl
# Crontab entry is
# 0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/etc/LongTail_dashboard.pl >> /tmp/LongTail_dashboard.out

$HOUR=`date +%H`;
chomp $HOUR;
$MINUTE=`date +%M`;
chomp $MINUTE;
$filedate=`date +%Y-%m-%d --date="1 day ago"`;
#$filedate=`date +%Y-%m-%d`;
chomp $filedate;

#################################################################################
#
# Basically run this stuff right after midnight
#
if (($HOUR <1) && ($MINUTE<5)){
#if (($HOUR <12) && ($MINUTE<15)){
	`cp /var/www/html/honey/dashboard_usernames.png /var/www/html/honey/dashboard/dashboard_usernames-$filedate.png`;
	`cp /var/www/html/honey/dashboard_passwords.png /var/www/html/honey/dashboard/dashboard_passwords-$filedate.png`;
	`cp /var/www/html/honey/dashboard_ips.png /var/www/html/honey/dashboard/dashboard_ips-$filedate.png`;
	`cp /var/www/html/honey/dashboard_number_of_attacks.png /var/www/html/honey/dashboard/dashboard_number_of_attacks-$filedate.png`;
	unlink "/var/www/html/honey/dashboard_usernames.data";
	unlink "/var/www/html/honey/dashboard_passwords.data";
	unlink "/var/www/html/honey/dashboard_ips.data";
	unlink "/var/www/html/honey/dashboard_number_of_attacks.data";

	open ("FILE", "/var/www/html/honey/dashboard/count") || die "Can not read to count file\n";
	while (<FILE>){
		chomp;
		$count=$_;
	}
	close (FILE);
	$count_plus_one =$count+1;
	
	#
	# Edit the last file to point to the not yet eisting file
	#
	
	open (INPUT, "/var/www/html/honey/dashboard/dashboard-$count.shtml");
	open (OUTPUT, ">>/tmp/LongTail.$$.2");
	while (<INPUT>){
		if (/meta http-equiv=/){
			print (OUTPUT "<meta http-equiv=\"refresh\" content=\"1 url=/honey/dashboard/dashboard-$count_plus_one.shtml\">\n");
		}
		else {
			print (OUTPUT "$_");
		}
	}
	close (INPUT);
	close (OUTPUT);
	system ("cp /tmp/LongTail.$$.2 /var/www/html/honey/dashboard/dashboard-$count.shtml");
	unlink ("/tmp/LongTail.$$.2");
	
	open (INPUT, "/var/www/html/honey/dashboard/dashboard-$count.shtml");
	open (OUTPUT, ">>/tmp/LongTail.$$.2");
	while (<INPUT>){
		if (/meta http-equiv=/){
			print (OUTPUT "<meta http-equiv=\"refresh\" content=\"1 url=/honey/dashboard/index.shtml\">\n");
		}
		else {
			$_ =~ s/\d\d\d\d-\d\d-\d\d/$filedate/;
			print (OUTPUT "$_");
		}
	}
	close (INPUT);
	close (OUTPUT);
	system ("cp /tmp/LongTail.$$.2 /var/www/html/honey/dashboard/dashboard-$count_plus_one.shtml");
	unlink ("/tmp/LongTail.$$.2");

	open ("FILE", ">/var/www/html/honey/dashboard/count") || die "Can not write to count file\n";
	print (FILE "$count_plus_one\n");
	close (FILE);
}

$DATE=`date +"%Y-%m-%d"`;
$TIME=`date +%k:%M`;
$TIME =~ s/ //g;
chomp $DATE;
chomp $TIME;
open (MESSAGES, "/var/log/messages")|| die "can not open /var/log/messages\n";
while (<MESSAGES>) {
	if (/$DATE/){
		if (/IP:/){
			chomp;
			$number_of_attacks++;

			$username=$_;
			$username =~ s/^..*Username: //;
			$username =~ s/ Pass..*$//;
			$usernames_seen{$username}++;

			$password=$_;
			$password =~ s/^..*Password: //;
			$passwords_seen{$password}++;

			$ip=$_;
			$ip =~ s/^..*IP: //;
			$ip =~ s/ Pass..*$//;
			$ips_seen{$ip}++;
		}
	}
}
close (MESSAGES);

open ("FILE", ">>/var/www/html/honey/dashboard_number_of_attacks.data") || die "Can not write to dashboard_number_of_attacks.data\n";
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$number_of_attacks $TIME\n");}else{print (FILE "$number_of_attacks \n");}
close (FILE);

open ("FILE", ">>/var/www/html/honey/dashboard_usernames.data") || die "Can not write to dashboard_usernames.data\n";
$arrSize = keys %usernames_seen;
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$arrSize $TIME\n");}else{print (FILE "$arrSize \n");}
close (FILE);


open ("FILE", ">>/var/www/html/honey/dashboard_passwords.data") || die "Can not write to dashboard_passwords.data\n";
$arrSize = keys %passwords_seen;
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$arrSize $TIME\n");}else{print (FILE "$arrSize \n");}
close (FILE);

open ("FILE", ">>/var/www/html/honey/dashboard_ips.data") || die "Can not write to dashboard_ips.data\n";
$arrSize = keys %ips_seen;
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$arrSize $TIME\n");}else{print (FILE "$arrSize \n");}

close (FILE);

$wc=`cat /var/www/html/honey/dashboard_usernames.data |wc -l`;
chomp $wc;
$lines_needed=288-$wc;
`cat /var/www/html/honey/dashboard_usernames.data > /var/www/html/honey/dashboard_usernames.tmp`;
`cat /var/www/html/honey/dashboard_passwords.data > /var/www/html/honey/dashboard_passwords.tmp`;
`cat /var/www/html/honey/dashboard_ips.data > /var/www/html/honey/dashboard_ips.tmp`;
`cat /var/www/html/honey/dashboard_number_of_attacks.data > /var/www/html/honey/dashboard_number_of_attacks.tmp`;



open (FILE, ">> /var/www/html/honey/dashboard_number_of_attacks.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);

open (FILE, ">> /var/www/html/honey/dashboard_ips.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);

open (FILE, ">> /var/www/html/honey/dashboard_usernames.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);
open (FILE, ">> /var/www/html/honey/dashboard_passwords.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);

open (FILE, "/var/www/html/honey/statistics.shtml");
while (<FILE>){
	if (/Last\ Month/){
		chomp;
		$_ =~ s/ //g;
		$_ =~ s/<\/TD><TD>/|/g;
		$_ =~ s/,//g;
		($trash,$days,$total,$average,$std_dev,$median,$max,$min)=split (/\|/,$_);
		last;
	}
}
close (FILE);
`php /usr/local/etc/LongTail_make_dashboard_graph.php /var/www/html/honey/dashboard_number_of_attacks.tmp "Number Of Attacks $DATE $TIME" "" "" "wide" $min $max $average> /var/www/html/honey/dashboard_number_of_attacks.png`;

open (FILE, "/var/www/html/honey/more_statistics.shtml");
$found=0;
while (<FILE>){
	if (/IP Address Count/){$found=1;}
	if (($found ==1 ) && (/Last\ Month/)){
		chomp;
		$_ =~ s/ //g;
		$_ =~ s/<\/TD><TD>/|/g;
		$_ =~ s/,//g;
		($trash,$days,$total,$average,$std_dev,$median,$max,$min)=split (/\|/,$_);
		last;
	}
}
close (FILE);
`php /usr/local/etc/LongTail_make_dashboard_graph.php /var/www/html/honey/dashboard_ips.tmp "Unique IP Count $DATE $TIME" "" "" "wide" $min $max $average > /var/www/html/honey/dashboard_ips.png`;

open (FILE, "/var/www/html/honey/more_statistics.shtml");
$found=0;
while (<FILE>){
	if (/Username Count/){$found=1;}
	if (($found ==1 ) && (/This\ Month/)){
		chomp;
		$_ =~ s/ //g;
		$_ =~ s/<\/TD><TD>/|/g;
		$_ =~ s/,//g;
		($trash,$days,$total,$average,$std_dev,$median,$max,$min)=split (/\|/,$_);
		last;
	}
}
close (FILE);
`php /usr/local/etc/LongTail_make_dashboard_graph.php /var/www/html/honey/dashboard_usernames.tmp "Unique Username Count $DATE $TIME" "" "" "wide" $min $max $average > /var/www/html/honey/dashboard_usernames.png`;


open (FILE, "/var/www/html/honey/more_statistics.shtml");
$found=0;
while (<FILE>){
	if (/Password Count/){$found=1;}
	if (($found ==1 ) && (/This\ Month/)){
		chomp;
		$_ =~ s/ //g;
		$_ =~ s/<\/TD><TD>/|/g;
		$_ =~ s/,//g;
		($trash,$days,$total,$average,$std_dev,$median,$max,$min)=split (/\|/,$_);
		last;
	}
}
close (FILE);
`php /usr/local/etc/LongTail_make_dashboard_graph.php /var/www/html/honey/dashboard_passwords.tmp "Unique Password Count $DATE $TIME" "" "" "wide" $min $max $average > /var/www/html/honey/dashboard_passwords.png`;
