#!/usr/bin/perl

############################################################################
## adds commas to numbers so they are readable
## 
sub commify {
	my ( $sign, $int, $frac ) = ( $_[0] =~ /^([+-]?)(\d*)(.*)/ );
	my $commified = (
	reverse scalar join ',',
	unpack '(A3)*',
	scalar reverse $int
	);
	return $sign . $commified . $frac;
}     

sub remove_single_attempts_from_sum2 {
	open (SUMDATA, "/var/www/html/honey/attacks/sum2.data");	
	open (SUMDATA_OUT, ">/var/www/html/honey/attacks/sum2.data_large_attacks");	
	while (<SUMDATA>){
		($dict,$attack)=split(/  /,$_);
		$wc = `cat /var/www/html/honey/attacks/dict-$dict.txt.wc`;
		chomp $wc;
		if ($wc > 4){
			print (SUMDATA_OUT $_);
		}
	}
	close (SUMDATA);
	close (SUMDATA_OUT);
}


sub init {
	$|=1;
	chdir ("/usr/local/etc/LongTail_botnets");
	$botnet_dir="/usr/local/etc/LongTail_botnets";
	$html_bots_dir="/var/www/html/honey/bots/";
	if (! -d $html_bots_dir){
		print "Can't find $html_bots_dir, exiting now\n";
		exit;
	}
	$bots_dir_url="honey/bots/";
	$bots_dir="/var/www/html/honey/bots/";
	$attacks_dir="/var/www/html/honey/attacks/";
	$client_data="/var/www/html/honey/clients.data /var/www/html/honey/kippo_clients.data";
	$download_dir="/var/www/html/honey/downloads/";
	if ( ! -d $download_dir ){
		print "$download_dir does not exist or is not a directory, exiting now\n";
		exit;
	}
	$this_year=`date +%Y`;
	chomp $this_year;
	$this_month=`date +%m`;
	chomp $this_month;
	$this_day=`date +%d`;
	chomp $this_day;

	open ("FILE", "/usr/local/etc/translate_country_codes")|| die "Can not open /usr/local/etc/translate_country_codes\nExiting now\n";
	while (<FILE>){
		chomp;
		$_ =~ s/  / /g;
		($code,$country)=split (/ /,$_,2);
		$country =~ s/ /_/g;
		$country_code{$code}=$country;
	}
	close (FILE);

}

sub print_header {
	print "<!--#include virtual=\"/honey/header_head.html\" -->\n";
	print "<!--#include virtual=\"/honey/header_fancybox.html\" -->\n";
	print "<!--#include virtual=\"/honey/header_body.html\" -->\n";
	print "<H3>BETA-BotNet Analysis</H3>\n";
	print "<P>BETA-BotNet analysis under development.\n";
	print "\n";
	print "<P>These numbers are based on \"Attack Patterns\", which are \n";
	print "generated 4 times a day, so these numbers will not match\n";
	print "what is on the front page of LongTail.\n";
	$date=`date`;
	print "Created on $date\n";
	if ( ! -e "/var/www/html/honey/attacks/sum2.data"){
		print "<P>Attack patterns being generated now, please check back later\n";
	}
}

###############################################################################
#
# do the real work
#

