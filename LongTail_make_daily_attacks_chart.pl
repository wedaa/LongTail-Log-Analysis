#!/usr/bin/perl
# Written by Eric Wedaa 2015-03
# This is absolutely horrible looking code, but it works
# and I don't see you writting anything better :-)
#

#chdir ("/var/www/html/honey/historical") || die "can not chdir\n";;
chdir ("$ARGV[0]") || die "can not chdir to $ARGV[0] \n";;
print "<HTML><BODY><TABLE border=1 >\n";

open (YEAR, "/bin/ls  -d 2*|");
while (<YEAR>){
	chomp;
	$year=$_;
	chdir $year;
	open (MONTH, "/bin/ls -d ??|");
	while (<MONTH>){
		chomp;
		$month=$_;
		$string=`cal $month $year`;
		$string =~ s/\n/ \n /g;
		$string =~ s/^ +//;
	
		chdir $month;
		open (DAY, "/bin/ls -d ??|");
		while (<DAY>){
			chomp;
			$day=$_;
			$value="NA";
			open (FILE, "$day/current-attack-count.data") ;
			while (<FILE>){
				$value=$_;
			}
			close (FILE);
			chomp $value;
			$day =~ s/^0//;
			$string =~ s/ $day / $day\/$value /g;
		}
		chdir ("..");
		$string =~ s/\n /\n/g;
		$string =~ s/\n /\n/g;
		$string =~ s/  1/<TD>1<\/TD>/g;
		$string =~ s/   /<TD>&nbsp<\/TD>/g;
		$string =~ s/  / /g;
		$string =~ s/<TD><\/TD>\n/\n/g;
		$string =~ s/<TD><\/TD>\n/\n/g;
		$string =~ s/<TD><\/TD>\n/\n/g;
		$string =~ s/^/<TR><TD>/;
		$string =~ s/\n/<\/TD><\/TR>\n<TR><TD>/g;
		$string =~ s/ <\/TD>/<\/TD>/g;
		$string =~ s/ /<\/TD><TD>/g;
		$string =~ s/\n<TR><TD><TD>/\n<TR><TD>/g;
		$string =~ s/<\/TD><\/TD>/<\/TD>/g;
		$string =~ s/<\/TD><\/TD>/<\/TD>/g;
		$string =~ s/<TR><TD><\/TD><\/TR>//g;
		$string =~ s/<TD>&nbsp<\/TD><\/TR>/<\/TD><\/TR>/g;
		$string =~ s/<TD>&nbsp<\/TD><\/TR>/<\/TD><\/TR>/g;
		$string =~ s/<TD>&nbsp<\/TD><\/TD><\/TR>/<\/TD><\/TR>/g;

		print $string;
	}
	chdir ("..");
}
print "</TABLE></BODY></HTML>\n";
