#!/usr/bin/perl

sub init {
	$MY_EMAIL="Myemail\@example.com";
	$MY_NAME="My Name";
	$MY_SITE="http://longtail.it.marist.edu";
	$DEBUG=0;
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
		$DAYS_AGO_YEAR=`date  +"%Y"  --date="$days_ago day ago"`;
		chomp $DAYS_AGO_YEAR;
		$DAYS_AGO_MONTH=`date  +"%m" --date="$days_ago day ago"`;
		chomp $DAYS_AGO_MONTH;
		$DAYS_AGO_DAY=`date  +"%d"   --date="$days_ago day ago"`;
		chomp $DAYS_AGO_DAY;
		if ( -e "/var/www/html/honey/historical/$DAYS_AGO_YEAR/$DAYS_AGO_MONTH/$DAYS_AGO_DAY/abuse_email_sent"){
			if ($DEBUG > 0){print (STDERR "/var/www/html/honey/historical/$DAYS_AGO_YEAR/$DAYS_AGO_MONTH/$DAYS_AGO_DAY/abuse_email_sent\n");}
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

open (INPUT, "cat /var/www/html/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-ip-addresses.txt |grep -vFf /usr/local/etc/LongTail_dont_send_abuse_ips|")||die "Can not open /var/www/html/honey/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-ip-addresses.txt\n";
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
	if ($num <= $threshold){print "$num is less than the threshold of $threshold, skipping\n"; next;}
	if ( -e "/usr/local/etc/whois.out/$ip" ){
		$abuse_email =`cat /usr/local/etc/whois.out/$ip | grep abuse |grep mail |egrep -vi changed\\|remarks\\|\% | awk '{print \$NF}' |grep \\@ `;
		chomp $abuse_email;
		# Try to find any email address
		if ( $abuse_email eq ""){
			$abuse_email =`cat /usr/local/etc/whois.out/$ip | grep mail |egrep -vi changed\\|remarks\\|\% | awk '{print \$NF}' |grep \\@ `;
		}
		$abuse_email =~ s/\n/,/g;
		$abuse_email =~ s/,$//g;
		chomp $abuse_email;
		if ( $abuse_email ne ""){
			if ($mail_sent{"$abuse_email"} != 1){
				print "------------------------\n";
				print "$ip\n$abuse_email\n";
				$abuse_line=`grep $ip\  /var/www/html/honey/current-ip-addresses.txt`;
				open (OUTPUT, ">email.$$");
				print (OUTPUT "Please do not respond directly to this email as it is unmonitored.  Please send email to $MY_EMAIL instead.\n\n");

				print (OUTPUT "We have received $num ssh login attempts from IP address $ip yesterday against one or more of our honeypots.\n\n");
				print (OUTPUT "We run a research project called LongTail ($MY_SITE ) which includes multiple honeypots.  \n\n");
				print (OUTPUT "If you wish to no longer receive these emails, or have questions about LongTail, please email $MY_EMAIL\n\n");
				print (OUTPUT "Yesterday's login attempts are available at $MY_SITE/honey/historical/$YESTERDAY_YEAR/$YESTERDAY_MONTH/$YESTERDAY_DAY/current-ip-addresses.txt\n\n");
				print (OUTPUT "Today's login attempts are available at $MY_SITE/honey/current-ip-addresses.txt\n\nThe prior 30 days of IP addresses that have tried to login to our honeypots is available at $MY_SITE/honey/last-30-days-ip-addresses.shtml\n\n");
				print (OUTPUT "This email is sent nightly.  You will not receive another email from us for at least 7 days, assuming we continue to have your host at $ip continue to attempt to login to our honeypots.\n\n");
				print (OUTPUT "Please include this email in your request to no longer receive these emails.\n\n");
				print (OUTPUT "SITE CODE=23ab67adc\n\n");
				print (OUTPUT "Thanks for your help!\n\n");
				print (OUTPUT "$MY_NAME\n$MY_EMAIL \n\n");
				close (OUTPUT);
				#
				# Send the email here
				#
				print "Sending email to $abuse_email\n";
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
