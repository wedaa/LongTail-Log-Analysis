#!/usr/bin/perl

# 2016-05-02 Bug fix so that it only counts SSH attacks, instead
#            of ALL attacks (including http and telnet, etc).
#
# Rebuilds dashboard images a day at a time
#
# Called as:
#   /usr/local/etc/LongTail_make_historical_dashboard_charts.pl /var/www/html/honey/historical/2015/01/04


$dir=$ARGV[0];
$DATE=$ARGV[0];
$DATE =~ s/historical\///;
$DATE =~ s/\/var\/www\/html\/honey\///;
$DATE =~ s/\//-/g;
print "DATE is -->$DATE<--\n";

if ( ! -d $dir) {
	print "$dir is not a directory, exiting now\n";
	exit;
}

#current-attack-count.data
#todays_username.count
#todays_password.count
#todays_ips.count

chdir "$dir"; # Change to the date we are looking at rebuilding
chdir "..";   # And then, change up one directory
#
# Yes, I recalculate min, average, max everytime I run the script.
# It's not worth it to optimize this at this point in time.
# This script runs once a month, so I'd rather spend my time
# optimizing other things that run all the time.
# Ericw

open (FIND, "find . -name current-attack-count.data|");
$count=0;
$total=0;
$min_attack=1000000;
$max_attack=0;
while (<FIND>){
	chomp;
	$file=$_;
	open (FILE, $file);
	while (<FILE>){
		chomp;
		$total=$total+$_;
		if ($_ < $min_attack){$min_attack=$_;}
		if ($_ > $max_attack){$max_attack=$_;}
	}
	close (FILE);
	$count++;
}
$average_attack=$total/$count;
$average_attack=sprintf("%.2f",$average_attack);
#print "min is $min_attack, max is $max_attack, average is $average_attack\n";

open (FIND, "find . -name todays_username.count|");
$count=0;
$total=0;
$min_username=1000000;
$max_username=0;
while (<FIND>){
	chomp;
	$file=$_;
	open (FILE, $file);
	while (<FILE>){
		chomp;
		$total=$total+$_;
		if ($_ < $min_username){$min_username=$_;}
		if ($_ > $max_username){$max_username=$_;}
	}
	close (FILE);
	$count++;
}
$average_username=$total/$count;
$average_username=sprintf("%.2f",$average_username);

open (FIND, "find . -name todays_password.count|");
$count=0;
$total=0;
$min_password=1000000;
$max_password=0;
while (<FIND>){
	chomp;
	$file=$_;
	open (FILE, $file);
	while (<FILE>){
		chomp;
		$total=$total+$_;
		if ($_ < $min_password){$min_password=$_;}
		if ($_ > $max_password){$max_password=$_;}
	}
	close (FILE);
	$count++;
}
$average_password=$total/$count;
$average_password=sprintf("%.2f",$average_password);

open (FIND, "find . -name todays_ips.count|");
$count=0;
$total=0;
$min_ip=1000000;
$max_ip=0;
while (<FIND>){
	chomp;
	$file=$_;
	open (FILE, $file);
	while (<FILE>){
		chomp;
		$total=$total+$_;
		if ($_ < $min_ip){$min_ip=$_;}
		if ($_ > $max_ip){$max_ip=$_;}
	}
	close (FILE);
	$count++;
}
$average_ip=$total/$count;
$average_ip=sprintf("%.2f",$average_ip);


#2015-01-04T23:38:20 shepherd sshd[23322]: IP: 122.225.103.103 PassLog: Username: root Password: 123567
$file="$dir/current-raw-data.gz";

#
# Now we go back to the individual directory
chdir "$dir";

#
# Pass 1, unique IPs
#
$hour=0;
$minute=0;

$minute_count=0;
while ($minute_count < 1441){
	$time_attacks[$minute_count]=0;
	$time_username_count[$minute_count]=0;
	$time_password_count[$minute_count]=0;
	$time_ip_count[$minute_count]=0;
	$minute_count++;
}
#print "DEBUG ". $time_ip_count[0] . "\n";


