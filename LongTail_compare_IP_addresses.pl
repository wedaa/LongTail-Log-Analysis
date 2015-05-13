#!/usr/bin/perl

sub init {
	$DATE=`date +%Y-%m-%d`;
	chomp $DATE;
	open (FILE, "/usr/local/etc/translate_country_codes");
	while (<FILE>){
		chomp;
		($code,$country)=split(/ /,$_,2);
		$code =~ tr/a-z/A-Z/;
		$country_code{$code}=$country;
	}
	close (FILE);
}

sub really_get_blacklists{
		chdir ("/var/www/html/honey/black_lists");
		`wget https://www.openbl.org/lists/base_all_ssh-only.txt.gz`;
		`wget https://www.openbl.org/lists/base_90days.txt.gz`;
		`gunzip -f base_90days.txt.gz`;
		`gunzip -f base_all_ssh-only.txt.gz`;
		
		`wget http://lists.blocklist.de/lists/ssh.txt`;
		`cp ssh.txt ssh.txt.$DATE`;
		`rm *gz`;
}

sub get_blacklists{
	$HOUR=`date +%H`;
	chomp $HOUR;
	$MINUTE=`date +%M`;
	chomp $MINUTE;
	if ( ($HOUR<1) &&($MINUTE<55)){
		print "Getting blacklists now\n";
		if ( ! -d "/var/www/html/honey/black_lists"){
			print "\n\nCan not find /var/www/html/honey/black_lists directory, exiting now\n";
			print "\n\nYou need to manually run mkdir /var/www/html/honey/black_lists to create it.\n";
			print "\n\n\n\n\n\n";
			exit;
		}
		&really_get_blacklists;
	}
	if ( ! -e "/var/www/html/honey/black_lists/ssh.txt.$DATE"){&really_get_blacklists;}
	if ( ! -e "/var/www/html/honey/black_lists/base_90days.txt"){&really_get_blacklists;}
	if ( ! -e "/var/www/html/honey/black_lists/base_all_ssh-only.txt"){&really_get_blacklists;}
}

sub load_local_ips{
	$local_ips_count=0;
	undef $ip_list;
	chdir ("/var/www/html/honey");
	open (FILE, "current-ip-addresses.txt");
	while (<FILE>){
		chomp;
		if (/\#/){next;}
		($trash,$count, $ip)=split(/\s+/,$_);
		$ip_list{"$ip"}=1;
		$local_ips_count++;
	}
	close (FILE);
}

sub compare_lists {
	&load_local_ips;
	open (FILE, "/var/www/html/honey/black_lists/$_[0]") || warn "can not open $_[0]\n";;
	$list_count=0;
	$match_list=0;
	while (<FILE>){
		$list_count++;
		chomp;
		if (/\#/){next;}
		if ($ip_list{"$_"} >0){$match_list ++; $ip_list{"$_"}=0;}
	}
	close (FILE);
	print "<TD>$list_count</TD>";
	if ( $local_ips_count > 0){
		$percentage=$match_list/$local_ips_count*100;
	}
	else {
		$percentage=0;
	}
	$percentage=sprintf("%.2f",$percentage);

	print "<TD>$match_list / $percentage\%\n";
	print "<TD>\n";
	foreach $ip (keys %ip_list) {
		if ($ip_list{$ip} >0){
			print "<BR>";
			print "<a href=\"/honey/attacks/ip_attacks.shtml#$ip\">$ip</A>\n";
			open (WHOIS, "/usr/local/etc/whois.pl $ip|");
			while (<WHOIS>){
				chomp;
				$_ =~ s/country://;
				$_ =~ s/ //g;
				$country=$_;
				$country= $country_code{$country};
			}
			close (WHOIS);
			print "$country";
		}
	} 
	print "</TD></TR>\n";
 
}

&init;
&get_blacklists;
&load_local_ips;
print "<HR>\n";
print "<P>Current IP address count is $local_ips_count\n";
print "<TABLE border=3>\n";
print "<TR><TH>File Name</TH><TH>Blacklist Provider</TH><TH>Size of<BR>Blacklist</TH><TH>Number of<BR>Matches</TH><TH>IP Addresses<BR>Not In Blacklist</TH></TR>\n";
print "<TR><TD>ssh.txt </TD><TD><A href=\"http://lists.blocklist.de/\">http://lists.blocklist.de/</A></TD>\n";
&compare_lists ("ssh.txt.$DATE") ;


print "<TR><TD>base_90days.txt </TD><TD> <A href=\"https://www.openbl.org/\">https://www.openbl.org/</A></TD>\n";
&compare_lists ("base_90days.txt") ;


print "<TR><TD>base_all_ssh-only.txt </TD><TD> <A href=\"https://www.openbl.org/ \">https://www.openbl.org/</A></TD>\n";
&compare_lists ("base_all_ssh-only.txt") ;

print "</TABLE>\n";
