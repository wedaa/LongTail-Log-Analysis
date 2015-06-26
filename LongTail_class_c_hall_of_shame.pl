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
	`ls *.*.*.*-$YEAR.$MONTH.* >/tmp/LongTail.hall.of.shame.$$`;

	open (FILE, "/tmp/LongTail.hall.of.shame.$$");
	while (<FILE>){
		($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
		$my_array{"$ip1.$ip2.$ip3"}++;
	}
	close (FILE);
	
	print "<TR><TH colspan=3>Class C IP ranges with most attacks for $MONTH $YEAR</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
	$count=0;
	foreach my $name (sort { $my_array{$b} <=> $my_array{$a} } keys %my_array) {
		$note="";
		if ( -e "/var/www/html/honey/notes/$name" ){
			$note=`cat /var/www/html/honey/notes/$name`;
		}
		$number_of_attacks=`cat $name* |wc -l`;
		chomp $number_of_attacks;
		if ( $number_of_attacks > 10000){
			if ($count < 10){
				printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $my_array{$name};
				$number_of_attacks=&commify($number_of_attacks);
				printf "<TD>$number_of_attacks</TD></TR>\n";
				$count++;
			}
			if ($count >= 10){last;}
		}
	}
	undef (%my_array);
}


sub this_year_hall_of_shame {
	my %my_array;
	chdir ("/var/www/html/honey/attacks/");
	#`ls *.*.*.*.*-$YEAR.* >/tmp/LongTail.hall.of.shame.$$`;
	`find . -name '*-$YEAR.*' |sed 's/^..//'   >/tmp/LongTail.hall.of.shame.$$`;
	
	open (FILE, "/tmp/LongTail.hall.of.shame.$$");
	while (<FILE>){
		($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
		$my_array{"$ip1.$ip2.$ip3"}++;
	}
	close (FILE);
	print "</TABLE>\n";
	print "<BR><BR>\n";
	print "<TABLE BORDER=3>\n";
	print "<TR><TH colspan=3>Class C IP ranges with most attacks for $YEAR</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
	$count=0;
	foreach my $name (sort { $my_array{$b} <=> $my_array{$a} } keys %my_array) {
		$note="";
		if ( -e "/var/www/html/honey/notes/$name" ){
			$note=`cat /var/www/html/honey/notes/$name`;
		}
		$number_of_attacks=`cat $name* |wc -l`;
		chomp $number_of_attacks;
		if ( $number_of_attacks > 10000){
			if ($count < 10){
				printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $my_array{$name};
				$number_of_attacks=&commify($number_of_attacks);
				printf "<TD>$number_of_attacks</TD></TR>\n";
				$count++;
			}
			if ($count >= 10){last;}
		}
	}
}

sub all_class_c {
	my %my_array;
	chdir ("/var/www/html/honey/attacks/");
	`find .  -name '*.*.*.*.*'  |sed 's/^..//' >/tmp/LongTail.hall.of.shame.$$`;
	
	open (FILE, "/tmp/LongTail.hall.of.shame.$$");
	while (<FILE>){
		($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
		$my_array{"$ip1.$ip2.$ip3"}++;
	}
	close (FILE);
	print "</TABLE>\n";
	print "<BR><BR>\n";
	print "<TABLE BORDER=3>\n";
	print "<TR><TH colspan=3>All Class C IP ranges Sorted By Number Of Attakcs</TD></TR>\n";
	print "<TR> <TH>Class C Address</TH> <TH>Number Of Attacks</TH> <TH>Number Of Login Attempts</TH> </TR> \n";
	foreach my $name (sort { $my_array{$b} <=> $my_array{$a} } keys %my_array) {
		$note="";
		if ( -e "/var/www/html/honey/notes/$name" ){
			$note=`cat /var/www/html/honey/notes/$name`;
		}
		$number_of_attacks=`cat $name* |wc -l`;
		chomp $number_of_attacks;
		printf "<TR><TD>%s $note</TD><TD>%d</TD>", $name, $my_array{$name};
		$number_of_attacks=&commify($number_of_attacks);
		printf "<TD>$number_of_attacks</TD></TR>\n";
	}
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