sub pass_1 {
	open (FIND, "find . -type f -print|xargs wc -l |sort -nr |awk '{print \$2}' |") || die "Can not run find command\n";
	$number_of_botnets=0;
	$global_max=0;
	$global_min=99999;
	$global_total=0;
	while (<FIND>){
		chomp;
	#print "Found filename $_\n";
		if (/.sh$/){next;}
		if (/.pl$/){next;}
		if (/.html/){next;}
		if (/.shtml/){next;}
		if (/.accounts/){next;}
		if (/typescript/){next;}
		if (/total/){next;}
		if (/2015/){next;}
		if (/sed.out/){next;}
		if (/backups/){next;}
		#if (/big_botnet/){next;}
		#if (/pink/){next;}
		#if (/fromage/){next;}
		if (/.static/){
			$static=1;
		}
		else {
			$static=0;
		}
		$filename=$_;
		$filename=~ s/\.\///;
		#print "Looking for botnet $filename\n";
		print "<H3>BotNet $filename</H3>\n";
		print "<a href=\"#divhosts$filename\" class=\"various\">Hosts involved with $filename</a>\n";
		print "<div style=\"display:none\">\n";
		print "<div id=\"divhosts$filename\">\n";
		print "<p><strong>Hosts involved with $filename</strong></p>\n";

		# print "<P>Hosts involved with $filename are:\n<BR>\n";
		if ( -e "$filename.accounts"){
			unlink ("$filename.accounts");
		}
		$total=0;
		$total_year=0;
		$total_month=0;
		$total_day=0;
		$attacks=0;
		$min=999999999;
		$max=0;
		unlink ("/tmp/TAG");
		`echo \"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\" > /tmp/TAG`;
		$number_of_bots=0;
		$number_of_botnets++;
		open (OUTPUT, ">$bots_dir/$filename.nmap.txt");
		open (FILE, "$_");
		#
		# This loop counts the number of attacks, login attempts, and bots
		# and creates a file /tmp/TAG containing the md5sums of the attacks
		#
		# This loop REALLLLLY needs to be cleaned up to make it faster
		#
		while (<FILE>){
			chomp;
			$ip=$_;
			if (/\.\.\./){next;}
			$number_of_bots++;
			print "$ip ";
			$tmp=system("cat $attacks_dir/$ip*|awk '{print \$1}'>> $filename.accounts");
			if ($ips_seen_already{$ip}){
				print "<BR>$ip has already been seen in $ips_seen_already{$ip}\n<BR>\n";
				$ips_seen_already{$ip}=$ips_seen_already{$ip}." ".$filename;
			}
			else {
				$ips_seen_already{$ip}=$filename;
			}
			open (SUMDATA, "/var/www/html/honey/attacks/sum2.data");	
			while (<SUMDATA>){
				$line=$_;
				if (/\Q $ip.\E/){ #2014-08-25 added the space to terminate the start of the IP address
#`echo "$line" >>/tmp/FOUND`;
#print "line is $line\n";
					($dict,$attack)=split(/ /,$_,2);
					#/var/www/html/honey/attacks/218.25.54.51.shepherd.1-2015.05.04.12.53.19-04
					($trash,$date)=split(/-/,$attack);
					$wc=`cat /var/www/html/honey/attacks/dict-$dict.txt.wc`;
					#open (CAT_FILE, "/var/www/html/honey/attacks/dict-$dict.txt.wc");
					#while (<CAT_FILE>){
					#	chomp;
					#	$wc=$_;
					#}
					#close (CAT_FILE);
					# These are patterns to search for from other IP addresses
					if (($wc > 3) && ($static == 0)){
						`echo $dict >>/tmp/TAG`;
					}
					#print "$wc ";
					if ($attack =~ "$this_year"){$total_year+=$wc;}
					if ($attack =~ "$this_year.$this_month"){$total_month+=$wc;}
					if ($attack =~ "$this_year.$this_month.$this_day"){$total_day+=$wc;}
					chomp $wc;
					if ( $wc > $max){$max=$wc;}
					if ( $wc < $min){$min=$wc;}
					if ( $wc > $global_max){$global_max=$wc;}
					if ( $wc < $global_min){$global_min=$wc;}
					$total+=$wc;
					$global_total+=$wc;
					$attacks++;
					$global_attacks++;
				}
			}
			close (SUMDATA);
		}
		close (FILE);
		close (OUTPUT);
		print "\n</div>\n</div>\n";

		`sort /tmp/TAG |uniq >/tmp/TAG.2`;
		#
		# This is where we find similar patterns to what we have
		# found already
		#
		# The statistics for these new hosts will show up the next 
		# time this program is run.
		#
		# Yes, I could make this recursive but I won't because
		# I don't want some weird recursive loop going on forever
		# until I just happen to catch it.
	
		`for pattern in \`cat /tmp/TAG.2\` ; do grep -F \$pattern /var/www/html/honey/attacks/sum2.data_large_attacks; done  |awk '{print \$2}' |sed 's/-..*//'  | awk -F\. '{print \$1,\$2,\$3,\$4}' |sed 's/ /./g' |sort |uniq >/tmp/tag.3`;
		#
		# The following line is so I can debug how hosts get 
		# moved into botnets
		#
		`for pattern in \`cat /tmp/TAG.2\` ; do grep -F \$pattern /var/www/html/honey/attacks/sum2.data_large_attacks; done  >/tmp/tag.4`;
	
		$DATE= `date +%Y.%m.%d:%H.%M`;
		`cp $filename $filename.$DATE`;
		`cat /tmp/tag.3 >> $filename`;
		`sort -u $filename >> $filename.2`;
		`cp  $filename.2  $filename`;
		`rm $filename.2`;
		#commented out so I can look at the file after it runs #unlink("/tmp/TAG.2");
		#commented out so I can look at the file after it runs #unlink ("/tmp/tag.3");
	
		print "\n";
		#$output=`for ip in \`cat $filename\` ; do grep -F \$ip  $client_data; done`;
		$output=`for ip in \`cat $filename | sed 's/\\./\\\\\\./g' \` ; do grep  ^\$ip\   $client_data; done`;

		$output =~ s/\n/\n<BR>/g;
		$output =~ s/\/var\/www\/html\/honey\///g;
		#print "<P>Client software and level:\n<BR>\n";
		print "<BR><a href=\"/$bots_dir_url/$filename.lifespan.shtml\">Lifetimes of IPs in $filename</a>\n";
		print "<BR><a href=\"#divclient$filename\" class=\"various\">Client software and level</a> \n";
		print "<div style=\"display:none\"> \n";
		print "<div id=\"divclient$filename\"> \n";
		print "<p><strong>Client software and level:</strong></p><br> \n";

		print $output;

		print "\b</div>\n</div>\n";

		if ($attacks>0){
			$average=$total/$attacks;
		}
		else {
			$average=0;
		}
		
		# Get country info here
		`grep -F -f $filename /usr/local/etc/ip-to-country | awk '{print \$2}' |sort |uniq -c |sort -nr > $html_bots_dir/$filename.countries.txt`;
		open (FILE, "$html_bots_dir/$filename.countries.txt");
		open (OUTPUT, ">$html_bots_dir/$filename.countries.tmp");
		while (<FILE>){
			chomp;
			$_ =~ tr/A-Z/a-z/;
			($trash,$count,$country)=split (/\s+/,$_,3);
			$_ =~ s/$country/$country_code{$country}/;
			$_ =~ s/_/ /g;
			print (OUTPUT "$_\n");
		}
		close (FILE);
		close (OUTPUT);
		if ( -e){
			unlink ("$html_bots_dir/$filename.countries.txt");
		}
		`/bin/mv $html_bots_dir/$filename.countries.tmp $html_bots_dir/$filename.countries.txt`;
		$country_count=`cat $html_bots_dir/$filename.countries.txt |wc -l`;

		$tmp=system ("sort $filename.accounts |uniq -c |sort -nr > $filename.accounts.tmp");
		if ( -e "$html_bots_dir/$filename.accounts.txt" ){ 
			unlink ("$html_bots_dir/$filename.accounts.txt");
		}
		$tmp=system ("/bin/mv $filename.accounts.tmp $html_bots_dir/$filename.accounts.txt");
		#$tmp=`ls -l $filename.accounts $html_bots_dir/$filename.accounts.txt`;
		#open (DEBUG, ">>/tmp/LongTail_get_botnet_stats.debug");
		#print (DEBUG "$tmp\n");
		#close (DEBUG);
		$line_count=`cat $html_bots_dir/$filename.accounts.txt |wc -l`;
		$line_count=&commify($line_count);
		$average=sprintf("%.2f",$average);
		$average=&commify($average);
		$total=&commify($total);
		$total_year=&commify($total_year);
		$total_month=&commify($total_month);
		$total_day=&commify($total_day);
		$number_of_bots=&commify($number_of_bots);
		$min=&commify($min);
		$max=&commify($max);
		print "\n<BR>\n";
		print "<TABLE>\n";
		print "<TR><TD>Total number of bots in $filename</TD><TD> $number_of_bots\n";
		print "<TR><TD>Total ssh attempts from $filename since logging began</TD><TD> $total\n";
		print "<TR><TD>Total ssh attempts from $filename this year</TD><TD> $total_year\n";
		print "<TR><TD>Total ssh attempts from $filename this month</TD><TD> $total_month\n";
		print "<TR><TD>Total ssh attempts from $filename today</TD><TD> $total_day\n";
		print "<TR><TD>Minimum attack size from $filename</TD><TD> $min\n";
		print "<TR><TD>Average attack size from $filename</TD><TD> $average\n";
		print "<TR><TD>Maximum attack size from $filename</TD><TD> $max\n";
		print "<TR><TD>Number of accounts tried $filename</TD><TD><a href=\"/$bots_dir_url/$filename.accounts.txt\">$line_count</a>\n";
		print "<TR><TD>Number of countries in $filename</TD><TD><a href=\"/$bots_dir_url/$filename.countries.txt\">$country_count</a>\n";
		print "<TR><TD>NMap data (if available)</TD><TD><a href=\"/$bots_dir_url/$filename.nmap.txt\">nmap</a>\n";
		print "<TR><TD>NMap OS Guess (if available)</TD><TD><a href=\"/$bots_dir_url/$filename.nmap.os.txt\">nmap</a>\n";
		print "</TABLE>\n";
		$total=0;
		$total_year=0;
		$total_month=0;
#print "DEBUG - Exiting now while debugging\n";
#exit;
	}
	close (FIND);
}

