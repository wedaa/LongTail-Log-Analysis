#!/usr/bin/perl
######################################################################
#
# Written by: Eric Wedaa
# Perl version started: 2016-10-16
# Last updated on:      2016-10-16
# Purpose: This script creates webpages that list the accounts 
#          attempted by each IP address.  This initial version
#          runs outside of the LongTail.sh Version 1 program, but will
#          be folded inside of the Version 2 code (which is all Perl).
#
# Initial notes:
# cat /var/log/messages |grep sshd |grep IP: |awk '{print $5,$8}' |sort |uniq -c |sort -k2V 
#
# Please see show_help routine (immediately below) for usage instructions
#

######################################################################

sub show_help {
	print "mandatory arguments are -i <filename> -o <filename> -t <directoryName>\n";
	print "where -i is input file, -o is output file, and -t is a directory to store temporary files and a sort location\n";
	print "Minimal checking is done in this version, as it will eventually\n";
	print "be folded into LongTail.pl\n\n";
	print "\n";
	print "Input file is assumed to be the temp file created by longtail, there is NO ERROR CHECKING DONE ON INPUT\n";
	print "Filenames must be fully qualified, such as /tmp/LongTail.$$, not just LongTail.$$\n";
	exit 0;
}

sub init_ip_to_country{
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

	open ("FILE", "/usr/local/etc/LongTail_sshPsycho_2_IP_addresses")|| die "Can not open /usr/local/etc/LongTail_sshPsycho_IP_addresses\nExiting now\n";
	while (<FILE>){
		chomp;
		$ssh_psycho2{$_}=$_;
		($ip1,$ip2,$ip3,$ip4)=split(/\./,$_);
		if ( $ip4 eq ""){
			$counter=1;
			while ($counter <= 255){
				$tmp="$_.$counter";
				$ssh_psycho2{$tmp}="$_.$counter";
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


######################################################################
sub process_args {
	#
	# My processing of arguments sucks and needs to be fixed
	#
	if ( @ARGV == 0 ){
		print "No parameters passed, exiting now\n";
		exit 1;
	}
	else{
		while ( @ARGV > 0 ) {
			if (( $ARGV[0] eq "-h" ) || ( $ARGV[0] eq "-help" )) {
				&show_help;
				exit 0;
			}
	
			if ( $ARGV[0] eq "-i" ) {
				shift @ARGV;;
				$INPUT_FILE=$ARGV[0];
				if ( -e "$INPUT_FILE" ) {
				}
				else  {
					print "Input file you specified does not exist, exiting now\n";
					exit 1;
				}
				shift @ARGV;;
				next;
			}
	
			if ( $ARGV[0] eq "-o" ) {
				shift @ARGV;;
				$OUTPUT_FILE=$ARGV[0];
				# I am assuming that I can write to the file passed to me :-)
				shift @ARGV;;
				next;
			}
	
			if ( $ARGV[0] eq "-t" ) {
				shift @ARGV;;
				$TMPDIR=$ARGV[0];
				# I am assuming that I can write to the file passed to me :-)
				shift @ARGV;;
				if ( ! -d $TMPDIR ){
					print "-t $TMPDIR is not a directory, exiting now\n";
					exit 1;
				}
				next;
			}

			print "Bad option, exiting now";
			exit 1;
		} #end of while
	} # end of else
	# Make sure all the options were passed to me
	if ( "X$INPUT_FILE" eq "X"){
		print "You didn't pass an input file, exiting now\n";
		exit;
	}
	if ( "X$OUTPUT_FILE" eq "X"){
		print "You didn't pass an output file, exiting now\n";
		exit;
	}
	if ( "X$TMPDIR" eq "X"){
		print "You didn't pass an temporary directory for sorting and output files, exiting now\n";
		exit;
	}
}

######################################################################
sub list_accounts_by_ip {
#
# input line looks like this:
# 2016-10-16T03:45:04-04:00 syrtest sshd-22[1636]: IP: 116.31.116.40 PassLog: Username: root Password: metallica
#
	#open (FILE, $INPUT_FILE)|| die "can not open $INPUT_FILE\n";
	open (FILE, "/usr/local/etc/catall.sh $INPUT_FILE|")|| die "can not open $INPUT_FILE\n";
	open (OUT, ">$TMPDIR/LongTail.$$")|| die "Can not write to $TMPDIR/LongTail.$$\n";
	while (<FILE>){
		chomp;
		@words=split(/ /,$_,10);
		print (OUT "$words[4] $words[7]\n");
	}
	close (FILE);
	close (OUT);
	`sort -V $TMPDIR/LongTail.$$ > $TMPDIR/LongTail.$$.sorted`;
	unlink ("$TMPDIR/LongTail.$$");

	`uniq -c $TMPDIR/LongTail.$$.sorted > $TMPDIR/LongTail.$$.uniqed`;
	unlink ("$TMPDIR/LongTail.$$.sorted");

	open (FILE, "$TMPDIR/LongTail.$$.uniqed") || die "This is wierd, can not open $TMPDIR/LongTail.$$.uniqed\n";
	open (OUTFILE, ">>$OUTPUT_FILE") || die "This is wierd, can not open $OUTPUT_FILE\n";
	while (<FILE>){
		chomp;
		@words=split(/\s+/,$_,4);
		$ip=$words[2];
		if (defined($ip_to_country{$ip})){
			$tmp_country_code=$ip_to_country{$ip};
		}
		else {
			if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
				if ($DEBUG >0){print "Calling /usr/local/etc/whois.pl $ip now\n";}
				#print (STDERR "ip is $ip\n");
				$tmp_country_code=`/usr/local/etc/whois.pl $ip`;
				chomp $tmp_country_code;
				if ($DEBUG >0){print "tmp_country_code is -->$tmp_country_code<--\n";}
				#$ip_to_country{$ip}=1;
				($trash,$tmp_country_code)=split(/ /,$tmp_country_code);
				if ($DEBUG >0){print "tmp_country_code NOW is -->$tmp_country_code<--\n";}
				$ip_to_country{$ip}=$tmp_country_code
			}
		}
		$tmp_country_code=~ tr/A-Z/a-z/;
		#$_ =~ s/$ip/$ip $country_code{$tmp_country_code}/;
		$tag="";
		if ($ssh_psycho{$ip} ){ $tag="sshPsycho"; }
		if ($ssh_psycho2{$ip} ){ $tag="sshPsycho-2"; }
		if ($ssh_psycho_associates{$ip} ){ $tag="sshPsycho_Associate"; }
		if ($ssh_psycho_friends{$ip} ){ $tag="sshPsycho_Friend"; }
		if ($botnets{$ip}) { $tag=$botnets{$ip};}
		#if ($tag ne ""){
		#	print "$_($tag)\n";
		#}
		#else {
		#	print "$_\n";
		#}

		print (OUTFILE "<TR><TD>$words[2]</TD><TD>$country_code{$tmp_country_code} $tag</TD><TD>$words[1]</TD><TD>$words[3]</TD></TR>\n");
	}
	close (FILE);
	close (OUTFILE);
	unlink ("$TMPDIR/LongTail.$$.uniqued");
}


######################################################################
$DEBUG=0;
if ($DEBUG >0 ){print "calling process_args now\n";}
&process_args;
if ($DEBUG >0 ){print "calling init_ip_to_country now\n";}
&init_ip_to_country;
#print "Input file is $INPUT_FILE\n";
#print "output file is $OUTPUT_FILE\n";
if ($DEBUG >0 ){print "calling list_accounts_by_ip now\n";}
&list_accounts_by_ip;
