#!/usr/bin/perl
############################################################################
# adds commas to numbers so they are readable
# 
sub commify {
  my ( $sign, $int, $frac ) = ( $_[0] =~ /^([+-]?)(\d*)(.*)/ );
  my $commified = (
  reverse scalar join ',',
  unpack '(A3)*',
  scalar reverse $int
  );
  return $sign . $commified . $frac;
}

sub init {
	$MIDNIGHT=0;
	$HOUR=`date +%h`;
	chomp $HOUR;
	if ( ! -e "/var/www/html/honey/attacks/sum2.data"){
		print "Can not find /var/www/html/honey/attacks/sum2.data, exiting now\n";
		exit;
	}
	open (FILE, "/usr/local/etc/translate_country_codes");
	while (<FILE>){
		chomp;
		($code,$country)=split(/ /,$_,2);
		$country_code{$code}=$country;
	}

#148.100.100.1 US
#148.100.100.112 US
	close (FILE);
	open (FILE, "tail -20000 /usr/local/etc/ip-to-country|");
	while (<FILE>){
		chomp;
		($ip,$country)=split(/ /,$_,2);
		($ip1,$ip2,$ip3,$ip4)=split(/\./,$ip);
		$country= lc($country);
		$ip="$ip1.$ip2.$ip3";
		$ip_address{$ip}=$country;
	}
	close (FILE);

}

