#!/usr/bin/perl
# Stupid program so I can cat both normal files and gzipped files
#

#while (( "$#" )); do
#	#echo "$1"
#	# Let cat and zcat complain about it :-)
#	#if [ ! -r $1 ] ; then
#	#	>&2 echo "Can't read $1"
#	#	exit
#	#fi
#	case $1 in
#		*bz2)
#			bzcat $1 |sed 's/|/BAR/g'|sed 's/\\/BACKSLASH/g'|sed 's/&/AMPERSAND/g' |sed 's/wget/WGET/g' |sed 's/tftp/TFTP/g'|sed 's/curl/CURL/g' |sed 's/ftpget/FTPGET/g' |sed 's/ftp/FTP/'|sed 's/busybox/BUSYBOX/g'
#		;;
#		*bz)
#			bzcat $1 |sed 's/|/BAR/g'|sed 's/\\/BACKSLASH/g'|sed 's/&/AMPERSAND/g' |sed 's/wget/WGET/g' |sed 's/tftp/TFTP/g'|sed 's/curl/CURL/g' |sed 's/ftpget/FTPGET/g' |sed 's/ftp/FTP/'|sed 's/busybox/BUSYBOX/g'
#		;;
#		*gz)
#			zcat $1 |sed 's/|/BAR/g'|sed 's/\\/BACKSLASH/g'|sed 's/&/AMPERSAND/g' |sed 's/wget/WGET/g' |sed 's/tftp/TFTP/g'|sed 's/curl/CURL/g' |sed 's/ftpget/FTPGET/g' |sed 's/ftp/FTP/'|sed 's/busybox/BUSYBOX/g'
#		;;
#		*)
#			cat $1 |sed 's/|/BAR/g'|sed 's/\\/BACKSLASH/g'|sed 's/&/AMPERSAND/g' |sed 's/wget/WGET/g' |sed 's/tftp/TFTP/g'|sed 's/curl/CURL/g' |sed 's/ftpget/FTPGET/g' |sed 's/ftp/FTP/'|sed 's/busybox/BUSYBOX/g'
#		;;
#		esac
#	shift
#done

while ($filename =shift){
print "$filename\n";
	$command = "cat ";
	if (/.bz2/){$command="bzcat "};
	if (/.bz/){$command="bzcat "};
	if (/.gz/){$command="zcat "};
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
		}
		print;
	}
	close (INPUT);
}
