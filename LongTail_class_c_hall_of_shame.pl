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


chdir ("/var/www/html/honey/attacks/");
`ls *.*.*.*.* >/tmp/ericw2`;

open (FILE, "/tmp/ericw2");
while (<FILE>){
	($ip1,$ip2,$ip3,$trash)=split (/\./,$_);
	$my_array{"$ip1.$ip2.$ip3"}++;
}
close (FILE);
foreach my $name (sort { $my_array{$b} <=> $my_array{$a} } keys %my_array) {
	$number_of_attacks=`cat $name* |wc -l`;
	chomp $number_of_attacks;
	if ( $number_of_attacks > 10000){
		printf "<TR><TD>%s</TD><TD>%d</TD>", $name, $my_array{$name};
		$number_of_attacks=&commify($number_of_attacks);
		printf "<TD>$number_of_attacks</TD></TR>\n";
	}
}
