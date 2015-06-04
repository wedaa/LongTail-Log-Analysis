#!/usr/bin/perl
sub init{
	$|=1;
	
	chdir ("/usr/local/etc/LongTail_botnets");
	$this_year=`date +%Y`;
	chomp $this_year;
	$this_month=`date +%m`;
	chomp $this_month;
	$this_day=`date +%d`;
	chomp $this_day;
	
	print "<!--#include virtual=\"/honey/header.html\" -->\n";
	print "<H3>New BotNets found </H3>\n";
	print "<P>Here's a preview of some of what is coming \n";
	$date=`date`;
	print "Created on $date\n";
}


##########################################################################
#
sub pass_1{
	`cp /var/www/html/honey/attacks/sum2.data /var/www/html/honey/attacks/not_in_a_botnet.data`;
	
	
	open (FIND, "find . -type f -print |") || die "Can not run find command\n";
	$number_of_botnets=0;
	while (<FIND>){
		chomp;
	#print "Found filename $_\n";
		if (/.sh$/){next;}
		if (/.pl$/){next;}
		if (/2015/){next;}
		if (/backups/){next;}
		if (/html/){next;}
	print "proceeding with filename $_\n";
		$filename=$_;
		$filename=~ s/\.\///;
		#system ("cat $filename");
		`for pattern in \`cat $filename\` ; do  grep -vF \$pattern /var/www/html/honey/attacks/not_in_a_botnet.data > /var/www/html/honey/attacks/not_in_a_botnet.data.2; mv /var/www/html/honey/attacks/not_in_a_botnet.data.2 /var/www/html/honey/attacks/not_in_a_botnet.data; done`;
	}
	close (FIND);
	`for pattern in \`cat /usr/local/etc/LongTail_associates_of_sshPsycho_IP_addresses\` ; do  grep -vF \$pattern /var/www/html/honey/attacks/not_in_a_botnet.data > /var/www/html/honey/attacks/not_in_a_botnet.data.2; mv /var/www/html/honey/attacks/not_in_a_botnet.data.2 /var/www/html/honey/attacks/not_in_a_botnet.data; done`;
	`for pattern in \`cat /usr/local/etc/LongTail_friends_of_sshPsycho_IP_addresses\` ; do  grep -vF \$pattern /var/www/html/honey/attacks/not_in_a_botnet.data > /var/www/html/honey/attacks/not_in_a_botnet.data.2; mv /var/www/html/honey/attacks/not_in_a_botnet.data.2 /var/www/html/honey/attacks/not_in_a_botnet.data; done`;
	`for pattern in \`cat /usr/local/etc/LongTail_sshPsycho_IP_addresses\` ; do  grep -vF \$pattern /var/www/html/honey/attacks/not_in_a_botnet.data > /var/www/html/honey/attacks/not_in_a_botnet.data.2; mv /var/www/html/honey/attacks/not_in_a_botnet.data.2 /var/www/html/honey/attacks/not_in_a_botnet.data; done`;
}


##########################################################################
#
# Loop through not_in_a_botnet.data and get rid of
# attacks that have less than 6 attacks
#
sub pass_2{
print "In pass2\n";

	if ( -e "/var/www/html/honey/attacks/possible_botnet.data"){
		unlink("/var/www/html/honey/attacks/possible_botnet.data");
	}
	open (FILE, "/var/www/html/honey/attacks/not_in_a_botnet.data");
	while (<FILE>){
		($dict,$attack)=split (/ /,$_,2);
		$wc=`cat /var/www/html/honey/attacks/dict-$dict.txt.wc`;
		chomp $wc;
		if ($wc >5){
			#print "wc: $wc ; dict: $dict\n";
			`grep $dict /var/www/html/honey/attacks/not_in_a_botnet.data >> /var/www/html/honey/attacks/possible_botnet.data`;
		}
	}
	close (FILE);
}

##########################################################################
#
# Loop through possible_botnet.data and 
# print out attacking IPs per dictionary
#
sub pass_3{
	print "In pass3\n";
	open (FILE, "/var/www/html/honey/attacks/possible_botnet.data");
	$last_dict="";
	$ip_list{"null"}=1;
	$ip_count=0;
	$string="";
	while (<FILE>){
#print "\nDEBUG $_";
		chomp;
		($dict,$attack)=split(/  /,$_);
		($ip1,$ip2,$ip3,$ip4,$trash)=split(/\./,$attack);
		$ip="$ip1.$ip2.$ip3.$ip4";
		if ($dict ne $last_dict){
#print "\nNEW DICT\n";
			if ($ip_count >1){
				print $string;
			}
			$last_dict=$dict;
			undef (@ip_list);
			$wc=`cat /var/www/html/honey/attacks/dict-$dict.txt.wc`;
			chomp $wc;
			$string="\nwc: $wc; $dict: ";
			#print "\n";
			#print "wc: $wc; $dict: ";
			#print "$ip ";
			$ip_list{$ip}=1;
			$big_ip_list{$ip}=1;
			$ip_count=1;
			$string="$string $ip";
		}
		else {
			if (! $ip_list{$ip}){
				#print "$ip ";
				$ip_list{$ip}=1;
				$big_ip_list{$ip}=1;
				$ip_count++;
				$string="$string $ip";
				if ( $big_ip_list{$ip}){
					print "*";
				}
			}
		}
	}
	close (FILE);
	print "\n\n";
}

##########################################################################
#
# Print close of webpage
#
sub done{
	print "<!--#include virtual=\"/honey/footer.html\" -->\n";
}

&init;
&pass_1;
&pass_2;
&pass_3;
&done;
