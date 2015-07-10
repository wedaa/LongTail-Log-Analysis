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
	`find .  -name '*.*.*.*.*'  |sed 's/^..//' >/tmp/LongTail.hall.of.shame.$$`;
	
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
	print "<TR><TH colspan=3>All Class C IP ranges Sorted By Number Of Attacks</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
#	foreach my $name (sort { $my_array{$b} <=> $my_array{$a} } keys %my_array) {
	open (INPUT, "/tmp/all_class_c.$$") ;
	while (<INPUT>){
		chomp;
		($name, $number_of_attacks)=split (/ /,$_);
		$note="";
		if ( -e "/var/www/html/honey/notes/$name" ){
			$note=`cat /var/www/html/honey/notes/$name`;
		}
		#$number_of_login_attempts=`cat $name* |wc -l`;
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
		printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $number_of_attacks;
		$number_of_login_attempts=&commify($number_of_login_attempts);
		printf "<TD>$number_of_login_attempts</TD></TR>\n";
	}
	close (INPUT);
	unlink ("/tmp/all_class_c.$$") ;
}

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
