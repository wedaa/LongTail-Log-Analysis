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

chdir ("/var/www/html/honey/attacks");
# This works but is slow # `md5sum  43.255.191* 43.255.190* 103.41.124.* 103.41.125.*|awk '{printf ("grep \%s /var/www/html/honey/attacks/sum2.data\\n",\$1)}' |sort -u >/tmp/sshpsycho.$$`;
#`cat /var/www/html/honey/attacks/sum2.data |egrep  43.255.191\\|43.255.190\\|103.41.124\\|103.41.125 |awk '{printf ("grep \%s /var/www/html/honey/attacks/sum2.data\\n",\$1)}' |sort -u >/tmp/sshpsycho.$$`;
`cat /var/www/html/honey/attacks/sum2.data |egrep -f /usr/local/etc/LongTail_sshPsycho_IP_addresses |awk '{printf ("grep \%s /var/www/html/honey/attacks/sum2.data\\n",\$1)}' |sort -u >/tmp/sshpsycho.$$`;

system("sh /tmp/sshpsycho.$$ | egrep -vf /usr/local/etc/LongTail_sshPsycho_IP_addresses > /tmp/sshpsycho.$$-2");

print "<H3>Friends of SSHPsycho</H3>\n";
print "These IP Addresses are using the exact same attacks as SSHPsycho\n";
print "<TABLE><TH>Number Of Lines<BR>In Attack Pattern</TH><TH>Checksum Of Attack Pattern</TH><TH>IP Address</TH><TH>Country</TH><TH>Host<BR>Attacked</TH><TH>Date Of Attack</TH></TR>\n";
open (FILE, "/tmp/sshpsycho.$$-2");
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
	}
}
close (FILE);
print "</TABLE>\n";

unlink ("/tmp/sshpsycho.$$");
unlink ("/tmp/sshpsycho.$$-2");

`egrep 103.41.12\\|43.255.19 sum2.data  |sort |awk '{print $1}' |uniq -c |sort -n |awk '{print $1}' |uniq -c > /tmp/sshpsycho.$$`;
#open (FILE, "/tmp/sshpsycho.$$");
#print "<TABLE>\n";
#print "<TR><TH>Number of Attacks</TH><TH>That were only used this many times</TH></TR>\n";
#while (<FILE>){
#	chomp;
#	$_ =~ s/\s+//;
#print "DEBUG $_\n";
#	($number_of_attacks, $times_used)=split(/ /,$_);
#	print "<TR><TD>$number_of_attacks</TD><TD>$times_used</TD></TR>\n";
#}
#close (FILE);
#print "</TABLE>\n";
unlink ("/tmp/sshpsycho.$$");
