#!/usr/bin/perl
######################################################################
# install_openssh.sh
# Written by: Eric Wedaa
# Version: 1.1
# Last Update: 2016-03-04, added checking so I don't try and map more
#              than 20 lines (which would cause a wrong map file that
#              firefox won't understand :-)
#
# LICENSE: GPLV2: Please see the README at 
# https://github.com/wedaa/LongTail-Log-Analysis/blob/master/README.md
#
#######################################################################
#
# Called as LongTail_make_top_20_imagemap.pl /var/www/html/honey/<filename>  
# where filename is something like current-top-20-admin-passwords.data
#
# This is hard because there aren't always 20 lines of data...
#
#print $ARGV[0];

if ( ! -e $ARGV[0] ){
	print (STDERR "Can't fine file $ARGV[0], exiting now\n");
	exit;
}
$image=$ARGV[0];
$image =~ s/.data/.png/;
$mapname = $ARGV[0];
$mapname =~ s/.data/.map/;
if ($mapname =~ /password/i){ $searchfor="password"; }
if ($mapname =~ /admin/i){ $searchfor="password"; }
if ($mapname =~ /account/i){ $searchfor="username"; }
if ($mapname =~ /ip/i){ $searchfor="IP Address"; }

$number_of_entries=0;
open (FILE, $ARGV[0]) || die "Can't open file $ARGV[0], exiting now\n";
while (<FILE>){
	$number_of_entries ++ ;
}
close(FILE);


$count=1;
if ($number_of_entries == 1) {$x=116; $x_20=320; $increment=0;}
if ($number_of_entries == 2) {$x=90; $x_20=190; $increment=160;}
if ($number_of_entries == 3) {$x=80; $x_20=145; $increment=110;}
if ($number_of_entries == 4) {$x=72; $x_20=120; $increment=82;}
if ($number_of_entries == 5) {$x=70; $x_20=108; $increment=65;}
if ($number_of_entries == 6) {$x=68; $x_20=97; $increment=55;}
if ($number_of_entries == 7) {$x=66; $x_20=95; $increment=46;}
if ($number_of_entries == 8) {$x=63; $x_20=90; $increment=41.30;}
if ($number_of_entries == 9) {$x=65; $x_20=84; $increment=36;}
if ($number_of_entries == 10) {$x=65; $x_20=85; $increment=32.25;}
if ($number_of_entries == 11) {$x=65; $x_20=84; $increment=29;}
if ($number_of_entries == 12) {$x=65; $x_20=84; $increment=27;}
if ($number_of_entries == 13) {$x=63; $x_20=80; $increment=24.75;}
if ($number_of_entries == 14) {$x=66; $x_20=80; $increment=22.80;}
if ($number_of_entries == 15) {$x=65; $x_20=78; $increment=21.5;}
if ($number_of_entries == 16) {$x=64; $x_20=76; $increment=20.10;}
if ($number_of_entries == 17) {$x=65; $x_20=77; $increment=18.75;}
if ($number_of_entries == 18) {$x=65; $x_20=76; $increment=17.75;}
if ($number_of_entries == 19) {$x=65; $x_20=74; $increment=16.90;}
if ($number_of_entries == 20) {$x=65; $x_20=74; $increment=16;}
if ($number_of_entries > 20) {$x=65; $x_20=74; $increment=16;}


open (FILE, $ARGV[0]) || die "Can't open file $ARGV[0], exiting now\n";
$line_count=0;
while (<FILE>){
	$line_count++;
	chomp;
	($count, $password)=split (/ /,$_);
	$password =~ s/\&nbsp;\[preauth\]//;
	if ($line_count <21){
	print "<area shape=\"rect\" coords=\"$x,0,$x_20,220\" href=\"http://www.google.com/search?q=&#34$searchfor+$password&#34\" alt=\"$DATE\" title=\"$DATE\" >\n";
	}
	$x += $increment;
	$x_20 += $increment;

}

print "</map>\n";

