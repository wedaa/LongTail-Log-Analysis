#!/usr/bin/perl
# Crontab entry is
# 0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/etc/LongTail_dashboard.pl >> /tmp/LongTail_dashboard.out

$HOUR=`date +%H`;
chomp $HOUR;
$MINUTE=`date +%M`;
chomp $MINUTE;

if (($HOUR <1) && ($MINUTE<5)){
	`cp /var/www/html/honey/dashboard_usernames.png /var/www/html`;
	`cp /var/www/html/honey/dashboard_passwords.png /var/www/html`;
	`cp /var/www/html/honey/dashboard_ips.png /var/www/html`;
	`cp /var/www/html/honey/dashboard_number_of_attacks.png /var/www/html`;
	unlink "/var/www/html/honey/dashboard_usernames.data";
	unlink "/var/www/html/honey/dashboard_passwords.data";
	unlink "/var/www/html/honey/dashboard_ips.data";
	unlink "/var/www/html/honey/dashboard_number_of_attacks.data";
}

$DATE=`date +"%Y-%m-%d"`;
$TIME=`date +%H:%M`;
chomp $DATE;
chomp $TIME;
open (MESSAGES, "/var/log/messages")|| die "can not open /var/log/messages\n";
while (<MESSAGES>) {
	if (/$DATE/){
		if (/IP:/){
			chomp;
			$number_of_attacks++;

			$username=$_;
			$username =~ s/^..*Username: //;
			$username =~ s/ Pass..*$//;
			$usernames_seen{$username}++;

			$password=$_;
			$password =~ s/^..*Password: //;
			$passwords_seen{$password}++;

			$ip=$_;
			$ip =~ s/^..*IP: //;
			$ip =~ s/ Pass..*$//;
			$ips_seen{$ip}++;
		}
	}
}
close (MESSAGES);

open ("FILE", ">>/var/www/html/honey/dashboard_number_of_attacks.data") || die "Can not write to dashboard_number_of_attacks.data\n";
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$number_of_attacks $TIME\n");}else{print (FILE "$number_of_attacks \n");}
close (FILE);

open ("FILE", ">>/var/www/html/honey/dashboard_usernames.data") || die "Can not write to dashboard_usernames.data\n";
$arrSize = keys %usernames_seen;
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$arrSize $TIME\n");}else{print (FILE "$arrSize \n");}
close (FILE);


open ("FILE", ">>/var/www/html/honey/dashboard_passwords.data") || die "Can not write to dashboard_passwords.data\n";
$arrSize = keys %passwords_seen;
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$arrSize $TIME\n");}else{print (FILE "$arrSize \n");}
close (FILE);

open ("FILE", ">>/var/www/html/honey/dashboard_ips.data") || die "Can not write to dashboard_ips.data\n";
$arrSize = keys %ips_seen;
if (($MINUTE == 0) || ($MINUTE==30)){print (FILE "$arrSize $TIME\n");}else{print (FILE "$arrSize \n");}

close (FILE);

$wc=`cat /var/www/html/honey/dashboard_usernames.data |wc -l`;
chomp $wc;
$lines_needed=288-$wc;
`cat /var/www/html/honey/dashboard_usernames.data > /var/www/html/honey/dashboard_usernames.tmp`;
`cat /var/www/html/honey/dashboard_passwords.data > /var/www/html/honey/dashboard_passwords.tmp`;
`cat /var/www/html/honey/dashboard_ips.data > /var/www/html/honey/dashboard_ips.tmp`;
`cat /var/www/html/honey/dashboard_number_of_attacks.data > /var/www/html/honey/dashboard_number_of_attacks.tmp`;



open (FILE, ">> /var/www/html/honey/dashboard_number_of_attacks.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);

open (FILE, ">> /var/www/html/honey/dashboard_ips.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);

open (FILE, ">> /var/www/html/honey/dashboard_usernames.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);
open (FILE, ">> /var/www/html/honey/dashboard_passwords.tmp");
$count=0;
while ($count < $lines_needed){print (FILE "0 \n");$count++;}
close (FILE);

`php /usr/local/etc/LongTail_make_graph.php /var/www/html/honey/dashboard_usernames.tmp "Unique Username Count $DATE $TIME" "" "" "wide"> /var/www/html/honey/dashboard_usernames.png`;
`php /usr/local/etc/LongTail_make_graph.php /var/www/html/honey/dashboard_passwords.tmp "Unique Password Count $DATE $TIME" "" "" "wide"> /var/www/html/honey/dashboard_passwords.png`;
`php /usr/local/etc/LongTail_make_graph.php /var/www/html/honey/dashboard_ips.tmp "Unique IP Count $DATE $TIME" "" "" "wide"> /var/www/html/honey/dashboard_ips.png`;
`php /usr/local/etc/LongTail_make_graph.php /var/www/html/honey/dashboard_number_of_attacks.tmp "Number Of Attacks $DATE $TIME" "" "" "wide"> /var/www/html/honey/dashboard_number_of_attacks.png`;
