#!/usr/bin/perl

sub print_header {
	print "<HTML>\n";
	print "<link rel=\"stylesheet\" type=\"text/css\" href=\"/honey/LongTail.css\">\n";
	print "<!--#include virtual=\"/honey/header.html\" --> \n";
	print "\n";
	print "<H3>LongTail Log Analysis @ <!--#include virtual=\"/honey/institution.html\" -->\n";
	print "/ Whois analysis of SSH Attacking IP Addresses(Top 100 by IP count)</H3>\n";
	print "<P>This page is updated daily.\n";
	print "Last updated on \n";
	$date=`date`;
	print $date;
	print "<BR>\n";
	print "<BR>\n";
	print "<TABLE border=1>\n";
	print "<TR><TH colspan=6>Whois Analysis of SSH Attacking IP Addresses</TH></TR>\n";
}

sub print_footer{
	print "</TABLE>\n";
	print "<!--#include virtual=\"/honey/footer.html\" --> \n";
}

sub pass_1 {
	print "<TR><TH>Number of<BR>times seen</TH><TH>Name</TH><TH>IP Addresses registered <BR>to this Name</TR>\n";
	open (PIPE, "ls /usr/local/etc/whois.out/* |xargs grep -i ^person |sed 's/^..*://' |sed 's/         //' |sort |uniq -c |sort -n |tail -100 |");
	while (<PIPE>){
		chomp;
		$_ =~ s/\r//;
		$_ =~ s/  / /g;
		$_ =~ s/  / /g;
		$_ =~ s/  / /g;
		$_ =~ s/  / /g;
		$_ =~ s/^ +//;
		($count,$name)=split (/ /,$_,2);
		$_ =~ s/^/<TR><TD>/;
		$_ =~ s/ /<\/TD><TD>/;
		print "$_</TD><TD>\n";
		$name =~ s/ /\\\ /g;
		$name =~ s/'/./g;
		#system ("grep $name /usr/local/etc/whois.out/* |grep -v descr |sed 's/^.*whois.out.//' |sed 's/:person.*/<BR>/' ");
		# Worked monday morning# system ("grep $name /usr/local/etc/whois.out/* |sed 's/^.*whois.out.//' |sed 's/:.*/<BR>/' ");
		open (PIPE2, "grep $name /usr/local/etc/whois.out/* |");
		while (<PIPE2>){
			chomp;
			$ip=$_;
			$ip =~ s/^.*whois.out.//;
			$ip =~ s/:.*//;
			print "$ip ";
			open (FILE2, "/usr/local/etc/whois.out/$ip");
			$last_modified_seen=0;
			while (<FILE2>){
				if (/last-modified/){
					$tmp=$_;
					$tmp=~ s/^.*whois.out.//;
					#$tmp =~ s/last-modified://;
					if( $last_modified_seen == 0 ){
						print $tmp;
						$last_modified_seen=1;
					}
					else {
						$tmp =~ s/last-modified://;
						print " $tmp ";
					}
				}
			}
			close (FILE2);
			print "<BR>\n";
		}
		close (PIPE2);
		print "</TD></TR>\n";
	}
	close (PIPE);
	print "</TABLE>\n";
}

&print_header;
&pass_1;
&print_footer;
