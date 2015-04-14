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

print "Total Passwords:             $filename_count\n";
print "Only Lowercase letters:      $only_lowercase\n";
print "Only Uppercase letters:      $only_uppercase\n";
print "Only numbers:                $only_numbers\n";
print "numbers, periods, \"E\":       $contains_only_num_plus_period_e\n";
print "Only alphaNum:               $contains_only_alphanum\n";
print "Only only non numeric/alpha: $contains_only_special_chars\n";
print "Contains a year:             $contains_year\n";
print "Contains two years:          $contains_two_years\n";
print "Contains two years separated:         $contains_two_years_separated\n";
print "Contains a month in english: $contains_month\n";
print "Contains a day of the week in english: $contains_day_of_week\n";
print "wordsEn.txt dictionary count is:  $count\n";
print "Are in wordsEn.txt dictionary:  $dictionary_word\n";
print "Words that don't match any of the above criteria:             $unflagged_words\n";

$size = @length_of_password;
$max_index = $#length_of_password;
#print "size is $size, max is $max_index\n";
print "Length of password: Number of uniq passwords\n";
$count=0;
while ($count <=$max_index){
	if ($count <40){
	print "$count : $length_of_password[$count]\n";
	}
	if ($count >= 40){
		if ($length_of_password[$count] >0){
			print "$count : $length_of_password[$count]\n";
		}
	}
	$count++;
}

print "\n\nLooking at dictionaries now\n\n";

#
# Yes, I read the file twice, once as whatever the file
# contents are, and then I wipe memory and read the file
# a second time and convert it to lower case.  It takes 
# a little longer, but saves memory
#
$dir[1]="/usr/local/dict-assorted";
$dir[2]="/usr/local/dict-packetstorm";
$directory_counter=1;
while ( $directory_counter <3){
open (LS, "ls $dir[$directory_counter]/*.gz $dir[$directory_counter]/*bz2 $dir[$directory_counter]/*.zip|")||die "can not run ls command on /usr/local/dict/\n";
$directory_counter++;
while (<LS>){
	chomp;
	#if (/rockyou.txt.bz2/){print "Skipping rockyou.txt.bz2 because it's huge\n";next;}
	$dictionary_name=$_;
	$dictionary_word=0;
	$dictionary_name_munged = $_;
	$dictionary_name_munged =~ s/.usr.local.dict-//;
	print "Dictionary $dictionary_name_munged";
	undef (%dict);
	undef (%dictlower);
	if (/.bz2$/){
		#print "Debug .bz2\n";
		open (DICT, "bzcat $_|") || die "can not open /usr/local/dict/$_\n";
	}
	if (/.gz$/){
		#print "Debug .gz\n";
		open (DICT, "zcat -c  $_|") || die "can not open /usr/local/dict/$_\n";
	}
	if (/.zip$/){
		#print "Debug .zip\n";
		open (DICT, "unzip -c  $_|") || die "can not open /usr/local/dict/$_\n";
	}
	$count=0;
	while (<DICT>){
		chomp;
		$_ =~ s/\cM//g;
		if ( $dict{$_} <1){
			$dict{$_}=1;
			#$_ =~ tr/[A-Z]/[a-z]/;
			#$dictlower{$_}=1;
			$count++;
		}
	}
	close (DICT);
	print " $count words;  matches:";
	open (FILE, "$filename") || die "Can not open $filename for reading\n";
	while (<FILE>){
		chomp;
		if ($dict{"$_"} >0){
			$dict{"$_"} ++; 
			$dictionary_word++;$flag=1;
			if ($show_matched_passwords == 1){
				print "$_ ";
				$column_count++;
				if ($column_count >8){$column_count=1; print "\n";}
			}
		}
		#else {print "Miss on $_ "; }
	}
	close (FILE);
	print " $dictionary_word, ";
	$percentage=$dictionary_word/$count*100;
	$percentage_string=sprintf("%.2f",$percentage);
	print "$percentage_string percent words found in all passwords.  ";
	if ( $dictionary_word > ($count*.90) ){
		if ( $dictionary_word  == $count ){
			print "INTERESTING, ALL words in dictionary were used";
		}
		else {
			print "More than 90%, INTERESTING , missing entries are:";
			foreach $value (keys %dict)
			{
				if ($dict{$value}<2){print "$value "}
			}
		}
	}
	print "\n";
	$dictionary_word=0;

	$_ = $dictionary_name;
	print "Dictionary $dictionary_name_munged in lower case ";
	undef (%dict);
	undef (%dictlower);
	if (/.bz2$/){
		#print "DEBUG bz2\n";
		open (DICT, "bzcat $_|") || die "can not open /usr/local/dict/$_\n";
	}
	if (/.gz$/){
		#print "DEBUG gz\n";
		open (DICT, "zcat -c  $_|") || die "can not open /usr/local/dict/$_\n";
	}
	if (/.zip$/){
		#print "DEBUG zip\n";
		open (DICT, "unzip -c  $_|") || die "can not open /usr/local/dict/$_\n";
	}
	$count=0;
	while (<DICT>){
		chomp;
		$_ =~ s/\cM//g;
		$_ =~ tr/[A-Z]/[a-z]/;
		if ( $dict{$_} <1){
			$dict{$_}=1;
			$count++;
		}
	}
	close (DICT);
	print " $count words;  matches:";
	open (FILE, "$filename") || die "Can not open $filename for reading\n";
	while (<FILE>){
		chomp;
		if ($dict{"$_"} >0){
			$dict{"$_"} ++; 
			$dictionary_word++;$flag=1;
			if ($show_matched_passwords == 1){
				print "$_ ";
				$column_count++;
				if ($column_count >8){$column_count=1; print "\n";}
			}
		}
	}
	close (FILE);
	print " $dictionary_word, ";
	$percentage=$dictionary_word/$count*100;
	$percentage_string=sprintf("%.2f",$percentage);
	print "$percentage_string percent words found in all passwords.  ";

	if ( $dictionary_word > ($count*.90) ){
		if ( $dictionary_word  == $count ){
			print "INTERESTING, ALL words in dictionary were used";
		}
		else {
			print "More than 90%, INTERESTING , missing entries are:";
			foreach $value (keys %dict)
			{
				if ($dict{$value}<2){print "$value "}
			}
		}
	}
	print "\n";
	$dictionary_word=0;
	print "\n";
}
close (LS);
}
