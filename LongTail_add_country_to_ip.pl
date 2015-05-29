#!/usr/bin/perl
# SAMPLE INPUT
#    213 117.21.174.111
#   2801 119.147.84.181

sub init {
#	if ($0) {
#		print "DEBUG found an arg --> $0\n";
#	}
#	else {
#		print "DEBUG no arg found\n";
#	}

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
	}
	close (FILE);

	open ("FILE", "/usr/local/etc/LongTail_sshPsycho_IP_addresses")|| die "Can not open /usr/local/etc/LongTail_sshPsycho_IP_addresses\nExiting now\n";
	while (<FILE>){
		chomp;
		$ssh_psycho{$_}=$_;
		($ip1,$ip2,$ip3,$ip4)=split(/\./,$_);
		if ( $ip4 eq ""){
			$counter=1;
			while ($counter <= 255){
				$tmp="$_.$counter";
				$ssh_psycho{$tmp}="$_.$counter";
				$counter++;
			}
		}
	}
	close (FILE);

	open ("FILE", "/usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses")|| die "Can not open /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses\nExiting now\n";
	while (<FILE>){
		chomp;
		$ssh_psycho_friends{$_}=$_;
		($ip1,$ip2,$ip3,$ip4)=split(/\./,$_);
		if ( $ip4 eq ""){
			$counter=1;
			while ($counter <= 255){
				$tmp="$_.$counter";
				$ssh_psycho_friends{$tmp}="$_.$counter";
				$counter++;
			}
		}
	}
	close (FILE);

	open ("FILE", "/usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses")|| die "Can not open /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses\nExiting now\n";
	while (<FILE>){
		chomp;
		$ssh_psycho_associates{$_}=$_;
		($ip1,$ip2,$ip3,$ip4)=split(/\./,$_);
		if ( $ip4 eq ""){
			$counter=1;
			while ($counter <= 255){
				$tmp="$_.$counter";
				$ssh_psycho_associates{$tmp}="$_.$counter";
				$counter++;
			}
		}
	}
	close (FILE);

	if ( -d "/usr/local/etc/LongTail_botnets"){
			open (FIND, "find /usr/local/etc/LongTail_botnets -type f -print|sort |") || die "Can not run find command\n";
			while (<FIND>){
				chomp;
				if (/.sh$/){next;}
				if (/.pl$/){next;}
				if (/.html/){next;}
				if (/.shtml/){next;}
				if (/\.201\d\./){next;}
				if (/\.202\d\./){next;}
				if (/backups/){next;}
				if (/sshPsycho/){next;}
				$filename=$_;
				$botnet_name=`basename $filename`;
				chomp $botnet_name;
				open (FILE, "$_");
				while (<FILE>){
					chomp;
					$ip=$_;
					if (/\.\.\./){next;}
					#if ($ssh_psycho_friends{$ip} ){ $tag="sshPsycho_Friend"; }
					$botnets{$ip}=$botnet_name;
				}
				close (FILE);
			}
			close (FIND);
		}
}
# <A HREF="/honey/ip_attacks.shtml#109.161.137.122">109.161.137.122</A> 

&init;
while (<>){
	chomp;
	($trash,$count,$ip)=split (/\s+/,$_,3);
	if ( ($count eq "") && ($ip eq "") ) {
		#print "DEBUG Only one field, must be ip\n";
		$ip = $trash;
	}
	$tmp_country_code=$ip_to_country{$ip};
	$tmp_country_code=~ tr/A-Z/a-z/;
	$_ =~ s/$ip/$ip $country_code{$tmp_country_code}/;
	$tag="";
	if ($ssh_psycho{$ip} ){ $tag="sshPsycho"; }
	if ($ssh_psycho_associates{$ip} ){ $tag="sshPsycho_Associate"; }
	if ($ssh_psycho_friends{$ip} ){ $tag="sshPsycho_Friend"; }
	if ($botnets{$ip}) { $tag=$botnets{$ip};}
	if ($tag ne ""){
		print "$_($tag)\n";
	}
	else {
		print "$_\n";
	}
}

