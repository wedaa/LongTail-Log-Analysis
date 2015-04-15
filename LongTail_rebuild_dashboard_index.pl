#!/usr/bin/perl

sub make_index_file {
	my $filename= $_[0];
	my $file_date= $_[1];
	my $date_dir = $file_date;
	$date_dir =~ s/-/\//g;
	my $next_file_date= $_[2];
	my $prior_file_date= $_[3];
	my $first_date=$_[4];
	my $last_date=$_[5];

	#print "IN make_index_file, writing to $dir/$filename\n";
	open (FILE, ">$dir/$filename");

	print (FILE "<HTML>\n");
	if ($next_file_date eq "LAST"){
		# I don't want this to run forever sucking up bandwidth
		# print (FILE "<meta http-equiv=\"refresh\" content=\"1 url=/honey/dashboard/index2.shtml\">\n");
		print (FILE "\n");
	}
	else {
		print (FILE "<meta http-equiv=\"refresh\" content=\"1 url=/honey/dashboard/index-$next_file_date.shtml\">\n");
	}
	print (FILE "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\">\n");
	print (FILE "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE "\n");
	print (FILE "<H3>LongTail Log Analysis Dashboard<BR>All SSH Ports</H3>\n");
	print (FILE "<P>All hosts, all sites, combined.  \n");
	print (FILE "Minimum, Average, and Maximum are from the month shown.  \n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	if ($next_file_date eq "LAST"){
		print (FILE "<A href=\"/honey/dashboard/index2.shtml\">RESTART Slideshow</A><a href=\"/honey/notes.shtml#2\">[2]</a> \n");
	}
	else {
		print (FILE "<A href=\"/honey/dashboard/manual-index-$file_date.shtml\">STOP Slideshow</A><a href=\"/honey/notes.shtml#2\">[2]</a> \n");
	}
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<A href=\"/honey/historical/$date_dir/index.shtml\">\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_number_of_attacks-$file_date.png\">\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_ips-$file_date.png\">\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_passwords-$file_date.png\">\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_usernames-$file_date.png\">\n");
	print (FILE "</a>\n");
	print (FILE "<!--#include virtual=\"/honey/footer.html\" --> \n");

	close (FILE);


	open (FILE, ">$dir/manual-$filename");

	print (FILE "<HTML>\n");
	print (FILE "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\">\n");
	print (FILE "<!--#include virtual=\"/honey/header.html\" --> \n");
	print (FILE "\n");
	print (FILE "<H3>LongTail Log Analysis Dashboard<BR>All SSH Ports</H3>\n");
	print (FILE "<P>All hosts, all sites, combined.  \n");
	print (FILE "Minimum, Average, and Maximum are from the month shown.  \n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<A href=\"/honey/dashboard/manual-index-$first_date.shtml\">FIRST Slide</A>\n");
	if ( $prior_file_date eq "FIRST"){
		print (FILE "NO PRIOR Slide\n");
	}
	else {
		print (FILE "<A href=\"/honey/dashboard/manual-index-$prior_file_date.shtml\">PRIOR Slide</A>\n");
	}
	print (FILE "<A href=\"/honey/dashboard/index-$file_date.shtml\">RESUME Slideshow</A>\n");
	if ($next_file_date eq "LAST"){
		print (FILE "NO NEXT Slide\n");
	}
	else {
		print (FILE "<A href=\"/honey/dashboard/manual-index-$next_file_date.shtml\">NEXT Slide</A>\n");
	}
	print (FILE "<A href=\"/honey/dashboard/manual-index-$last_date.shtml\">LAST Slide</A>\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<A href=\"/honey/historical/$date_dir/index.shtml\">\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_number_of_attacks-$file_date.png\">\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_ips-$file_date.png\">\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_passwords-$file_date.png\">\n");
	print (FILE "<BR>\n");
	print (FILE "<BR>\n");
	print (FILE "<img src=\"/honey/dashboard/dashboard_usernames-$file_date.png\">\n");
	print (FILE "</a>\n");
	print (FILE "<!--#include virtual=\"/honey/footer.html\" --> \n");

	close (FILE);
}

$dir="/var/www/html/honey/dashboard/";
$counter=0;
chdir ("$dir");

open (LS, "ls dashboard_number_of_attacks-*|");
while (<LS>){
	#print;
	chomp;
	$_ =~ s/dashboard_number_of_attacks-//;
	$_ =~ s/.png//;
	#print;
	$date_array[$counter]=$_;
	$counter++;
}
close (LS);
$date_array[$counter]="LAST";
$first_date=$date_array[0];
$last_date=$date_array[$counter-1];

$new_counter=0;
$first=1;
while ($new_counter < $counter){
	#print "Date is $date_array[$new_counter]\n";
	if ($first ==1){
		$prior_date="FIRST";
		$next_date=$date_array[$new_counter+1];
		$this_date=$date_array[$new_counter];
		$index_filename="index2.shtml";
		&make_index_file ($index_filename,$this_date,$next_date,$prior_date,$first_date,$last_date);
		$first = 0;
		$index_filename="index-$this_date.shtml";
		&make_index_file ($index_filename,$this_date,$next_date,$prior_date,$first_date,$last_date);
	}
	else {
		$prior_date=$date_array[$new_counter-1];
		$next_date=$date_array[$new_counter+1];
		$this_date=$date_array[$new_counter];
		$index_filename="index-$this_date.shtml";
		&make_index_file ($index_filename,$this_date,$next_date,$prior_date,$first_date,$last_date);
	}
	$new_counter++;
}
