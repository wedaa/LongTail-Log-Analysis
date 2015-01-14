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
	($ip_address,$country)=split (/\s+/,$_,2);
	#$ip_table{$ip_address}=$country;
	$ip_table{"$ip_address"}=$country;
	#print "DEBUG-ip_address is $ip_address, country is $country\n";
	#print "DEBUG-$ip_table{$ip_address}\n";
}
close (FILE);
#print "DEBUG-ARGV[0] is $ARGV[0]\n";
$ip=$ARGV[0];

if ($ip_table{$ip}){ 
	#print "in the file\n";
	#print "country: $ip_table{$ip}\n";
	$tmp=$ip_table{$ip};
	print "country: $tmp\n"
}
else {
	#print "Looking it up\n";
	open (PIPE, "whois $ARGV[0]|") || die "Can not open whois command\n";
	while (<PIPE>){
		print "DEBUG $_";
		if (/country/i){
			print "DEBUG Country line found:$_\n";
			$_ =~ s/:/: /g;
			#($trash,$country)=split(/\s+/, $_);
			$size=@line_array=split(/\s+/, $_);
			print "size is $size, country: $line_array[$size-1]\n";
			last;
		}
	}
	close (PIPE);
	open (FILE, ">>/usr/local/etc/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
	print (FILE "$ARGV[0] $country\n");
	close (FILE);
}
