#!/usr/bin/perl
#
# No error checking, I assume the argument is good, and that
# the file is good. Maybe later.
#
# All this does is return the line "Country: <country-of-the-ip-address>
#
# Usage : whois.perl <IPV4-address>
open (FILE, "/usr/local/etc/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
while (<FILE>){
	#print "DEBUG $_";
	chomp;
	($ip_address,$file_country)=split (/\s+/,$_,2);
	#$ip_table{$ip_address}=$file_country;
	$ip_table{"$ip_address"}=$file_country;
	#print "DEBUG-ip_address is $ip_address, country is $file_country\n";
	#print "DEBUG-$ip_table{$ip_address}\n";
}
close (FILE);
#print "DEBUG-ARGV[0] is $ARGV[0]\n";
$ip=$ARGV[0];

if ($ip_table{$ip}){ 
	#print "in the file\n";
	#print "country: $ip_table{$ip}\n";
	$tmp=$ip_table{$ip};
	print "country: $tmp\n";
	#print "DEBUG-Found ip in stored ip tables:country is $tmp\n";
}
else {
	#print "Looking it up\n";
	$found_country=1;
	#print "DEBUG IP is $ARGV[0]\n";
	open (PIPE, "whois $ARGV[0]|") || die "Can not open whois command\n";
	while (<PIPE>){
		#print "DEBUG $_";
		# Sometimes whois lookups for some IPs do not return a Country Code:-(
		# This is a hack to force a country code
		if ((/com\.tw/i)||(/hinet-net/i)){
			$country="TW";
			$found_country=0;
			print "DEBUG .tw found\n";
		}
		if (/leaseweb/i){
			$country="KR";
			$found_country=0;
		}
		if ((/kornet/i)||(/BORANET/i)||(/address.*seoul/i)||(/\.co\.kr/i)){
			$country="KR";
			$found_country=0;
		}
		if ((/Comcast Cable/i)||(/Comcast Business Communications/i)||
			(/Comcast IP/i)||(/Optimum Online/i)||
			(/Cox Communications/i)||(/MCI Communications/i)){
			$country="US";
			$found_country=0;
		}
		if (/country/i){
			$found_country=0;
			#print "DEBUG Country line found:$_\n";
			$_ =~ s/:/: /g;
			#($trash,$country)=split(/\s+/, $_);
			$size=@line_array=split(/\s+/, $_);
			print "size is $size, country: $line_array[$size-1]\n";
			$country=$line_array[$size-1];
			last;
		}
	}
	if ($found_country){
		print "DEBUG Information NOT found, something is wrong, Setting to UNKNOWN now.\n";
		$country="UNKNOWN";
	}
	close (PIPE);
	open (FILE, ">>/usr/local/etc/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
	print (FILE "$ARGV[0] $country\n");
	close (FILE);
}
