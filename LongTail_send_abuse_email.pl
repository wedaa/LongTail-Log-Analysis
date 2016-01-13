#!/usr/bin/perl
#/usr/local/etc/whois.out
chdir ("/tmp");
$threshold=9; #Only send email if attacks > $threshold
open (INPUT, "cat /var/www/html/honey/last-7-days-ip-addresses.txt |grep -vFf /usr/local/etc/LongTail_dont_send_abuse_ips|")||die "Can not open /var/www/html/honey/last-7-days-ip-addresses.txt\n";
while (<INPUT>){
	chomp;
	if (/#/){next;}
	$_ =~ s/^\s+//;
	#print "==========================\n";
	($num, $ip, $country)=split(/ /,$_);
	#print "$ip\n";
	if ($country =~/China/){next;}
	if ($country =~/Hong_Kong/){next;}
	if ($num <= $threshold){next;}
	if ( -e "/usr/local/etc/whois.out/$ip" ){
		$abuse_email =`cat /usr/local/etc/whois.out/$ip | grep abuse |grep mail |egrep -vi changed\\|remarks\\|\% | awk '{print \$NF}' `;
		chomp $abuse_email;
		if ( $abuse_email ne ""){
			$abuse_email =~ s/\n/,/g;
			print "------------------------\n";
			print "$ip\n$abuse_email\n";
			$abuse_line=`grep $ip\  /var/www/html/honey/last-7-days-ip-addresses.txt`;
			print "We have received $num login attempts from IP address $ip in the past 7 days against one of our honeypots.\n\n";
			print "We run a research project called LongTail which includes multiple honeypots.  yada yada\n\n";
			print "If you wish to no longer receive these emails, or have questions about LongTail, please email yada@yada.com\n\n";
			print "The prior 30 days of IP addresses that have tried to login to our honeypots is available at http://longtail.it.marist.edu/honey/last-30-days-ip-addresses.shtml\n\n";
			print "Please include this email in your request to no longer receive these emails.\n\n";
			print "SITE CODE=23ab67adc\n\n";
			print "Thanks for your help!\n\n";
			print "My name and my email\n\n";
		}
	}
}
close (INPUT);
