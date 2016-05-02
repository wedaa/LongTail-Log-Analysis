#!/usr/bin/perl
# You must run the following commands so that geo-location works
# and you must download the latest databases after the second tuesday
# of each month
#
# 2016-05-02 Bug fix so that it only counts SSH attacks, instead
#            of ALL attacks (including http and telnet, etc).
#
# yum install cpan
#cpan Geo::IP
#cpan Socket6
#mkdir /usr/local/share/GeoIP
#mkdir /usr/local/share/GeoIP/backups # Will be used to store older copies of database files
#cd /usr/local/share/GeoIP
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
#wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
#gunzip GeoIP.dat.gz
#gunzip GeoLiteCity.dat.gz
#gunzip GeoIPv6.dat.gz
#

use strict;
use warnings;
use DBI;
use Geo::IP;
use File::Tail;
my $old_files;
my $valid_action;
my $DEBUG=0;
my $INPUT;
my $new_record;
my $record;
my $print_record;
my $account;
my $host;
my $what;
my $password;
my $files;
my $ip;
my $trash ;
my $who;
my $action;
my $date;
my $munged_date;
my $munged_time;
my $dbh;
my @date_array;
my $country;
my $city;
my $line_counter;
my $today_day;
my $today_month;
my $today_year;
my $today;
my $yesterday_day;
my $yesterday_month;
my $yesterday_year;
my $yesterday;
my $last_month;
my $last_year; # This is really used to figure out what year last_month is in
my $timeout=60; # Wait time in seconds before re-trying a write to myql
my $mail_errors_to="eric.wedaa\@marist.edu";
#my $mail_errors_to="eric.wedaa\@marist.edu";
my $retry_again="no";
my $dev;
my $ino;
my $mode;
my $nlink;
my $uid;
my $gid;
my $rdev;
my $size;
my $atime;
my $mtime;
my $ctime;
my $blksize;
my $blocks;
my $filesize;
my $old_size;
my $current_size;



######################################################################
#
# Initialize a bunch of stuff
#
sub init {
	$|=1;
	$today_day=`date  +"%d" --date="1 day ago"`;
	chomp $today_day;
	$today_month=`date  +"%m" --date="1 day ago"`;
	chomp $today_month;
	$today_year=`date  +"%Y" --date="1 day ago"`;
	chomp $today_year;
	$today="$today_year-$today_month-$today_day";

	$yesterday_day=`date  +"%d"`;
	chomp $yesterday_day;
	$yesterday_month=`date  +"%m"`;
	chomp $yesterday_month;
	$yesterday_year=`date  +"%Y"`;
	chomp $yesterday_year;
	$yesterday="$yesterday_year-$yesterday_month-$yesterday_day";

	$last_month=`date  +"%m" --date="last month"`;
	chomp $last_month;
	$last_year=`date  +"%Y" --date="last month"`;
	chomp $last_year;

	$new_record=0;
	$record="";
	$print_record=0;
	$account="LongTail";
	$host="longtail.it.marist.edu";
	$password="lo96hjmsow";
	$country="";
	$city="";
	$line_counter=0;

	if ( -d "/var/www/html/honey/historical/$yesterday_year/$yesterday_month/$yesterday_day" ){
		chdir "/var/www/html/honey/historical/$yesterday_year/$yesterday_month/$yesterday_day";
	}
	else {
		print "Can not cd to /var/www/html/honey/historical/$yesterday_year/$yesterday_month/$yesterday_day, exiting now!\n";
		exit;
	}
}

