#!/usr/bin/perl
# Stupid program so I can cat both normal files and gzipped files
#

while ($filename =shift){
#print "$filename\n";
	$command = "cat ";
	if ($filename =~ /.bz2/){$command="bzcat "};
	if ($filename =~ /.bz/){$command="bzcat "};
	if ($filename =~ /.gz/){$command="zcat "};
	open (INPUT, "$command $filename|");
	while (<INPUT>){
		if (/ IP: /){
			$_ =~ s/\|/BAR/g;
			$_ =~ s/\</LESSTHAN/g;
			$_ =~ s/\>/GREATERTHAN/g;
			$_ =~ s/\\/BACKSLASH/g;
			$_ =~ s/;/SEMICOLON/g;
			$_ =~ s/\&/AMPERSAND/g;
			$_ =~ s/wget/WGET/g;
			$_ =~ s/curl/CURL/g;
			$_ =~ s/ftpget/FTPGET/g;
			$_ =~ s/ftp/FTP/g;
			$_ =~ s/tftp/TFTP/g;
			$_ =~ s/busybox/BUSYBOX/g;
			$_ =~ s/rm /RM /g;
			$_ =~ s/cd /CD /g;
			$_ =~ s/chmod /CHMOD /g;
		}
		print;
	}
	close (INPUT);
}
