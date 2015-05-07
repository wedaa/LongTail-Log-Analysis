#!/usr/bin/perl
# SAMPLE INPUT
#    213 117.21.174.111
#   2801 119.147.84.181

sub init {

	open ("FILE", "/usr/local/etc/translate_country_codes")|| die "Can not open /usr/local/etc/translate_country_codes\nExiting now\n";
	while (<FILE>){
		chomp;
		$_ =~ s/  / /g;
		($code,$country)=split (/ /,$_,2);
		$country =~ s/ /_/g;
		$country_code{$code}=$country;
	}
	close (FILE);

	open ("FILE", "/usr/local/etc/ip-to-country")|| die "Can not open /usr/local/etc/ip-to-country\nExiting now\n";
	while (<FILE>){
		chomp;
		$_ =~ s/  / /g;
		($ip,$country)=split (/ /,$_,2);
		$ip_to_country{$ip}=$country;
#		print "DEBUG $country\n";
	}
	close (FILE);
}

&init;
while (<>){
	chomp;
	($trash,$count,$ip)=split (/\s+/,$_,3);
	#print "DEBUG trash is $trash\n";
	#print "DEBUG count is $count\n";
	#print "DEBUG IP is -->$ip<--\n";
	#print "DEBUG ". $ip_to_country{$ip} ;
	if ( ($count eq "") && ($ip eq "") ) {
		#print "DEBUG Only one field, must be ip\n";
		$ip = $trash;
	}
	$tmp_country_code=$ip_to_country{$ip};
	$tmp_country_code=~ tr/A-Z/a-z/;
	#print "tmp_country_code is -->$tmp_country_code<--\n";
	$_ =~ s/$ip/$ip $country_code{$tmp_country_code}/;
	print "$_\n";
}