sub geolocate_ip{
  my $ip=shift;
	my $local_ip_1;
	my $local_ip_2;
	$local_ip_1="10\\.";
	$local_ip_2="148.100";

	#print (STDERR "In geolocate for $ip\n");
	my $tmp;
	my $tmp2;
	if ($ip =~ /^$local_ip_1/){return ("US-Marist:Poughkeepsie");}
	if ($ip =~ /^$local_ip_2/){return ("US-Marist:Poughkeepsie");}
	#print (STDERR "Foo\n");
	my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
	my $record = $gi->record_by_addr($ip);
	#print $record->country_code,
	#      $record->country_code3,
	#      $record->country_name,
	#      $record->region,
	#      $record->region_name,
	#      $record->city,
	#      $record->postal_code,
	#      $record->latitude,
	#      $record->longitude,
	#      $record->time_zone,
	#      $record->area_code,
	#      $record->continent_code,
	#      $record->metro_code;
	# ericw note: I have no idea what happens if there IS a record
	# but there is no country code
	undef ($tmp);
	if (defined $record){
		$tmp=$record->country_name;
		$tmp2=$record->city;
		return ("$tmp:$tmp2");
	}
	else {
		return ("undefined:undefined");
	}
}


sub geo_locate_country{
	$ip=shift;
	my $tmp;
  my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
  my $record = $gi->record_by_addr($ip);
	# ericw note: I have no idea what happens if there IS a record
	# but there is no country code
	undef ($tmp);
	if (defined $record){
		$tmp=$record->country_code;
		return ($tmp);
	}
	return ("undefined");
}


