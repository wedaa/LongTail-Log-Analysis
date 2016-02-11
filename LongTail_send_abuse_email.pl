#!/usr/bin/perl

sub init {
	chdir ("/tmp");
	$YESTERDAY_YEAR=`date  +"%Y"  --date="1 day ago"`;
	chomp $YESTERDAY_YEAR;
	$YESTERDAY_MONTH=`date  +"%m" --date="1 day ago"`;
	chomp $YESTERDAY_MONTH;
	$YESTERDAY_DAY=`date  +"%d"   --date="1 day ago"`;
	chomp $YESTERDAY_DAY;
	
	$threshold=9; #Only send email if attacks > $threshold

	$days_ago=1;
	while ($days_ago < 8){
		$DAYS_AGO_YEAR=`date  +"%Y"  --date="1 day ago"`;
		chomp $DAYS_AGO_YEAR;
		$DAYS_AGO_MONTH=`date  +"%m" --date="1 day ago"`;
		chomp $DAYS_AGO_MONTH;
		$DAYS_AGO_DAY=`date  +"%d"   --date="1 day ago"`;
		chomp $DAYS_AGO_DAY;
		if ( -e "/var/www/html/honey/historical/$DAYS_AGO_YEAR/$DAYS_AGO_MONTH/$DAYS_AGO_DAY/abuse_email_sent"){
			open (INPUT, "/var/www/html/honey/historical/$DAYS_AGO_YEAR/$DAYS_AGO_MONTH/$DAYS_AGO_DAY/abuse_email_sent");
			while (<INPUT>){
				chomp;
				$mail_sent{"$_"}=1;
			}
			close (INPUT);
		}
		$days_ago++;
	}
}

&init; 

if ( ! -e "/usr/local/etc/LongTail_dont_send_abuse_ips"){
	print "There is no /usr/local/etc/LongTail_dont_send_abuse_ips file.\n";
	print "Please create one, even if it is totally empty\n";
	exit;
}

if (! -e "/var/www/html/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-ip-addresses.txt"){
	print "Could not find /var/www/html/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-ip-addresses.txt\n";
	print "exiting now\n";
	exit;
}

open (INPUT, "cat /var/www/html/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-ip-addresses.txt |grep -vFf /usr/local/etc/LongTail_dont_send_abuse_ips|")||die "Can not open /var/www/html/honey/last-7-days-ip-addresses.txt\n";
while (<INPUT>){
	chomp;
	if (/#/){next;}
	$_ =~ s/^\s+//;
#	print "==========================\n";
#	print "LINE is $_\n";
	($num, $ip, $country)=split(/ /,$_);
	print "$ip\n";
	if ($country =~/China/){print "IP is in China, skipping\n";next;}
	if ($country =~/Hong_Kong/){print "IP is in Hong Kong, skipping\n";next;}
	if ($num <= $threshold){next;}
	if ( -e "/usr/local/etc/whois.out/$ip" ){
		$abuse_email =`cat /usr/local/etc/whois.out/$ip | grep abuse |grep mail |egrep -vi changed\\|remarks\\|\% | awk '{print \$NF}' `;
		chomp $abuse_email;
		if ( $abuse_email ne ""){
			if ($mail_sent{"$abuse_email"} != 1){
				$abuse_email =~ s/\n/,/g;
				print "------------------------\n";
				print "$ip\n$abuse_email\n";
				$abuse_line=`grep $ip\  /var/www/html/honey/current-ip-addresses.txt`;
				print "We have received $num login attempts from IP address $ip in the past 7 days against one or more of our honeypots.\n\n";
				print "We run a research project called LongTail which includes multiple honeypots.  yada yada\n\n";
				print "If you wish to no longer receive these emails, or have questions about LongTail, please email yada@yada.com\n\n";
				print "The prior 30 days of IP addresses that have tried to login to our honeypots is available at http://longtail.it.marist.edu/honey/last-30-days-ip-addresses.shtml\n\n";
				print "This email is sent nightly.  You will not receive another email from us for at least 7 days, assuming we continue to have your host at $ip contnue to attempt to login to our honeypots.\n";
				print "Please include this email in your request to no longer receive these emails.\n\n";
				print "SITE CODE=23ab67adc\n\n";
				print "Thanks for your help!\n\n";
				print "My name and my email\n\n";
				open (OUTPUT, ">>/var/www/html/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/abuse_email_sent") || die "Can not write to /var/www/html/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/abuse_email_sent, exiting now\n";
				print (OUTPUT "$abuse_email\n");
				close (OUTPUT);
			}
			else {
				print "Email to $abuse_email was sent within the last 7 days\n";
			}
		}
		else {
			print "Interesting, no abuse email found for $ip\n";
		}
	}
	else {
		print "Could not find whois information for $ip at /usr/local/etc/whois.out/$ip\n";
	}
}
close (INPUT);
