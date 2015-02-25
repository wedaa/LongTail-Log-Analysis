#!/usr/bin/perl
# data format 2014-09-09T05:25:15-04:00 login sshd[30843]: refused connect from 218.241.153.80 (218.241.153.80)
#
sub init {
	use Time::Local;
	%mon2num = qw(
	jan 1  feb 2  mar 3  apr 4  may 5  jun 6
	jul 7  aug 8  sep 9  oct 10 nov 11 dec 12
	);
	$|=1;
	$DEBUG=0;
	$attacks_dir="/tmp/";
	$DATE=`date`;
}

&init;

# Just cat all the files to the script
while (<>){
	($time1,$trash)=split(/ /,$_,2);
	if ( /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/){
		#print "$1\n";
		$ip=$1;
		($date,$time)=split(/T/,$time1,2);
		($time,$tmp)=split(/-/,$time,2);
		($year,$month,$day)=split(/-/,$date,3);
		($hour,$minutes,$second)=split(/:/,$time,3);
		$epoch=timelocal($second,$minutes,$hour,$day,$month-1,$year);
		$first_seen=scalar localtime($epoch);
		if (! defined $ip_epoch{$ip}) {
			$ip_earliest_seen_time{$ip}=$epoch;
			$ip_latest_seen_time{$ip}=$epoch;
		}
		$ip_epoch{$ip}=$epoch;
		$ip_attacks{$ip}++;
		if ($epoch < $ip_earliest_seen_time{$ip}){ $ip_earliest_seen_time{$ip}=$epoch;}
		if ($epoch > $ip_latest_seen_time{$ip}){ $ip_latest_seen_time{$ip}=$epoch;}
		$ip_age{$ip}=$ip_latest_seen_time{$ip}-$ip_earliest_seen_time{$ip};
	}
}
print "Epoch time, ip address, age in days, first seen date, last seen date, number of attacks\n";
foreach $key (sort {$ip_age{$b} <=> $ip_age{$a}} keys %ip_age){
	#if ( $DEBUG){print "key is $key\n";}
	$days=$ip_age{$key}/60/60/24;
	$first_seen=scalar localtime($ip_earliest_seen_time{$key});
	$last_seen=scalar localtime($ip_latest_seen_time{$key});
	printf("%d, %s,  %.2f,  %s,  %s,  %d\n", $ip_age{$key}, $key, $days,$first_seen, $last_seen, $ip_attacks{$key});
}
