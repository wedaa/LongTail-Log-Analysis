#!/usr/bin/perl
# Written by Eric Wedaa 2015-03
# This is absolutely horrible looking code, but it works
# and I don't see you writting anything better :-)
#

use List::Util qw(max min sum); 
@a_1=();
@a_2=();
@a_3=();
@a_4=();
@a_5=();
@a_6=();
@a_7=();

#chdir ("/var/www/html/honey/historical") || die "can not chdir\n";;
chdir ("$ARGV[0]") || die "can not chdir to $ARGV[0] \n";;
print "<HTML><BODY><TABLE>\n";

open (YEAR, "/bin/ls  -d 2*|");
while (<YEAR>){
	chomp;
	$year=$_;
	chdir $year;
	open (MONTH, "/bin/ls -d ??|");
	while (<MONTH>){
		chomp;
		$month=$_;
		$string=`cal $month $year`;
		$string =~ s/\n/ \n /g;
		$string =~ s/^ +//;
	
		chdir $month;
		open (DAY, "/bin/ls -d ??|");
		while (<DAY>){
			chomp;
			$day=$_;
			$value="NA";
			open (FILE, "$day/current-attack-count.data") ;
			while (<FILE>){
				$value=$_;
			}
			close (FILE);
			chomp $value;
			$day =~ s/^0//;
			$string =~ s/ $day / $day\/$value /g;
		}
		chdir ("..");
		$string =~ s/\n /\n/g;
		$string =~ s/\n /\n/g;
		$string =~ s/  1/<TD>1<\/TD>/g;
		$string =~ s/   /<TD>&nbsp<\/TD>/g;
		$string =~ s/  / /g;
		$string =~ s/<TD><\/TD>\n/\n/g;
		$string =~ s/<TD><\/TD>\n/\n/g;
		$string =~ s/<TD><\/TD>\n/\n/g;
		$string =~ s/^/<TR><TD>/;
		$string =~ s/\n/<\/TD><\/TR>\n<TR><TD>/g;
		$string =~ s/ <\/TD>/<\/TD>/g;
		$string =~ s/ /<\/TD><TD>/g;
		$string =~ s/\n<TR><TD><TD>/\n<TR><TD>/g;
		$string =~ s/<\/TD><\/TD>/<\/TD>/g;
		$string =~ s/<\/TD><\/TD>/<\/TD>/g;
		$string =~ s/<TR><TD><\/TD><\/TR>//g;
		$string =~ s/<TD>&nbsp<\/TD><\/TR>/<\/TD><\/TR>/g;
		$string =~ s/<TD>&nbsp<\/TD><\/TR>/<\/TD><\/TR>/g;
		$string =~ s/<TD>&nbsp<\/TD><\/TD><\/TR>/<\/TD><\/TR>/g;

		$string =~ s/^<TR><TD>/<TR><TH>/;
		$string =~ s/<TD>2015/<TH>2015/;
		$string =~ s/<TD>2016/<TH>2016/;
		$string =~ s/<TD>2017/<TH>2017/;
		$string =~ s/<TD>2018/<TH>2018/;
		$string =~ s/<TD>2019/<TH>2019/;
		$string =~ s/<TR><TD>Su..*+/<TR><TH>Su<\/TH><TH>Mo<\/TH><TH>Tu<\/TH><TH>We<\/TH><TH>Th<\/TH><TH>Fr<\/TH><TH>Sa<\/TH><\/TR>/;
		#$string =~ s/<TR>/<TR><TD>&nbsp<\/TD>/g;
		#print $string;

		$line_count=0;
		for (split /^/, $string) {
			if ($line_count < 2 ){$line_count++; next;}
			if ($line_count > 7 ){$line_count++; next;}
			$_ =~ s/<\/TD>//g;
			$_ =~ s/<\/TR>//g;
			@array=split(/<TD>/,$_);
			$day_of_week_loop=1;
			while ($day_of_week_loop < 8){
				($tmp,$tmp1)=split(/\//,$array[$day_of_week_loop] );
				if ($tmp1 > 0){
					#$totals[$day_of_week_loop]+=$tmp1;
					#$count[$day_of_week_loop]++;
					# @a_1() etc is declared at top of program
					if ( $day_of_week_loop == 1) {$sqsum_1+=$tmp1*$tmp1; push(@a_1,$tmp1)}
					if ( $day_of_week_loop == 2) {$sqsum_2+=$tmp1*$tmp1; push(@a_2,$tmp1)}
					if ( $day_of_week_loop == 3) {$sqsum_3+=$tmp1*$tmp1; push(@a_3,$tmp1)}
					if ( $day_of_week_loop == 4) {$sqsum_4+=$tmp1*$tmp1; push(@a_4,$tmp1)}
					if ( $day_of_week_loop == 5) {$sqsum_5+=$tmp1*$tmp1; push(@a_5,$tmp1)}
					if ( $day_of_week_loop == 6) {$sqsum_6+=$tmp1*$tmp1; push(@a_6,$tmp1)}
					if ( $day_of_week_loop == 7) {$sqsum_7+=$tmp1*$tmp1; push(@a_7,$tmp1)}
				}
				$day_of_week_loop++;
			}
			$line_count++;
		}
		$string =~ s/<TR>/<TR><TD>&nbsp<\/TD>/g;
		print $string;
	}
	chdir ("..");
}
$day_of_week_loop=1;
while ($day_of_week_loop < 8){
	if ($totals[$day_of_week_loop] > 0){
		#print "Total for $day_of_week_loop $totals[$day_of_week_loop] count=$count[$day_of_week_loop]\n";
	}
	$day_of_week_loop++;
}
#print "\n</TABLE>\n";

$n_1=@a_1;
$s_1=sum(@a_1);
$a_1=$s_1/@a_1;
$m_1=max(@a_1);
$mm_1=min(@a_1);
$std_1=sqrt($sqsum_1/$n_1-($s_1/$n_1)*($s_1/$n_1));
$mid_1=int @a_1/2;
@srtd=sort { $a <=> $b } @a_1;
if(@a_1%2){$med_1=$srtd[$mid_1];}else{$med_1=($srtd[$mid_1-1]+$srtd[$mid_1])/2;}; 

$n_2=@a_2;
$s_2=sum(@a_2);
$a_2=$s_2/@a_2;
$m_2=max(@a_2);
$mm_2=min(@a_2);
$std_2=sqrt($sqsum_2/$n_2-($s_2/$n_2)*($s_2/$n_2));
$mid_2=int @a_2/2;
@srtd=sort { $a <=> $b } @a_2;
if(@a_2%2){$med_2=$srtd[$mid_2];}else{$med_2=($srtd[$mid_2-1]+$srtd[$mid_2])/2;}; 

$n_3=@a_3;
$s_3=sum(@a_3);
$a_3=$s_3/@a_3;
$m_3=max(@a_3);
$mm_3=min(@a_3);
$std_3=sqrt($sqsum_3/$n_3-($s_3/$n_3)*($s_3/$n_3));
$mid_3=int @a_3/2;
@srtd=sort { $a <=> $b } @a_3;
if(@a_3%2){$med_3=$srtd[$mid_3];}else{$med_3=($srtd[$mid_3-1]+$srtd[$mid_3])/2;}; 

$n_4=@a_4;
$s_4=sum(@a_4);
$a_4=$s_4/@a_4;
$m_4=max(@a_4);
$mm_4=min(@a_4);
$std_4=sqrt($sqsum_4/$n_4-($s_4/$n_4)*($s_4/$n_4));
$mid_4=int @a_4/2;
@srtd=sort { $a <=> $b } @a_4;
if(@a_4%2){$med_4=$srtd[$mid_4];}else{$med_4=($srtd[$mid_4-1]+$srtd[$mid_4])/2;}; 

$n_5=@a_5;
$s_5=sum(@a_5);
$a_5=$s_5/@a_5;
$m_5=max(@a_5);
$mm_5=min(@a_5);
$std_5=sqrt($sqsum_5/$n_5-($s_5/$n_5)*($s_5/$n_5));
$mid_5=int @a_5/2;
@srtd=sort { $a <=> $b } @a_5;
if(@a_5%2){$med_5=$srtd[$mid_5];}else{$med_5=($srtd[$mid_5-1]+$srtd[$mid_5])/2;}; 

$n_6=@a_6;
$s_6=sum(@a_6);
$a_6=$s_6/@a_6;
$m_6=max(@a_6);
$mm_6=min(@a_6);
$std_6=sqrt($sqsum_6/$n_6-($s_6/$n_6)*($s_6/$n_6));
$mid_6=int @a_6/2;
@srtd=sort { $a <=> $b } @a_6;
if(@a_6%2){$med_6=$srtd[$mid_6];}else{$med_6=($srtd[$mid_6-1]+$srtd[$mid_6])/2;}; 

$n_7=@a_7;
$s_7=sum(@a_7);
$a_7=$s_7/@a_7;
$m_7=max(@a_7);
$mm_7=min(@a_7);
$std_7=sqrt($sqsum_7/$n_7-($s_7/$n_7)*($s_7/$n_7));
$mid_7=int @a_7/2;
@srtd=sort { $a <=> $b } @a_7;
if(@a_7%2){$med_7=$srtd[$mid_7];}else{$med_7=($srtd[$mid_7-1]+$srtd[$mid_7])/2;}; 

$std_1=sprintf("%.2f",$std_1);
$std_2=sprintf("%.2f",$std_2);
$std_3=sprintf("%.2f",$std_3);
$std_4=sprintf("%.2f",$std_4);
$std_5=sprintf("%.2f",$std_5);
$std_6=sprintf("%.2f",$std_6);
$std_7=sprintf("%.2f",$std_7);

$a_1=sprintf("%.2f",$a_1);
$a_2=sprintf("%.2f",$a_2);
$a_3=sprintf("%.2f",$a_3);
$a_4=sprintf("%.2f",$a_4);
$a_5=sprintf("%.2f",$a_5);
$a_6=sprintf("%.2f",$a_6);
$a_7=sprintf("%.2f",$a_7);

#print "\n<TABLE>\n";
print "<TR><TH></TH><TH>Su</TH><TH>Mo</TH><TH>Tu</TH><TH>We</TH><TH>Th</TH><TH>Fr</TH><TH>Sa</TH></TR>\n";
print "<TR><TH>Count</TH><TD>$n_1</TD><TD>$n_2</TD><TD>$n_3</TD><TD>$n_4</TD><TD>$n_5</TD><TD>$n_6</TD><TD>$n_7</TD></TR>\n";
print "<TR><TH>Sum</TH><TD>$s_1</TD><TD>$s_2</TD><TD>$s_3</TD><TD>$s_4</TD><TD>$s_5</TD><TD>$s_6</TD><TD>$s_7</TD></TR>\n";
print "<TR><TH>Average</TH><TD>$a_1</TD><TD>$a_2</TD><TD>$a_3</TD><TD>$a_4</TD><TD>$a_5</TD><TD>$a_6</TD><TD>$a_7</TD></TR>\n";
print "<TR><TH>Std Dev.</TH><TD>$std_1</TD><TD>$std_2</TD><TD>$std_3</TD><TD>$std_4</TD><TD>$std_5</TD><TD>$std_6</TD><TD>$std_7</TD></TR>\n";
print "<TR><TH>Median</TH><TD>$med_1</TD><TD>$med_2</TD><TD>$med_3</TD><TD>$med_4</TD><TD>$med_5</TD><TD>$med_6</TD><TD>$med_7</TD></TR>\n";
print "<TR><TH>Min</TH><TD>$m_1</TD><TD>$m_2</TD><TD>$m_3</TD><TD>$m_4</TD><TD>$m_5</TD><TD>$m_6</TD><TD>$m_7</TD></TR>\n";
print "<TR><TH>Max</TH><TD>$mm_1</TD><TD>$mm_2</TD><TD>$mm_3</TD><TD>$mm_4</TD><TD>$mm_5</TD><TD>$mm_6</TD><TD>$mm_7</TD></TR>\n";


#print "Sunday Count=$n_1\nSUM=$s_1\nAVERAGE=$a_1\nSTD=$std_1\nMEDIAN=$med_1\nMAX=$m_1\nMIN=$mm_1";


print "\n</TABLE></BODY></HTML>\n";