open (FILE, "zcat $file|sort|");
while (<FILE>){
	if (/IP:/){
		if (( /PassLog/)||(/Pass2222Log/)){ # Look at only ssh
			chomp;
			$time = $_;
			$time =~ s/ ..*$//;
			$time =~ s/^.*T//;
			$time =~ s/:..$//;
			($log_hour , $log_minute)=split(/:/,$time);
			$minute_number=($log_hour*60)+$log_minute;


			$password=$_;
			$password=~ s/^..*Password: //;
			#print "password is $password\n";
			$password_array{$password}=1;
			$size=keys (%password_array);
			$time_password_count[$minute_number]=$size;

			$username=$_;
			$username=~ s/^..*Username: //;
			$username=~ s/ Password:.*$//;
			#print "username is $username\n";
			$username_array{$username}=1;
			$size=keys (%username_array);
			$time_username_count[$minute_number]=$size;

			$ip=$_;
			$ip =~ s/^..*IP: //;
			$ip =~ s/ Pass..*$//;
			#print "ip is $ip\n";
			$ip_array{$ip}=1;
			$size=keys (%ip_array);
			$time_ip_count[$minute_number] = $size ;
	#print "DEBUG-loading time_ip_count array, minute is $minute_number, ip size is $size\n";
	
			$time_attacks[$minute_number]++;
		}
	}
}
close (FILE);

open (ATTACK_FILE, ">$dir/dashboard_number_of_attacks.data");
open (IPS_FILE, ">$dir/dashboard_ips.data");
open (USERNAME_FILE, ">$dir/dashboard_usernames.data");
open (PASSWORD_FILE, ">$dir/dashboard_passwords.data");
$minute_count=0;
$last_ip_count_seen=0;
$last_username_count_seen=0;
$last_password_count_seen=0;
$last_attack_count_seen=0;

while ($minute_count < 1440){
	$running_total_of_attacks+=$time_attacks[$minute_count];
	$minute = $minute_count % 60;
	$hour=int $minute_count / 60;
	if ($minute < 10){
		$time="$hour:0$minute";
	}
	else {
		$time="$hour:$minute";
	}

	if (( $minute_count % 5) == 0){
		if (( $minute_count % 30) != 0){$time = "";}

		if ( $time_ip_count[$minute_count] > 0) {
			print (IPS_FILE $time_ip_count[$minute_count] . " $time\n");
			#print "$minute_count ".$time_ip_count[$minute_count] . " $time\n";
			$last_ip_count_seen = $time_ip_count[$minute_count] ;
		}
		else {
			#print "$minute_count ".$time_ip_count[$minute_count] . " $time\n";
			print (IPS_FILE "$last_ip_count_seen $time\n");
		}

		if ($time_username_count[$minute_count] >0 ){
			print (USERNAME_FILE $time_username_count[$minute_count] . " $time\n");
			$last_username_count_seen = $time_username_count[$minute_count] ;
		}
		else {
			print (USERNAME_FILE "$last_username_count_seen $time\n");
		}


		if ( $time_password_count[$minute_count] > 0){
			print (PASSWORD_FILE $time_password_count[$minute_count] . " $time\n");
			$last_password_count_seen = $time_password_count[$minute_count] ;
		}
		else {
			print (PASSWORD_FILE "$last_password_count_seen $time\n");
		}

		if ($time_attacks[$minute_count] >0){
			print (ATTACK_FILE $running_total_of_attacks . " $time\n");
		}
		else {
			print (ATTACK_FILE "$running_total_of_attacks $time\n");
		}
	}
	$minute_count++;
}

`php /usr/local/etc/LongTail_make_dashboard_graph.php $dir/dashboard_passwords.data "Unique Password Count $DATE " "" "" "wide" $min_password $max_password $average_password $max_password > /var/www/html/honey/dashboard/dashboard_passwords-$DATE.png`;

`php /usr/local/etc/LongTail_make_dashboard_graph.php $dir/dashboard_usernames.data "Unique Username Count $DATE " "" "" "wide" $min_username $max_username $average_username  $max_username > /var/www/html/honey/dashboard/dashboard_usernames-$DATE.png`;

`php /usr/local/etc/LongTail_make_dashboard_graph.php $dir/dashboard_ips.data "Unique IP Count $DATE " "" "" "wide" $min_ip $max_ip $average_ip $max_ip > /var/www/html/honey/dashboard/dashboard_ips-$DATE.png`;

`php /usr/local/etc/LongTail_make_dashboard_graph.php $dir/dashboard_number_of_attacks.data "Number Of Attacks $DATE " "" "" "wide" $min_attack $max_attack $average_attack $max_attack > /var/www/html/honey/dashboard/dashboard_number_of_attacks-$DATE.png`;


