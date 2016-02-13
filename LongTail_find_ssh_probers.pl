#!/usr/bin/perl

sub init {
	local $count;

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

	open (FILE, "/var/www/html/honey/all-ips")||die "Can not open /var/www/html/honey/all-ips to read\n";
	while (<FILE>){
		chomp;
		$ip{$_}=1;
		$count++;
	}
	close (FILE);

	open (OUT, ">/var/www/html/honey/historical_ssh_probes.shtml") ||die "can not open /var/www/html/honey/historical_ssh_probes.shtml\n";
	open (OUT_2, ">/var/www/html/honey/historical_ssh_probes_sorted.shtml") ||die "can not open /var/www/html/honey/historical_probes_sorted.shtml\n";
	open (OUT_3, ">/var/www/html/honey/todays_ssh_probes_sorted.shtml") ||die "can not open /var/www/html/honey/todays_ssh_probes_sorted.shtml\n";

	print (OUT "<HTML>\n");
	print (OUT "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\">\n");
	print (OUT "<!--#include virtual=\"/honey/header.html\" -->\n");
	print (OUT "\n");
	print (OUT "<H3>LongTail Log Analysis @ <!--#include virtual=\"/honey/institution.html\" -->\n");
	print (OUT "/ Historical IP Addresses Performing SSH Probes, Sorted By IP Address</H3>\n");
	print (OUT "<P>This page is updated daily.\n");
	$date=`date`;
	print (OUT "Last updated on :$date \n");


	print (OUT_2 "<HTML>\n");
	print (OUT_2 "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\">\n");
	print (OUT_2 "<!--#include virtual=\"/honey/header.html\" -->\n");
	print (OUT_2 "\n");
	print (OUT_2 "<H3>LongTail Log Analysis @ <!--#include virtual=\"/honey/institution.html\" -->\n");
	print (OUT_2 "/ Historical IP Addresses Performing SSH Probes, Sorted By Count</H3>\n");
	print (OUT_2 "<P>This page is updated daily.\n");
	$date=`date`;
	print (OUT_2 "Last updated on :$date \n");

	print (OUT_3 "<HTML>\n");
	print (OUT_3 "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\">\n");
	print (OUT_3 "<!--#include virtual=\"/honey/header.html\" -->\n");
	print (OUT_3 "\n");
	print (OUT_3 "<H3>LongTail Log Analysis @ <!--#include virtual=\"/honey/institution.html\" -->\n");
	print (OUT_3 "/ Today's IP Addresses Performing SSH Probes</H3>\n");
	print (OUT_3 "<P>This page is updated hourly.\n");
	$date=`date`;
	print (OUT_3 "Last updated on :$date \n");

	print (OUT "<P>$count IP addresses found that performed ssh login attempts\n");
	print (OUT_2 "<P>$count IP addresses found that performed ssh login attempts\n");

	`zcat /var/www/html/honey/historical/*/*/*/all_messages.gz |grep discon  |grep -v 'login attempt '|awk '{print \$1, \$7}'|sed 's/:\$//'|sort -T /data/tmp >/data/tmp/ssh_disconnect`;

}

sub pass_1{
	local $count;
	open (FILE, "/data/tmp/ssh_disconnect")||die "Can not open data/tmp/ssh_disconnect to read\n";
	open (OUTFILE, ">/data/tmp/ssh_disconnect.output.$$")||die "Can not open data/tmp/ssh_disconnect to write\n";
	while (<FILE>){
		chomp;
		($date,$ip)=split(/ /,$_);
		if (/from/){next;}
		if (/Username/){next;}
		if (/Username/){next;}
		if (/ 10\./){next;}
		if (/ 148.100\./){next;}
		if (! $ip{$ip}){
			if ($ip_to_country{$ip} ){
				$country=$ip_to_country{$ip};
			}
			else {
				$country=`/usr/local/etc/whois.pl $ip |grep -i country|head -1|sed 's/:/: /g'|awk '{print \$2}' `;
			}
			chomp $country;
			$country =~ tr/A-Z/a-z/;
			if (  "x$country_code{$country}" ne "x"){
				$country=$country_code{$country};
			}
			print (OUTFILE "$ip $country $date\n");
			if (! $ip_found{$ip}){
				$ip_found{$ip}=1;
				$count++;
			}
		}
	}
	close (FILE);
	close (OUTFILE);
	print (OUT "<P>$count IP addresses found that performed ssh probes without performing an ssh login attempt\n");
	print (OUT_2 "<P>$count IP addresses found that performed ssh probes without performing an ssh login attempt\n");
	print (OUT "<TABLE border=1><TR><TH>IP Address</TH><TH>Country</TH><TH>Date Seen</TH></TR>\n");
	print (OUT_2 "<TABLE border=1><TR><TH># Of Times Seen</TH><TH>IP Address</TH><TH>Country</TH></TR>\n");
	print (OUT_3 "<TABLE border=1><TR><TH>IP Address</TH><TH>Country</TH><TH>Date Seen</TH></TR>\n");
	close (OUT);
	close (OUT_2);
	close (OUT_3);

	system ("sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n  /data/tmp/ssh_disconnect.output.$$|sed 's/^/<TR><TD>/' |sed 's/ /<\\/TD><TD>/g' | sed 's/\$/<\\/TD><\\/TR>/' >> /var/www/html/honey/historical_ssh_probes.shtml  ");
	system ("awk '{print \$1, \$2}' /data/tmp/ssh_disconnect.output.$$ |sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq -c | awk '{print \$1, \$2, \$3 }' |sort -nr |sed 's/^/<TR><TD>/' |sed 's/ /<\\/TD><TD>/g' | sed 's/\$/<\\/TD><\\/TR>/' >> /var/www/html/honey/historical_ssh_probes_sorted.shtml  ");
	$today=`date +%Y-%m-%d`;
	chomp $today;
	system ("grep $today /var/www/html/honey/historical_ssh_probes.shtml  >>/var/www/html/honey/todays_ssh_probes_sorted.shtml");
}

&init;
&pass_1;
open (OUT, ">>/var/www/html/honey/historical_ssh_probes.shtml") ||die "can not open /var/www/html/honey/historical_ssh_probes.shtml\n";
open (OUT_2, ">>/var/www/html/honey/historical_ssh_probes_sorted.shtml") ||die "can not open /var/www/html/honey/historical_probes_sorted.shtml\n";
open (OUT_3, ">>/var/www/html/honey/todays_ssh_probes_sorted.shtml") ||die "can not open /var/www/html/honey/todays_ssh_probes_sorted.shtml\n";

print (OUT    "</TABLE>\n<BR><!--#include virtual=\"/honey/footer.html\" -->\n");
print (OUT_2  "</TABLE>\n<BR><!--#include virtual=\"/honey/footer.html\" -->\n");
print (OUT_3  "</TABLE>\n<BR><!--#include virtual=\"/honey/footer.html\" -->\n");

close (OUT);
close (OUT_2);
close (OUT_3);

#unlink ("/data/tmp/ssh_disconnect");
unlink ("/data/tmp/ssh_disconnect.output.$$");
