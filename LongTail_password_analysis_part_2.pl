#!/usr/bin/perl
$|=1;
#
# Foreign language days/months from
# http://www.europa-pages.co.uk/lessons/spanish-dates.html
#
$filename=$ARGV[0];
$show_matched_passwords=0;
$column_count=1;


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
print "<TABLE>\n";
print "<TR><TH>Dictionary file</TH><TH>\# of words</TH><TH>\# of Matches</TH><TH>% matches</TH><TH>Comments</TH></TR>\n";
while (<LS>){
	chomp;
	if ( /rockyou/){next;}
	$dictionary_name=$_;
	$dictionary_word=0;
	$dictionary_name_munged = $_;
	$dictionary_name_munged =~ s/.usr.local.dict-//;
	print "<TR>\n";
	print "<TD>$dictionary_name_munged</TD>";
	undef (%dict);
	undef (%dictlower);
	if (/.bz2$/){
		open (DICT, "bzcat $_|") || die "can not open /usr/local/dict/$_\n";
	}
	if (/.gz$/){
		open (DICT, "zcat -c  $_|") || die "can not open /usr/local/dict/$_\n";
	}
	if (/.zip$/){
		open (DICT, "unzip -c  $_|") || die "can not open /usr/local/dict/$_\n";
	}
	$count=0;
	while (<DICT>){
		chomp;
		$_ =~ s/\cM//g;
		if ( $dict{$_} <1){
			$dict{$_}=1;
			$count++;
		}
	}
	close (DICT);
	print "<TD>$count</TD>";
	open (FILE, "$filename") || die "Can not open $filename for reading\n";
	while (<FILE>){
		chomp;
		if ($dict{"$_"} >0){
			$dict{"$_"} ++; 
			$dictionary_word++;$flag=1;
			if ($show_matched_passwords == 1){
				print "<BR>$_ ";
				$column_count++;
				if ($column_count >8){$column_count=1; print "<BR>\n";}
			}
		}
		#else {print "Miss on $_ "; }
	}
	close (FILE);
	print "<TD> $dictionary_word ";
	$percentage=$dictionary_word/$count*100;
	$percentage_string=sprintf("%.2f",$percentage);
	print "<TD> $percentage_string </TD> ";
	if ( $dictionary_word > ($count*.90) ){
		if ( $dictionary_word  == $count ){
			print "<TD>INTERESTING, ALL words in dictionary were used";
		}
		else {
			print "<TD>More than 90%, INTERESTING , missing entries are:";
			foreach $value (keys %dict)
			{
				if ($dict{$value}<2){print "$value "}
			}
		}
	}
	print "</TR>\n";
	$dictionary_word=0;
	#############################################################################
	#
	# Lower Case now
	#
	$_ = $dictionary_name;
	print "<TR><TD>$dictionary_name_munged in lower case ";
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
	$tmp_count=0;
	while (<DICT>){
		chomp;
		$_ =~ s/\cM//g;
		$_ =~ tr/[A-Z]/[a-z]/;
		if ( $dict{$_} <1){
			$dict{$_}=1;
			$count++;
		}
		$tmp_count++;
	#	if ($tmp_count > 10000){$tmp_count=0; print ".";}
	}
	close (DICT);
	print "<TD> $count </TD>";
	open (FILE, "$filename") || die "Can not open $filename for reading\n";
	while (<FILE>){
		chomp;
		if ($dict{"$_"} >0){
			$dict{"$_"} ++; 
			$dictionary_word++;$flag=1;
			if ($show_matched_passwords == 1){
				print "$_ ";
				$column_count++;
				if ($column_count >8){$column_count=1; print "<BR>\n";}
			}
		}
	}
	close (FILE);
	print "<TD> $dictionary_word ";
	$percentage=$dictionary_word/$count*100;
	$percentage_string=sprintf("%.2f",$percentage);
	print "<TD>$percentage_string</TD> ";

	if ( $dictionary_word > ($count*.90) ){
		if ( $dictionary_word  == $count ){
			print "<TD>INTERESTING, ALL words in dictionary were used";
		}
		else {
			print "<TD>More than 90%, INTERESTING , missing entries are:";
			foreach $value (keys %dict)
			{
				if ($dict{$value}<2){print "$value "}
			}
		}
	}
	print "</TR>\n";
	$dictionary_word=0;
	print "\n";
}
close (LS);
}
