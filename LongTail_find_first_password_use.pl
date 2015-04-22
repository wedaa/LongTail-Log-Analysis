#!/usr/bin/perl

if ($ARGV[0] eq "passwords"){ $file="todays_password"; $search_for="Passwords"; }
if ($ARGV[0] eq "usernames"){ $file="todays_username";  $search_for="Usernames";}
if ($ARGV[0] eq "ips"){ $file="todays_ips";  $search_for="IP Addresses";}
if (! defined ($search_for)){
	print "You forgot to specify what to look for, exiting now.\n";
	exit;
}

chdir "/var/www/html/honey/historical";

open (FIND_YEAR, "ls |") || die "Can not run ls is /var/www/html/honey/historical, exiting now\n";
while (<FIND_YEAR>){
	chomp;
	$year=$_;
	#print "year is $year, ";
	chdir $year;

	open (FIND_MONTH, "ls |") || die "Can not run ls is /var/www/html/honey/historical/$year, exiting now\n";;
	while (<FIND_MONTH>){
		chomp;
		$month=$_;
		#print "month is $month, ";
		chdir $month;

		open (FIND_DAY, "ls |") || die "Can not run ls is /var/www/html/honey/historical/$year/$month, exiting now\n";;
		while (<FIND_DAY>){
			chomp;
			$day=$_;
			#print "day is $day\n";
			chdir $day;
			if ( -e $file){
				open (FILE, $file) || die "Can not open file $file in /var/www/html/honey/historical/$year/$month/$day, exiting now\n";;
				while (<FILE>){
					chomp;
					if (! defined ($password_array{$_})){
						$password_array{$_}="$year-$month-$day";
						$password_last_seen_array{$_}="$year-$month-$day";
						$password_count++;
					}
					else {
						$password_last_seen_array{$_}="$year-$month-$day";
					}
				}
				close (FILE);
			}
			chdir "..";
		}
	chdir "..";
	}
chdir "..";
}

open (OUTPUT, ">$file.$$") || die "Can not open $dir/$file.$$, exiting now\n";;
while (($password, $date) = each(%password_array)){
	if (($search_for eq "Usernames" ) || ($search_for eq "IP Addresses")){
		print (OUTPUT "<TR><TD>$date&nbsp;</TD><TD>$password_last_seen_array{$password}&nbsp;</TD><TD align=left>$password</TD></TR>\n");
	}
	else {
		print (OUTPUT "$date $password_last_seen_array{$password} $password\n");
	}
}
close (OUTPUT); 
print "<TABLE>\n";
print "<TR><TH colspan=3>$search_for count is $password_count</TH></TR>\n";
print "<TR><TH>First Seen</TH><TH>Last Seen</TH><TH>$search_for</TH></TR>\n";

system ("sort $file.$$ ");
unlink ("$file.$$");

#print "</TABLE>\n";