sub pass_1 { 	
	$total=0;
	if ( -e "/var/www/html/honey/current-ip-addresses.txt" ){
		open (FILE, "/var/www/html/honey/current-ip-addresses.txt" );
		while (<FILE>){
			if (/\#/){next;}
			$_ =~ s/^ +//;
			($count,$ip)=split(/ /,$_);
			$total += $count;
			if (/43.255.191./){$sshpsycho+=$count;}
			if (/43.255.190./){$sshpsycho+=$count;}
			if (/103.41.124./){$sshpsycho+=$count;}
			if (/103.41.125/){$sshpsycho+=$count;}
		}
		close (FILE);
	
		$percentage = $sshpsycho/$total;
		$percentage *= 100;
		$percentage = sprintf("%.2f",$percentage);
	
		$total = &commify($total);
		$sshpsycho=&commify($sshpsycho);
		$percentage=&commify($percentage);
		print "<H3>SSHPsycho Numbers For Today</H3>\n";
		print "<p>Total attacks so far today:  $total\n";
		print "<p>Total SSHPsycho attacks so far today: $sshpsycho\n";
		print "<P>Percent of all attacks today that were from SSHPsycho: $percentage\n";
	}
}

sub pass_1b { 	
	$total=0;
	if ( -e "/var/www/html/honey/current-ip-addresses.txt" ){
		open (FILE, "/var/www/html/honey/current-ip-addresses.txt" );
		while (<FILE>){
			if (/\#/){next;}
			$_ =~ s/^ +//;
			($count,$ip)=split(/ /,$_);
			$total += $count;
			if (/43.229.53./){$sshpsycho2+=$count;}
			if (/43.229.52./){$sshpsycho2+=$count;}
			if (/43.255.188./){$sshpsycho2+=$count;}
			if (/43.255.189./){$sshpsycho2+=$count;}
		}
		close (FILE);
	
		$percentage = $sshpsycho2/$total;
		$percentage *= 100;
		$percentage = sprintf("%.2f",$percentage);
	
		$total = &commify($total);
		$sshpsycho2=&commify($sshpsycho2);
		$percentage=&commify($percentage);
		print "<H3>SSHPsycho-2 Numbers For Today</H3>\n";
		print "<p>Total attacks so far today:  $total\n";
		print "<p>Total SSHPsycho-2 attacks so far today: $sshpsycho2\n";
		print "<P>Percent of all attacks today that were from SSHPsycho-2: $percentage\n";
	}
}

sub pass_2 {
	chdir ("/var/www/html/honey/attacks");
	`cat /usr/local/etc/LongTail_sshPsycho_IP_addresses /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses >/tmp/sshPsycho.$$`;
	`cat /var/www/html/honey/attacks/sum2.data |grep -F -f /tmp/sshPsycho.$$ |awk '{printf ("grep \%s /var/www/html/honey/attacks/sum2.data\\n",\$1)}' |sort -u >/tmp/sshpsycho.$$`;
	
	system("sh /tmp/sshpsycho.$$ | grep  -F -vf /usr/local/etc/LongTail_sshPsycho_IP_addresses  | grep  -F -vf /usr/local/etc/LongTail_sshPsycho_2_IP_addresses | grep -F -vf /usr/local/etc/LongTail_sshPsycho_2_IP_addresses > /tmp/sshpsycho.$$-2");
	
	print "<H3>Friends of SSHPsycho</H3>\n";
	print "These IP Addresses are using the exact same attacks as SSHPsycho or as other friends of sshPsycho\n";
	# Attack Pattern
#print "<TABLE><TH>Number Of Lines<BR>In Attack Pattern</TH><TH>Checksum Of Attack Pattern</TH><TH>IP Address</TH><TH>Country</TH><TH>Host<BR>Attacked</TH><TH>Date Of Attack</TH></TR>\n";

	open (FILE, "/tmp/sshpsycho.$$-2");
	open (OUTPUT_FILE, "> /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp");
	while (<FILE>){
		chomp;
		($checksum, $filename)=split (/\s+/,$_);
		open (FILE2, "/var/www/html/honey/attacks/dict-$checksum.txt.wc");
		while (<FILE2>){
			chomp;
			$wc=$_;
		}
		close (FILE2);

		($ip1,$ip2,$ip3,$ip4,$host,$attacknumber,$date)=split(/\.|-/,$filename,7);
		($year,$month,$day,$hour,$minute,$second)=split (/\./,$date);
		$tmp="$ip1.$ip2.$ip3";
		if ( $ip_address{$tmp} ) {
			$country=$ip_address{$tmp};
		}
		else {
			$country=`/usr/local/etc/whois.pl $ip1.$ip2.$ip3.$ip4`;
		}
		chomp $country;
		$country=~ s/country: //;
		$country = lc ($country);
		$country = lc ($country);
		$country=$country_code{$country};

		if ($wc >9 ){
			#print "<TR><TD>$wc</TD><TD> $checksum</TD><TD>$ip1.$ip2.$ip3.$ip4</TD><TD>$country</TD><TD>$host</TD><TD>$year-$month-$day $hour:$minute</TD>\n";
			print "$ip1.$ip2.$ip3.$ip4 ";
			print (OUTPUT_FILE "$ip1.$ip2.$ip3.$ip4\n");
		}
	}
	close (FILE);
	close (OUTPUT_FILE);
	`cat /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses >> /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp`;
	`sort -u /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp > /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses`;
#	`echo 43.229.52 >> /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses`;
#	print "</TABLE>\n";
	
	unlink ("/tmp/sshpsycho.$$");
	unlink ("/tmp/sshpsycho.$$-2");
}

sub pass_3{ 	
	#
	# Third level analysis, look for attacks not already in sshPsycho or sssPsychoFriends
	# but that have a commanality (in this case, use wubao or jiamima in their attack string
	chdir ("/var/www/html/honey/attacks");
	`ls |grep -v dict|grep -v sshpsy|\
		grep -F -vf /usr/local/etc/LongTail_sshPsycho_IP_addresses |\
		grep -F -vf /usr/local/etc/LongTail_sshPsycho_2_IP_addresses |\
		grep -F -vf /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses |\
		xargs egrep -l wubao\\|jiamima  |\
		awk -F. '{print \$1, \$2, \$3, \$4}' |sed 's/ /./g' |\
		sort |uniq -c |sort -nr > /tmp/sshpsycho.$$`;

	`ls 222.186.21.*  |awk -F. '{print \$1, \$2, \$3, \$4}' |sed 's/ /./g' |sort |uniq -c |sort -nr >> /tmp/sshpsycho.$$`;
	`ls 222.186.134.*  |awk -F. '{print \$1, \$2, \$3, \$4}' |sed 's/ /./g' |sort |uniq -c |sort -nr >> /tmp/sshpsycho.$$`;
	
	$total=0;
	print "<H3>Attacks with a significant level of commonality with sshPsycho attacks</H3>\n";
	print "<TABLE><TH>IP ADDRESS</TH><TH>Country</TH><TH>Number of Attack Patterns<BR>With Significant \"Match\"</TH><TH>Number Of<BR>Attacks</TH></TR>\n";
	open (FILE, "/tmp/sshpsycho.$$");
	open (OUTPUT_FILE, "> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp");
	while (<FILE>){
		chomp;
		$_ =~ s/^ *//;
		($count,$ip)=split(/ /,$_);
		$wc = `cat $ip.* |wc -l`;
		chomp $wc;

		($ip1,$ip2,$ip3,$ip4)=split(/\./,$ip);
		$tmp="$ip1.$ip2.$ip3";
		if ( $ip_address{$tmp} ) {
			$country=$ip_address{$tmp};
		}
		else {
			$country=`/usr/local/etc/whois.pl $ip1.$ip2.$ip3.$ip4`;
		}
		#$country=`/usr/local/etc/whois.pl $ip`;

		chomp $country;
		$country=~ s/country: //;
		$country = lc ($country);
		$country = lc ($country);
		$country=$country_code{$country};

		print "<TR><TD>$ip</TD><TD>$country</TD><TD>$count</TD><TD>$wc</TD></TR>\n";
		if ($count > 1){
			print (OUTPUT_FILE "$ip\n");
		}
		$total += $wc;
	}
	close (FILE);
	`cat /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses >> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp`;
	`sort -u /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp |grep -F -v 222.186.21 |grep -F -v 222.186.134 > /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses`;
	`echo 222.186.21 >> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses`;
	`echo 222.186.134 >> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses`;
	print "</TABLE>\n";
	print "<P>Total number of attacks from hosts with attacks similar to sshPsycho: $total\n";
	unlink ("/tmp/sshpsycho.$$");
}

sub pass_4{
# sshpsycho original hosts are offline, I'll just run
# this once a week to catch any imported data
	if ( $HOUR == $MIDNIGHT){
		$day_of_week=`date +%a`;
		chomp $day_of_week;
		if ($day_of_week eq "Sun"){
			`cat 103.41.124* 103.41.125* 43.255.190* 43.255.191* |sort |uniq -c |sort -n > /var/www/html/honey/attacks/sshpsycho_attacks.txt`
		}
	}
}

#Cleanup the files and remove IPs from associates once they are in friends
sub pass_5 {
	open (FILE, "/usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses");
	while (<FILE>){
	chomp;
	$ip_array{$_}=1;
	}
	close (FILE);

	open (FILE, "/usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses");
	open (OUTPUT, ">/tmp/LongTail_associates");
	while (<FILE>){
	chomp;
	if (! $ip_array{$_}){print (OUTPUT "$_\n");}
	}
	close (FILE);
	close (OUTPUT);
	unlink ("/usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses");
	system ("cp /tmp/LongTail_associates /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses");
	unlink ("/tmp/LongTail_associates");
}

sub pass_6 {
}

print "\n";
print "<P>sshPsycho accounts tried\n";
print "<PRE>\n";
system ("for ip in `cat /usr/local/etc/LongTail_sshPsycho_IP_addresses ` ;do cat /var/www/html/honey/attacks/\$ip.*; done | awk '{print \$1}'| sort |uniq -c");
print "</PRE>\n";

print "\n";
print "<P>sshPsycho_2 accounts tried\n";
print "<PRE>\n";
system ("for ip in `cat /usr/local/etc/LongTail_sshPsycho_2_IP_addresses ` ;do cat /var/www/html/honey/attacks/\$ip.*; done | awk '{print \$1}'| sort |uniq -c");
print "</PRE>\n";

print "\n";
print "<P>sshPsycho friends accounts tried\n";
print "<PRE>\n";
system ("for ip in `cat /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses ` ;do cat /var/www/html/honey/attacks/\$ip.*; done | awk '{print \$1}'| sort |uniq -c");
print "</PRE>\n";

print "\n";
print "<P>sshPsycho associates accounts tried\n";
print "<PRE>\n";
system ("for ip in `cat /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses ` ;do cat /var/www/html/honey/attacks/\$ip.*; done | awk '{print \$1}'| sort |uniq -c");
print "</PRE>\n";


&init;
#$date=`date`;print "DEBUG pass1 at $date \n";
&pass_1;
&pass_1b;
#$date=`date`;print "DEBUG pass2 at $date \n";
&pass_2;
#$date=`date`;print "DEBUG pass3 at $date \n";
&pass_3;

#$date=`date`;print "DEBUG pass4 at $date \n";
&pass_4;
#$date=`date`;print "DEBUG pass5 at $date \n";
&pass_5; 
#$date=`date`;print "DEBUG done at $date\n";
&pass_6; # accounts
if ( -e "/tmp/sshpsycho.$$"){ unlink ("/tmp/sshpsycho.$$");}
if ( -e "/tmp/sshpsycho.$$-2"){unlink ("/tmp/sshpsycho.$$-2");}
if ( -e "/tmp/sshPsycho.$$"){ unlink ("/tmp/sshPsycho.$$");}
if ( -e "/tmp/sshPsycho.$$-2"){unlink ("/tmp/sshPsycho.$$-2");}
if ( -e "/usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp"){unlink ("/usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp");}
if ( -e "/usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp"){unlink ("/usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp");}

