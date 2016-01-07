#!/usr/bin/perl
#
# Foreign language days/months from
# http://www.europa-pages.co.uk/lessons/spanish-dates.html
#
$filename=$ARGV[0];
$show_matched_passwords=0;
#print "filename is $filename\n";
$column_count=1;

open (DICT, "/usr/local/dict/wordsEn.txt") || die "can not open /usr/local/dict/wordsEn.txt\n";
while (<DICT>){
	chomp;
	$dict{$_}=1;
	$count++;
}
close (DICT);

open (FILE, "$filename") || die "Can not open $filename for reading\n";
while (<FILE>){
	chomp;
	$filename_count++;
	$flag=0;
	#if (length($_) >20 ){print "$_\n"; print " ";print length($_);}
	$length_of_password[length($_)]++;
	if ($_ =~ /^[a-z]+$/){$only_lowercase++;$flag=1;}
	if ($_ =~ /^[A-Z]+$/){$only_uppercase++;$flag=1;}
	if ($_ =~ /^[a-z]+$/i){$only_letters++;$flag=1;}
	if ($_ =~ /^[0-9]+$/i){$only_numbers++;$flag=1;}
	$tmp=$_;
	$tmp=~ s/[0-9]//g;
	$tmp=~ s/\.//g;
	$tmp=~ s/E//g;
	if (length($tmp) == 0){$contains_only_num_plus_period_e++;$flag=1;}
	
	if ($_ =~ /18[0-9][0-9]18[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /18[0-9][0-9]19[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /18[0-9][0-9]20[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /19[0-9][0-9]18[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /19[0-9][0-9]19[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /19[0-9][0-9]10[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /20[0-9][0-9]18[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /20[0-9][0-9]19[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	if ($_ =~ /20[0-9][0-9]20[0-9][0-9]/i){$contains_two_years++; $flag=1;}
	
	if ($_ =~ /18[0-9][0-9].+18[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /18[0-9][0-9].+19[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /18[0-9][0-9].+20[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /19[0-9][0-9].+18[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /19[0-9][0-9].+19[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /19[0-9][0-9].+10[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /20[0-9][0-9].+18[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /20[0-9][0-9].+19[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}
	if ($_ =~ /20[0-9][0-9].+20[0-9][0-9]/i){$contains_two_years_separated++; $flag=1;}

	if ($_ =~ /\.edu$/i) {$contains_domainname++; $flag=1;}
	if ($_ =~ /\.com$/i) {$contains_domainname++; $flag=1;}
	if ($_ =~ /\.net$/i) {$contains_domainname++; $flag=1;}
	if ($_ =~ /\.org$/i) {$contains_domainname++; $flag=1;}
	if ($_ =~ /\.cn$/i) {$contains_domainname++; $flag=1;}
	if ($_ =~ /\.tv$/i) {$contains_domainname++; $flag=1;}

	
	if ($_ =~ /18[0-9][0-9]/i){$contains_year++; $flag=1;}
	if ($_ =~ /19[0-9][0-9]/i){$contains_year++; $flag=1;}
	if ($_ =~ /20[0-9][0-9]/i){$contains_year++; $flag=1;}
	
	if ($_ =~ /Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday/i){$contains_day_of_week++;$flag=1;}
	if ($_ =~ /january|february|march|april|may|june|july|august|september|october|november|december/i){$contains_month++;$flag=1;}

	$tmp=$_;
	$tmp =~ tr/[A-Z]/[a-z]/;
	#print "DEBUG tmp is $tmp\n";
	if ($dict{"$tmp"} >0){$dictionary_word++;$flag=1;}
	
	
	$tmp=$_;
	$tmp=~ s/[a-z]//g;
	$tmp=~ s/[A-Z]//g;
	$tmp=~ s/[0-9]//g;
	 
	#print "word is -->$_<-- tmp is -->$tmp<--\n";
	#print "length of tmp is "; print length($tmp); print "\n";
	if (length($tmp) == 0){$contains_only_alphanum++;$flag=1;}
	if (length($tmp) >0){if (length($tmp) == length($_)){$contains_only_special_chars++;$flag=1;} }

	if ($flag ==0 ){$unflagged_words++;}

}
close (FILE);

print "<BR>\n";
print "<TABLE>\n";
print "<TR><TD>Total Passwords</TD><TD>$filename_count\n";
print "<TR><TD>Only Lowercase letters</TD><TD>$only_lowercase\n";
print "<TR><TD>Only Uppercase letters</TD><TD>$only_uppercase\n";
print "<TR><TD>Only numbers</TD><TD>$only_numbers\n";
print "<TR><TD>numbers, periods, \"E\"</TD><TD>$contains_only_num_plus_period_e\n";
print "<TR><TD>Only alphaNum</TD><TD>$contains_only_alphanum\n";
print "<TR><TD>Ends with .edu|.com|.org|.net|.org|.tv|.cn</TD><TD>$contains_domainname (Thanks to <A href=\"http://www.netsec.ethz.ch/publications/papers/passwords15-abdou.pdf\">http://www.netsec.ethz.ch/publications/papers/passwords15-abdou.pdf</a> for the idea!)\n";
print "<TR><TD>Only only non numeric/alpha</TD><TD>$contains_only_special_chars\n";
print "<TR><TD>Contains a year</TD><TD>$contains_year\n";
print "<TR><TD>Contains two years</TD><TD>$contains_two_years\n";
print "<TR><TD>Contains two years separated</TD><TD>$contains_two_years_separated\n";
print "<TR><TD>Contains a month in english</TD><TD>$contains_month\n";
print "<TR><TD>Contains a day of the week in English</TD><TD>$contains_day_of_week\n";
print "<TR><TD>Number of words in the wordsEn.txt English dictionary </TD><TD>$count\n";
print "<TR><TD>Number of passwords found in the wordsEn.txt dictionary</TD><TD>$dictionary_word\n";
print "<TR><TD>Words that don't match any of the above criteria</TD><TD>$unflagged_words\n";
print "</TABLE>\n";
print "<BR><BR>\n";


$size = @length_of_password;
$max_index = $#length_of_password;
print "<TABLE>\n";
print "<TR><TH>Length of<BR>password</TH><TH>Number of<BR>unique passwords</TH></TR>\n";
$count=1;
while ($count <=$max_index){
	if ($count <40){
	print "<TR><TD>$count</TD><TD>$length_of_password[$count]</TD>\n";
	if ($count == 8){
		print "<TD>8 characters used to be the maximum password lenght for unix.</TD>\n";
	}
	if ($count == 32){
		print "<TD>MD5 hashes are 32 characters!</TD>\n";
	}
	}
	if ($count >= 40){
		if ($length_of_password[$count] >0){
			print "<TR><TD>$count</TD><TD>$length_of_password[$count]</TD></TR>\n";
		}
	}
	$count++;
}
print "</TABLE>\n";
