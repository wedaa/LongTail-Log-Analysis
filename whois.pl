#!/usr/bin/perl
#
# No error checking, I assume the argument is good, and that
# the file is good. Maybe later.
#
# All this does is return the line "Country: <country-of-the-ip-address>
#
# Usage : whois.perl <IPV4-address>
#
# Run the following commands to setup geolocation from a 
# database in addition to looking up unfound addresses in the
# flat file ip-to-country.  We store lookups in the flat
# file as hacker owned whois entries tend to disappear and 
# then we don't know what country they were originaly attached to.
#
#cpan CPAN
#cpan Geo::IP
#cpan Socket6
#mkdir /usr/local/share/GeoIP
#mkdir /usr/local/share/GeoIP/backups # Will be used to store older copies of database files
#cd /usr/local/share/GeoIP
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
#wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
#gunzip GeoIP.dat.gz
#gunzip GeoLiteCity.dat.gz
#gunzip GeoIPv6.dat.gz
#
######################################################################
#
# Initialize variables
#
sub init_vars {
	$SCRIPT_DIR="/usr/local/etc/";
	$ip=$ARGV[0];
	use Geo::IP;

}

sub geolocate_ip{
        my $ip=shift;
        my $tmp;
  my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
  my $record = $gi->record_by_addr($ip);
  #print $record->country_code,
  #      $record->country_code3,
  #      $record->country_name,
  #      $record->region,
  #      $record->region_name,
  #      $record->city,
  #      $record->postal_code,
  #      $record->latitude,
  #      $record->longitude,
  #      $record->time_zone,
  #      $record->area_code,
  #      $record->continent_code,
  #      $record->metro_code;
        # ericw note: I have no idea what happens if there IS a record
        # but there is no country code
        undef ($tmp);
        if (defined $record){
                $tmp=$record->country_code;
		print "country: $tmp\n";
                return "$tmp";
        }
        else {
		print "country: undefined\n";
                return ("undefined");
        }

  # the IPv6 support is currently only avail if you use the CAPI which is much
  # faster anyway. ie: print Geo::IP->api equals to 'CAPI'
  #use Socket;
  #use Socket6;
  #use Geo::IP;
  #my $g = Geo::IP->open('/usr/local/share/GeoIP/GeoIPv6.dat') or die;
  #my $g = Geo::IP->open('GeoLiteCity.dat') or die;
  #print $g->country_code_by_ipnum_v6(inet_pton AF_INET6, '::24.24.24.24');
  #print $g->country_code_by_addr_v6('2a02:e88::');
}

######################################################################
#
# subroutine to find a country code if it's not in the file....
#
sub look_up_country {
	#print (STDERR "In look_up_country\n");
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
		$country="UNKNOWN";
		$tmp=`timeout 10  wget -4 -T 3 -qO- ipinfo.io/$ip |grep -i country`;
		$tmp=~ s/"|,|://g;
		$tmp =~ s/^\s+//;
		($tmp2,$country)=split(/\s+/, $tmp);
		if ( length($country) == 0){
			$country="UNKNOWN";
		}
	}
	print "country: $country\n";
	$ip_table{"$ip"}=$country;
	open (FILE, ">>$SCRIPT_DIR/ip-to-country") || die "can not open $SCRIPT_DIR/ip-to-country\n";
	print (FILE "$ARGV[0] $country\n");
	close (FILE);
}
######################################################################
#
# Main line of code
#
&init_vars;

if ( $ip eq "NAMEDPIPE" ){
	#OK, so we start as a daemon, and get killed later...
	$PIPE=$ARGV[1];
	open (FILE, "$SCRIPT_DIR/ip-to-country") || die "can not open $SCRIPT_DIR/ip-to-country\n";
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
		if ($ip eq "EXIT") {
			print (STDERR "Exit received\n");
			last;
		}
		$tmp="Not Set";
		#print "Fell through loop\n";
		#print "Writing to pipe2\n";
		if ($ip_table{$ip}){ 
			$tmp=$ip_table{$ip};
		}
		else {
			&look_up_country;
		}
		open (OUT, '>', "pipe2") || die "Can not open named pipe pipe2\n";
		print (OUT "country: $tmp\n");
		close (OUT);
	}
	#print "Fell through\n";
	close (INPUT);
}
else {
	#OK, so we run interactively
	
	# We look it up in the file first because sometimes whois entries
	# disappear when the bad guys have their whois taken away
	open (FILE, "$SCRIPT_DIR/ip-to-country") || die "can not open /usr/local/etc/ip-to-country\n";
	while (<FILE>){
		chomp;
		($ip_address,$file_country)=split (/\s+/,$_,2);
		$ip_table{"$ip_address"}=$file_country;
		if ($ip_table{$ip}){  last; }
	}
	close (FILE);
	$country ="";
	if ($ip_table{$ip}){ 
		$tmp=$ip_table{$ip};
		print "country: $tmp\n";
		$country=$tmp;
	}
	else { #It's not in the file or the array :-(
		if ( -e "/usr/local/share/GeoIP/GeoIP.dat" ){
			$country=&geolocate_ip("$ip");
			open (FILE, ">>$SCRIPT_DIR/ip-to-country") || die "can not open $SCRIPT_DIR/ip-to-country\n";
			print (FILE "$ip $country\n");
			close (FILE);
		}
		if ( $country eq ""){
			# Look it up via the files and then whois data
			# This is because hacker owned whois data disappears
			# when it is taken away from them
			&look_up_country;
		}
	}

}