###############################################################################
#
# Copy files to download dir
#

sub pass_2 {
	open (FIND, "find . -type f -print|xargs wc -l |sort -nr |awk '{print \$2}' |") || die "Can not run find command\n";
	while (<FIND>){
		chomp;
		if (/.sh$/){next;}
		if (/.pl$/){next;}
		if (/.html/){next;}
		if (/.shtml/){next;}
		if (/.accounts/){next;}
		if (/typescript/){next;}
		if (/total/){next;}
		if (/2015/){next;}
		if (/sed.out/){next;}
		if (/backups/){next;}
		if (/.static/){
			$static=1;
		}
		else {
			$static=0;
		}
		$filename=$_;
		`cp $filename $download_dir`;
	}
	close (FIND);
}



###############################################################################
#
# Collect NMap data
#

sub pass_3 {
	open (FIND, "find . -type f -print|xargs wc -l |sort -nr |awk '{print \$2}' |") || die "Can not run find command\n";
	while (<FIND>){
		chomp;
		if (/.sh$/){next;}
		if (/.pl$/){next;}
		if (/.html/){next;}
		if (/.shtml/){next;}
		if (/.accounts/){next;}
		if (/typescript/){next;}
		if (/total/){next;}
		if (/2015/){next;}
		if (/sed.out/){next;}
		if (/backups/){next;}
		#if (/big_botnet/){next;}
		#if (/pink/){next;}
		#if (/china/){next;}
		#if (/15-/){next;}
		#if (/fromage/){next;}
		if (/.static/){
			$static=1;
		}
		else {
			$static=0;
		}
		$filename=$_;
		$filename=~ s/\.\///;
		open (OUTPUT, ">$bots_dir/$filename.nmap.txt");
		print (OUTPUT "==================================================================\n");
		print (OUTPUT "Botnet $filename\n");
		open (OUTPUT2, ">$bots_dir/$filename.nmap.os.txt");
		print (OUTPUT2 "==================================================================\n");
		print (OUTPUT2 "Botnet $filename\n");
#print "DEBUG botnet is $filename\n";
		open (FILE, "$_");
		$print_ports=0;
		while (<FILE>){
#print "DEBUG looking for ip $_";
			chomp;
			$ip=$_;
			if (/\.\.\./){next;}
			open (FIND2, "find /usr/local/etc/nmap -name '$ip-*'|sort | ");
			print (OUTPUT "+++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
			print (OUTPUT "Looking for IP Address $ip\n");
			print (OUTPUT2 "+++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
			print (OUTPUT2 "Looking for IP Address $ip\n");
			while (<FIND2>){
#print "DEBUG nmap file is $_\n";
				print (OUTPUT "======================================\n");
				print (OUTPUT $_);
				print (OUTPUT2 "======================================\n");
				print (OUTPUT2 $_);

				open (FILE2, $_);
				while (<FILE2>){
					if (/Discovered open port/){next;}
					if (/Aggressive OS guesses/){print(OUTPUT $_);next;}
					if (/Service Info: OS/){print(OUTPUT $_);next;}
					if (/^OS CPE/){print(OUTPUT $_);print (OUTPUT2 $_); next;}
					if (/No exact OS matches for host/){print(OUTPUT $_);print (OUTPUT2 $_); next;}
					if (/OS: /){print(OUTPUT $_);print (OUTPUT2 $_); next;}
					if (/NetBIOS computer name/){print(OUTPUT $_);print (OUTPUT2 $_); next;}

					if (/open port/){print(OUTPUT $_);}
					if (/^PORT/){ 
						$print_ports=1;
						print (OUTPUT "\n$_");next;
					}	
					if (/^TRACEROUTE/){ $print_ports=0;next;}	
					if ((/^\d/) && ( $print_ports ==1)){print(OUTPUT $_);next;}
				}
				close (FILE2);
				
			}
			close (FIND2);
		}
		close (FILE);
		close (OUTPUT);
		close (OUTPUT2);
	}
	close (FIND);
}


###############################################################################
#
# Collect IP Lifetime data
# 
# current_attackers_lifespan_botnet.shtml
# current_attackers_lifespan_first.shtml
# current_attackers_lifespan_ip.shtml
# current_attackers_lifespan_last.shtml
# current_attackers_lifespan_number.shtml
# current_attackers_lifespan.shtml

#

sub pass_4 {
	open (FIND, "find . -type f -print|xargs wc -l |sort -nr |awk '{print \$2}' |") || die "Can not run find command\n";
	while (<FIND>){
		chomp;
		if (/.sh$/){next;}
		if (/.pl$/){next;}
		if (/.html/){next;}
		if (/.shtml/){next;}
		if (/.accounts/){next;}
		if (/typescript/){next;}
		if (/total/){next;}
		if (/2015/){next;}
		if (/sed.out/){next;}
		if (/backups/){next;}
		#if (/big_botnet/){next;}
		#if (/pink/){next;}
		#if (/china/){next;}
		#if (/15-/){next;}
		#if (/fromage/){next;}
		if (/.static/){
			$static=1;
		}
		else {
			$static=0;
		}
		$filename=$_;
		$filename=~ s/\.\///;
#print "DEBUG looking for $filename\n";
$header="
<HTML>
<HEAD>
<TITLE>LongTail Log Analysis Attackers Lifespan</TITLE>
</HEAD>
<BODY bgcolor=#00f0FF>
<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\"> 
<!--#include virtual=\"/honey/header.html\" --> 
<H1>LongTail Log Analysis Attackers Lifespan</H1>
<P>This page is updated daily.
<P>Last updated on Sun Aug 23 17:45:01 EDT 2015

<P>Click the header to sort on that column
<TABLE border=1>
<TR>
<TH><a href=\"/honey/bots/".$filename.".lifespan_ip.shtml\">IP</a></TH>
<TH><a href=\"/honey/bots/".$filename.".lifespan.shtml\">Lifetime In Days</a></TH>
<TH><a href=\"/honey/bots/".$filename.".lifespan_botnet.shtml\">Botnet</a></TH>
<TH><a href=\"/honey/bots/".$filename.".lifespan_first.shtml\">First Date Seen</a></TH>
<TH><a href=\"/honey/bots/".$filename.".lifespan_last.shtml\">Last Date Seen</a></TH>
<TH><a href=\"/honey/bots/".$filename.".lifespan_number.shtml\">Number of Attack<BR>Patterns Recorded</a></TH></TR>
"; 
#print "DEBUG writing to $bots_dir/$filename.lifespan.shtml\n";
		open (OUTPUT, ">$bots_dir/$filename.lifespan.shtml"); print (OUTPUT $header); close (OUTPUT);
		open (OUTPUT, ">$bots_dir/$filename.lifespan_ip.shtml"); print (OUTPUT $header); close (OUTPUT);
		open (OUTPUT, ">$bots_dir/$filename.lifespan_botnet.shtml"); print (OUTPUT $header); close (OUTPUT);
		open (OUTPUT, ">$bots_dir/$filename.lifespan_first.shtml"); print (OUTPUT $header); close (OUTPUT);
		open (OUTPUT, ">$bots_dir/$filename.lifespan_last.shtml"); print (OUTPUT $header); close (OUTPUT);
		open (OUTPUT, ">$bots_dir/$filename.lifespan_number.shtml"); print (OUTPUT $header); close (OUTPUT);
		
		#`cat $filename |cat big_botnet |sed 's/^/<TD>/' |sed 's/\$/</' > $filename.sed.out`;
		`cat $filename |sed 's/^/<TD>/' |sed 's/\$/</' > $filename.sed.out`;
		#works `cat $filename |cat big_botnet |sed 's/^/<TD>/' >$filename.sed.out`;

		`grep -F -f $filename.sed.out /var/www/html/honey/current_attackers_lifespan_botnet.shtml >> $bots_dir/$filename.lifespan_botnet.shtml`;
		`grep -F -f $filename.sed.out /var/www/html/honey/current_attackers_lifespan_first.shtml >> $bots_dir/$filename.lifespan_first.shtml`;
		`grep -F -f $filename.sed.out /var/www/html/honey/current_attackers_lifespan_ip.shtml >> $bots_dir/$filename.lifespan_ip.shtml`;
		`grep -F -f $filename.sed.out /var/www/html/honey/current_attackers_lifespan_last.shtml >> $bots_dir/$filename.lifespan_last.shtml`;
		`grep -F -f $filename.sed.out /var/www/html/honey/current_attackers_lifespan_number.shtml >> $bots_dir/$filename.lifespan_number.shtml`;
		`grep -F -f $filename.sed.out /var/www/html/honey/current_attackers_lifespan.shtml >> $bots_dir/$filename.lifespan.shtml`;

		$print_ports=0;
		unlink ("$filename.sed.out");
	}
	close (FIND);
}

sub print_footer {
	if ($global_attacks>0){
		$average=$global_total/$global_attacks;
	}
	else {
		$average=0;
	}
	$average=sprintf("%.2f",$average);
	$average=&commify($average);
	$global_average=sprintf("%.2f",$global_average);
	$global_average=&commify($global_average);
	$global_total=&commify($global_total);
	$global_min=&commify($global_min);
	$global_max=&commify($global_max);
	print "<H3>BotNet Totals</H3>\n";
	#print "<P>Total ssh attempts from all BotNets since logging began: $global_total\n";
	print "<P>Total number of botnets known: $number_of_botnets\n";
	print "<P>Minimum attack size from all BotNets: $global_min\n";
	print "<P>Average attack size from all BotNets: $average\n";
	print "<P>Maximum attack size from all BotNets: $global_max\n";

	print "<!--#include virtual=\"/honey/footer.html\" -->\n";
}

&init ;
&remove_single_attempts_from_sum2 ;
&print_header ;
&pass_1 ;
&pass_2 ;
&pass_3 ;
&pass_4;
&print_footer ;

