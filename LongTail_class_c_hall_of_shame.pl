#!/usr/bin/perl

############################################################################
# adds commas to numbers so they are readable
# 
sub commify {
  my ( $sign, $int, $frac ) = ( $_[0] =~ /^([+-]?)(\d*)(.*)/ );
  my $commified = (
  reverse scalar join ',',
  unpack '(A3)*',
  scalar reverse $int
  );
  return $sign . $commified . $frac;
}


sub this_month_hall_of_shame {
	my %my_array;
	my $count;
	chdir ("/var/www/html/honey/attacks/");
	`find .  -name '*.*.*.*-$YEAR.$MONTH.*'  |sed 's/^..//' >/tmp/LongTail.hall.of.shame.$$`;
	
	open (FILE, "/tmp/LongTail.hall.of.shame.$$");
	while (<FILE>){
		($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
		$my_array{"$ip1.$ip2.$ip3"}++;
	}
	close (FILE);
	open (OUTPUT, ">/tmp/all_class_c.$$") ||die "Can not write to /tmp/all_class_c.$$\n";
	#
	# This sorts by number of attacks :-)
	#
	foreach my $name (keys %my_array) {
                print (OUTPUT "$name $my_array{$name}\n");
        }
	close (OUTPUT);
	system ("sort -nrk2 /tmp/all_class_c.$$ > /tmp/all_class_c.$$.tmp");
	unlink ("/tmp/all_class_c.$$");
	system ("mv /tmp/all_class_c.$$.tmp /tmp/all_class_c.$$");
	print "</TABLE>\n";
	print "<BR><BR>\n";
	print "<TABLE BORDER=3>\n";
	print "<TR><TH colspan=3>Class C IP ranges with most attacks for $MONTH $YEAR</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
	open (INPUT, "/tmp/all_class_c.$$") ;
	while (<INPUT>){
		chomp;
		($name, $number_of_attacks)=split (/ /,$_);
		$note="";
		if ( -e "/var/www/html/honey/notes/$name" ){
			$note=`cat /var/www/html/honey/notes/$name`;
			chomp $note;
		}
		$number_of_login_attempts=0;
		open (INPUT2, "/var/www/html/honey/attacks/sum2.data");
		while (<INPUT2>){
			if (/$name/){
				($dict,$stuff)=split(/ /,$_);
				open (INPUT3, "/var/www/html/honey/attacks/dict-$dict.txt.wc");
				while (<INPUT3>){
					$number_of_login_attempts+= $_;
				}
				close (INPUT3);
			}
		}
		close (INPUT2);
		chomp $number_of_login_attempts;
#print "number of attacks is $number_of_login_attempts\n";
		if ( $number_of_login_attempts > 10000){
			if ($count < 10){
				printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $number_of_attacks;
				$number_of_login_attempts=&commify($number_of_login_attempts);
				printf "<TD>$number_of_login_attempts</TD></TR>\n";
				$count ++;
			}
			if ($count >= 10){last;}
		}
	}
	close (INPUT);
}


sub this_year_hall_of_shame {
	#`ls *.*.*.*.*-$YEAR.* >/tmp/LongTail.hall.of.shame.$$`;
	my %my_array;
	my $count;
	chdir ("/var/www/html/honey/attacks/");
	`find .  -name '*.*.*.*-$YEAR.*'  |sed 's/^..//' >/tmp/LongTail.hall.of.shame.$$`;
	
	open (FILE, "/tmp/LongTail.hall.of.shame.$$");
	while (<FILE>){
		($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
		$my_array{"$ip1.$ip2.$ip3"}++;
	}
	close (FILE);
	open (OUTPUT, ">/tmp/all_class_c.$$") ||die "Can not write to /tmp/all_class_c.$$\n";
	foreach my $name (keys %my_array) {
                print (OUTPUT "$name $my_array{$name}\n");
        }
	close (OUTPUT);
	system ("sort -nrk2 /tmp/all_class_c.$$ > /tmp/all_class_c.$$.tmp");
	unlink ("/tmp/all_class_c.$$");
	system ("mv /tmp/all_class_c.$$.tmp /tmp/all_class_c.$$");
	print "</TABLE>\n";
	print "<BR><BR>\n";
	print "<TABLE BORDER=3>\n";
	print "<TR><TH colspan=3>Class C IP ranges with most attacks for $YEAR</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
	open (INPUT, "/tmp/all_class_c.$$") ;
	while (<INPUT>){
		chomp;
		($name, $number_of_attacks)=split (/ /,$_);
		$note="";
		if ( -e "/var/www/html/honey/notes/$name" ){
			$note=`cat /var/www/html/honey/notes/$name`;
			chomp $note;
		}
		$number_of_login_attempts=0;
		open (INPUT2, "/var/www/html/honey/attacks/sum2.data");
		while (<INPUT2>){
			if (/$name/){
				($dict,$stuff)=split(/ /,$_);
				open (INPUT3, "/var/www/html/honey/attacks/dict-$dict.txt.wc");
				while (<INPUT3>){
					$number_of_login_attempts+= $_;
				}
				close (INPUT3);
			}
		}
		close (INPUT2);
		chomp $number_of_login_attempts;
		if ( $number_of_login_attempts > 10000){
			if ($count < 10){
				printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $number_of_attacks;
				$number_of_login_attempts=&commify($number_of_login_attempts);
				printf "<TD>$number_of_login_attempts</TD></TR>\n";
				$count ++;
			}
			if ($count >= 10){last;}
		}
	}
	close (INPUT);
}

sub all_class_c {
	my %my_array;
	my $count;
	chdir ("/var/www/html/honey/attacks/");
#OLD	`find .  -name '*.*.*.*.*'  |sed 's/^..//' >/tmp/LongTail.hall.of.shame.$$`;
#OLD	
#OLD	open (FILE, "/tmp/LongTail.hall.of.shame.$$");
#OLD	while (<FILE>){
#OLD		($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
#OLD		$my_array{"$ip1.$ip2.$ip3"}++;
#OLD	}
#OLD	close (FILE);
#OLD	open (OUTPUT, ">/tmp/all_class_c.$$") ||die "Can not write to /tmp/all_class_c.$$\n";
#OLD	# foreach takes forever...
#OLD	if ($DEBUG >0){print "DEBUG Starting foreach loop at:";$TMP_DATE=`date`; print $TMP_DATE;}
#OLD	foreach my $name (keys %my_array) {
#OLD                print (OUTPUT "$name $my_array{$name}\n");
#OLD        }
#OLD	close (OUTPUT);
#OLD	if ($DEBUG >0){print "DEBUG done with foreach loop at:";$TMP_DATE=`date`; print $TMP_DATE;}
#OLD	system ("sort -nrk2 /tmp/all_class_c.$$ > /tmp/all_class_c.$$.tmp");
#OLD	unlink ("/tmp/all_class_c.$$");
#OLD	system ("mv /tmp/all_class_c.$$.tmp /tmp/all_class_c.$$");
#OLD
#OLD	if ($DEBUG >0){print "DEBUG done with sort command at:";$TMP_DATE=`date`; print $TMP_DATE;}
	print "</TABLE>\n";
	print "<BR><BR>\n";
	print "<TABLE BORDER=3>\n";
	print "<TR><TH colspan=3>All Class C IP ranges Sorted By Number Of Attacks</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
#OLD#	foreach my $name (sort { $my_array{$b} <=> $my_array{$a} } keys %my_array) {
#OLD	open (INPUT, "/tmp/all_class_c.$$") ;
#OLD	if ($DEBUG >0){print "DEBUG Starting reading /tmp/all_class_c.$$ at:";$TMP_DATE=`date`; print $TMP_DATE;}
#OLD	while (<INPUT>){
#OLD		chomp;
#OLD		($name, $number_of_attacks)=split (/ /,$_);
#OLD		if ($DEBUG >0){ print "DEBUG name is $name\n";}
#OLD		$note="";
#OLD		if ( -e "/var/www/html/honey/notes/$name" ){
#OLD			$note=`cat /var/www/html/honey/notes/$name`;
#OLD			chomp $note;
#OLD		}
#OLD		#
#OLD		# this was horribly slow too
#OLD		# Can also fail with "bash: /usr/bin/wc: Argument list too long"
#OLD		#
#OLD		#$number_of_login_attempts=`cat $name* |wc -l`;
#OLD
#OLD		#
#OLD		# Damn, I'm reading this file a bazillion times
#OLD		# If there are 11,000 Class C spaces, then I
#OLD		# read this file 11,000 times.  This sucks.
#OLD		#
#OLD		# I need to make this significantly faster
#OLD		# 2015-12-30 ericw
#OLD		#
#OLD		# Here's a hint:
#OLD		# sort sum2 by IP address, calculate totals, write to a
#OLD		# temp file, then sort and print the temp file to the 
#OLD		# output file.
#OLD		# sort -nr  -t\> -k5 /var/www/html/honey//class_c_list.shtml
#OLD		#
#OLD		$number_of_login_attempts=0;
#OLD		open (INPUT2, "/var/www/html/honey/attacks/sum2.data");
#OLD		while (<INPUT2>){
#OLD			if (/$name/){
#OLD				($dict,$stuff)=split(/ /,$_);
#OLD				open (INPUT3, "/var/www/html/honey/attacks/dict-$dict.txt.wc");
#OLD				while (<INPUT3>){
#OLD					$number_of_login_attempts+= $_;
#OLD				}
#OLD				close (INPUT3);
#OLD			}
#OLD		}
#OLD		close (INPUT2);
#OLD		chomp $number_of_login_attempts;
#OLD		printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $number_of_attacks;
#OLD		$number_of_login_attempts=&commify($number_of_login_attempts);
#OLD		printf "<TD>$number_of_login_attempts</TD></TR>\n";
#OLD	}
#OLD	close (INPUT);


	$count=1;
	$t2=0;
	$number_of_login_attempts=0;
	$number_of_attacks=0;
	`sed 's/  /\.\./'  /var/www/html/honey/attacks/sum2.data | sort -n -t . -k 3,3n -k 4,4n -k 5,5n |sed \'s/\\.\\./  /\' > /var/www/html/honey/attacks/sum2.data.sorted`;

	$prior_class_c="";
	open (INPUT2, "/var/www/html/honey/attacks/sum2.data.sorted");
	open (OUTPUT2, ">/var/www/html/honey/attacks/sum2.data.sorted.out");
	while (<INPUT2>){
		($dict,$ip1,$ip2,$ip3,$trash)=split(/\s+|\./,$_,5);
		#print "debug $ip1,$ip2,$ip3\n";
		$this_class_c="$ip1.$ip2.$ip3";
		if ( $prior_class_c ne $this_class_c ) {
			if ( $prior_class_c ne "" ) {
				print (OUTPUT2 "$prior_class_c $number_of_attacks $number_of_login_attempts\n");
				$number_of_login_attempts=0;
				$number_of_attacks=0;
			}
			$prior_class_c = $this_class_c ;
		}
		open (INPUT3, "/var/www/html/honey/attacks/dict-$dict.txt.wc");
		while (<INPUT3>){
			$number_of_login_attempts+= $_;
			$number_of_attacks++;
		}
		close (INPUT3);
	}
	close (INPUT2);
	close (OUTPUT2);
	`sort -nr -k2 /var/www/html/honey/attacks/sum2.data.sorted.out >/var/www/html/honey/attacks/sum2.data.sorted.out2`;
	open (INPUT, "/var/www/html/honey/attacks/sum2.data.sorted.out2");
	while (<INPUT>){
		chomp;
		($class_c,$number_of_attacks,$number_of_login_attempts)=split(/\s/,$_,3);
		if ( -f "/var/www/html/honey/notes/$class_c" ){
			$note=`cat /var/www/html/honey/notes/$class_c`;
			chomp $note;
		}
		print "<TR><TD>$class_c $note</TD><TD>$number_of_attacks</TD>";
		$number_of_login_attempts=&commify($number_of_login_attempts);
		print "<TD>$number_of_login_attempts</TD></TR>\n";
		$note="";
	}
	close (INPUT);
	unlink ("/var/www/html/honey/attacks/sum2.data.sorted");
	unlink ("/var/www/html/honey/attacks/sum2.data.sorted.out");
	unlink ("/var/www/html/honey/attacks/sum2.data.sorted.out2");


	if ($DEBUG >0){print "DEBUG Done reading /tmp/all_class_c.$$ at:";$TMP_DATE=`date`; print $TMP_DATE;}
	unlink ("/tmp/all_class_c.$$") ;
}
#####################################################################
#
# Main line of code
#

$|=1;
$DEBUG=0;
$YEAR=`date +%Y`;
chomp $YEAR;
$MONTH=`date +%m`;
chomp $MONTH;
chdir ("/var/www/html/honey/attacks/");
if ( "$ARGV[0]" eq "ALL" ){
	&all_class_c;
}
else {
	&this_month_hall_of_shame;
	&this_year_hall_of_shame;
}

unlink ("/tmp/LongTail.hall.of.shame.$$");