sub read_file {
	my $file=shift;
	my $tmp;
	my $date_ok;
	my $munged_month;
	my $date;
	my $name;
	my $time;
	my $line;
	my $tmp_date;
	my $file_handle;
	my %months=("Jan","01",
	"Feb","02",
	"Mar","03",
	"Apr","04",
	"May","05",
	"Jun","06",
	"Jul","07",
	"Aug","08",
	"Sep","09",
	"Oct","10",
	"Nov","11",
	"Dec","12");

	my $dbh = DBI->connect("DBI:mysql:database=shibboleth_logins;host=$host",
		"$account", "$password",
		{'RaiseError' => 1});
	if ($@) {
		print "Can't connect to mysql database on $host, exiting now\n";
		`logger "$0 can't connect to mysql database on $host, failure,  exiting now"`;
		`echo "This is bad, NOT adding Shibboleth IDP logins to database" |mailx -s "import_idp-process.log-to-mysql-tail.pl can not connect to mysql database on $host, failure,  exiting now" $mail_errors_to`;
	}

	
	# Create a new table 'foo' if it does not exist already. 
	# This must not fail, thus we don't catch errors.
	#$dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");
	
	#CREATE TABLE `login_attempts` (
	#  `ticket` varchar(80) NOT NULL,
	#  `hostname` varchar(30) DEFAULT NULL,
	#  `date` date DEFAULT NULL,
	#  `time` time DEFAULT NULL,
	#  `username` varchar(100) DEFAULT NULL,
	#  `src_ip` varchar(15) DEFAULT NULL,
	#  `src_as` varchar(20) DEFAULT NULL,
	#  `src_country` varchar(40) DEFAULT NULL,
	#  `src_city` varchar(40) DEFAULT NULL,
	#  `action` varchar(40) DEFAULT NULL,
	#  PRIMARY KEY (`ticket`)
	#) ;

	
	chomp $file;
	print (STDERR "Looking at $file now\n");
	if ($file =~ /.gz/){
		#open (FILE, "zcat $file|") || die "Can not open $file for reading\n";
		if ($action eq "-tail"){
			print "Something is wrong, tail should NEVER be on a compressed file\n";
			exit;
		}
	}
	else {
		if ($action eq "-tail"){
			  $file_handle=File::Tail->new("$file");
		}
		else {
			print "You should never get here, exiting now\n";
		}
	}
	
	$date_ok=0;
	while (defined($line=$file_handle->read)) {
		# It's ok if the file rotates as I am not using line-numbers 
		# as part of the index field since we have millisecond accuracy.
		$_ = $line;
		chomp;
		$line_counter++;
		if (/Successfully authenticated/){
			($date,$time,$trash,$trash,$trash,$trash,$ip,$trash,$trash,$trash,$trash,$name)=split (/ /,$_);
			$tmp=&geolocate_ip($ip);
			($country,$city)=split(/:/,$tmp);
			$what="$date $time $name";
			$dbh->do("INSERT ignore INTO login_attempts VALUES ('$what','idp.it.marist.edu','$date','$time'," . $dbh->quote("$name")  . ",'$ip',''," . $dbh->quote("$country") . ",'$city','ValidLogin') ");

			if ($@){
				print (STDERR "THIS is bad, could not insert into database\n");
				print (STDERR "Will retry.\n");
				# I'd better get the file size so I can see if the log 
				# was rotated while I was stuck here.
				($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$current_size,
				$atime,$mtime,$ctime,$blksize,$blocks)
				= stat($files);

				`logger "$0 Could not write to mysql database, trying again..."`;
				$retry_again="yes";
				while ( $retry_again eq "yes"){
					sleep ($timeout);
					#
					# Let's try and open the database again
					#
					eval {$dbh = DBI->connect("DBI:mysql:database=shibboleth_logins;host=$host",
					"$account", "$password",
					{'RaiseError' => 1}) };
					if ($@) {
						print (STDERR "Can't connect to mysql database on $host\n");
					`logger "$0 can't connect to mysql database on $host, failure,  sleeping now"`;
					}
					eval { $dbh->do("INSERT ignore INTO login_attempts VALUES ('$what','login.marist.edu','$munged_date','$munged_time'," . $dbh->quote("$who")  . ",'$ip',''," . $dbh->quote("$country") . ",'$city','$action') ")};
					if ($@){
						print (STDERR "THIS is bad, insert into database failed again, failure\n");
						print (STDERR "Entry was lost, failure.\n");
						print (STDERR "Exiting now DANGER.\n");
						`logger "$0 Could not write to mysql database again, will keep trying "`;
						open (FILE, ">/opt/tomcat/logs/write_to_mysql_failed");
						($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
						$atime,$mtime,$ctime,$blksize,$blocks)
						= stat($files);
						print (FILE "$size\n");
						close (FILE);
					}
					else {
						unlink ("/opt/tomcat/logs/write_to_mysql_failed");
						$retry_again="no";
						# Check here to see if the file shrank while we were 
						# stuck waiting....  Toss a warning and an email if it did
					}
				}
			}
		}
		if (/User authentication for.* failed/){
			($date,$time,$trash,$trash,$trash,$trash,$ip,$trash,$trash,$trash,$trash,$name)=split (/ /,$_);
			$tmp=&geolocate_ip($ip);
			($country,$city)=split(/:/,$tmp);
			$what="$date $time $name";
			$dbh->do("INSERT ignore INTO login_attempts VALUES ('$what','idp.it.marist.edu','$date','$time'," . $dbh->quote("$name")  . ",'$ip',''," . $dbh->quote("$country") . ",'$city','FailedLogin') ");
		}

	}
	$tmp_date=`date`;
	chomp $tmp_date;
	print "Exited from while loop, this should never happen!  This was at $tmp_date\n";
	# Disconnect from the database.
	$dbh->disconnect();
}

&init;
$action=$ARGV[0];
$valid_action=0;
if (! defined ($action)){
	$action="";
}

if ($action eq "-tail"){
	print "Tailing the file now\n";
	$files="idp-process.log";
	if ( $files ne "" ){
		print "this month's file found: $files\n";
		&read_file ("$files");
		print "Back from read_file, this should never happen!\n";
		exit;
	}
	else {
		print "Could not find this month's file $files\n";
	}
	$valid_action=1;
}
if ($valid_action < 1 ){
	print "No valid action found, printing help screen now\n";
	$action ="-help";
}
if (($action eq "-help") || ($valid_action < 1 )){
	print "\n";
	print "/usr/local/sbin/import_idp-process.log-to-mysql-tail.pl -help || -tail \n";
	print "  -tail will tail the idp-process.log file add add entries as appropriate forever.\n";
	print "  -help will show this screen\n";
	print "Please also see /usr/local/sbin/import_idp-process.log-to-mysql.pl\n";
	print "\n";
}
