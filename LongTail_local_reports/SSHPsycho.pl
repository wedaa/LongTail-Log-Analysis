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

sub pass_2 {
	chdir ("/var/www/html/honey/attacks");
	`cat /usr/local/etc/LongTail_sshPsycho_IP_addresses /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses >/tmp/sshPsycho.$$`;
	`cat /var/www/html/honey/attacks/sum2.data |egrep -f /tmp/sshPsycho.$$ |awk '{printf ("grep \%s /var/www/html/honey/attacks/sum2.data\\n",\$1)}' |sort -u >/tmp/sshpsycho.$$`;
	
	system("sh /tmp/sshpsycho.$$ | egrep -vf /usr/local/etc/LongTail_sshPsycho_IP_addresses > /tmp/sshpsycho.$$-2");
	
	print "<H3>Friends of SSHPsycho</H3>\n";
	print "These IP Addresses are using the exact same attacks as SSHPsycho or as other friends of sshPsycho\n";
	print "<TABLE><TH>Number Of Lines<BR>In Attack Pattern</TH><TH>Checksum Of Attack Pattern</TH><TH>IP Address</TH><TH>Country</TH><TH>Host<BR>Attacked</TH><TH>Date Of Attack</TH></TR>\n";
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
		$country=`/usr/local/etc/whois.pl $ip1.$ip2.$ip3.$ip4`;
		$country=~ s/country: //;
		$country=`cat /usr/local/etc/translate_country_codes| grep -i ^$country `;
		($trash,$country)=split (/ /,$country);
		chomp $country;
		if ($wc >9 ){
			print "<TR><TD>$wc</TD><TD> $checksum</TD><TD>$ip1.$ip2.$ip3.$ip4</TD><TD>$country</TD><TD>$host</TD><TD>$year-$month-$day $hour:$minute</TD>\n";
			print (OUTPUT_FILE "$ip1.$ip2.$ip3.$ip4\n");
		}
	}
	close (FILE);
	close (OUTPUT_FILE);
	`cat /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses >> /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp`;
	`sort -u /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses.tmp > /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses`;
	`echo 43.229.52 >> /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses`;
	print "</TABLE>\n";
	
	unlink ("/tmp/sshpsycho.$$");
	unlink ("/tmp/sshpsycho.$$-2");
}

sub pass_3{ 	
	#
	# Third level analysis, look for attacks not already in sshPsycho or sssPsychoFriends
	# but that have a commanality (in this case, use wubao or jiamima in their attack string
	chdir ("/var/www/html/honey/attacks");
	`egrep -l wubao\\|jiamima *.*.*.*.* |egrep -vf /usr/local/etc/LongTail_sshPsycho_IP_addresses |egrep -vf /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses |awk -F. '{print \$1, \$2, \$3, \$4}' |sed 's/ /./g' |sort |uniq -c |sort -nr > /tmp/sshpsycho.$$`;
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
		$country=`/usr/local/etc/whois.pl $ip`;
		$country=~ s/country: //;
		$country=`cat /usr/local/etc/translate_country_codes| grep -i ^$country `;
		($trash,$country)=split (/ /,$country);
		chomp $country;
		print "<TR><TD>$ip</TD><TD>$country</TD><TD>$count</TD><TD>$wc</TD></TR>\n";
		if ($count > 1){
			print (OUTPUT_FILE "$ip\n");
		}
		$total += $wc;
	}
	close (FILE);
	`cat /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses >> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp`;
	`sort -u /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses.tmp |grep -v 222.186.21 |grep -v 222.186.134 > /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses`;
	`echo 222.186.21 >> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses`;
	`echo 222.186.134 >> /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses`;
	print "</TABLE>\n";
	print "<P>Total number of attacks from hosts with attacks similar to sshPsycho: $total\n";
	unlink ("/tmp/sshpsycho.$$");
}

sub pass_4{
	if ( $HOUR == $MIDNIGHT){
		`cat 103.41.124* 103.41.125* 43.255.190* 43.255.191* |sort |uniq -c |sort -n > /var/www/html/honey/attacks/sshpsycho_attacks.txt`
	}
}

&pass_1;
&pass_2;
&pass_3;
&pass_4;
