#!/usr/bin/perl
#
# No error checking, I assume the argument is good, and that
# the file is good. Maybe later.
#
# All this does is return the line "Country: <country-of-the-ip-address>
#
# Usage : whois.perl <IPV4-address>
#
sub look_up_country {
}

$ip=$ARGV[0];

if ( $ip eq "NAMEDPIPE" ){
	#OK, so we start as a daemon, and get killed later...
	$PIPE=$ARGV[1];
	open (FILE, "/usr/local/etc/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
	while (<FILE>){
		chomp;
		($ip_address,$file_country)=split (/\s+/,$_,2);
		$ip_table{"$ip_address"}=$file_country;
	}
	close (FILE);
	while (1){
		open (INPUT, "+< $PIPE") || die "Can not open named pipe $PIPE\n";
		while (<INPUT>){
			chomp;
			$ip=$_;
			close (INPUT);
		}
		$tmp="Not Set";
		print "Fell through loop\n";
		open (OUT, '>', "pipe2") || die "Can not open named pipe pipe2\n";
		print "Writing to pipe2\n";
		if ($ip_table{$ip}){ 
			$tmp=$ip_table{$ip};
			#print "DEBUG country is $tmp\n";
		}
		print (OUT "country: $tmp\n");
		close (OUT);
	}
	print "Fell through\n";
	close (INPUT);
}
else {
	#OK, so we run interactively
	
	open (FILE, "/usr/local/etc/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
	while (<FILE>){
		chomp;
		($ip_address,$file_country)=split (/\s+/,$_,2);
		$ip_table{"$ip_address"}=$file_country;
		if ($ip_table{$ip}){  last; }
	}
	close (FILE);

	if ($ip_table{$ip}){ 
		$tmp=$ip_table{$ip};
		print "country: $tmp\n";
	}
	else {
		$found_country=1;
		#print "DEBUG IP is $ARGV[0]\n";
		open (PIPE, "whois $ARGV[0]|") || die "Can not open whois command\n";
		while (<PIPE>){
			# Sometimes whois lookups for some IPs do not return a Country Code:-(
			# This is a hack to force a country code
			if ((/com\.tw/i)||(/hinet-net/i)){
				$country="TW";
				$found_country=0;
				#print "DEBUG .tw found\n";
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
				#print "size is $size, country: $line_array[$size-1]\n";
				$country=$line_array[$size-1];
				last;
			}
		}
		close (PIPE);
		if ($found_country){
			#print "DEBUG Information NOT found, something is wrong, Setting to UNKNOWN now.\n";
			$country="UNKNOWN";
			#print "DEBUG-wget -qO- ipinfo.io/$ip\n";
			#$tmp=`wget -qO- ipinfo.io/$ip |grep -i country`;
			$tmp=`wget -qO- ipinfo.io/$ip |grep -i country`;
			#print "DEBUG-$tmp\n";
			$tmp=~ s/"|,|://g;
			$tmp =~ s/^\s+//;
			($tmp2,$country)=split(/\s+/, $tmp);
			#print "DEBUG Country is $country\n";
			if ( length($country) == 0){
				$country="UNKNOWN";
			}
		}
		print "country: $country\n";
		$ip_table{"$ip"}=$country;
		open (FILE, ">>/usr/local/etc/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
		print (FILE "$ARGV[0] $country\n");
		close (FILE);
	}
}
