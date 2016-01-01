#!/usr/bin/perl
#print "<HTML>\n"; #Delete these lines once it's working
#print "<BODY>\n"; #Delete these lines once it's working

#print "<img src=\"last-30-days-password-count.png\" alt=\"last-30-days-password-count.png\" usemap=\"#mapname\" />\n";
#print "<map name=\"mapname\">\n";

$YEAR=`date +%Y`;
chomp $YEAR;
$count=30;
$x=65;
$x_20=88;
while ($count >0){
	$DATE=`date "+%Y/%m/%d" --date="$count day ago"`;
	chomp $DATE;
	#print "<area shape=\"rect\" coords=\"$x,0,$x_20,220\" href=\"http://longtail.it.marist.edu/honey/historical/$YEAR/$DATE/\" alt=\"$DATE\" title=\"$DATE\" >\n";
	#I changed this so that image maps point DOWNHILL, instead of to the top level historical dir
	print "<area shape=\"rect\" coords=\"$x,0,$x_20,220\" href=\"historical/$DATE/\" alt=\"$DATE\" title=\"$DATE\" >\n";
	$x += 24;
	$x_20 += 24;

#  <area shape="rect" coords="60,0,80,200" href="http://longtail.it.marist.edu/honey/historical/2015/03/24/" alt="03/24" title="03/24" >
#  <area shape="rect" coords="90,0,110,200" href="http://longtail.it.marist.edu/honey/historical/2015/03/25/" alt="03/25" title="03/25" >
#  <area shape="rect" coords="770,0,790,200" href="http://longtail.it.marist.edu/honey/historical/2015/04/22" alt="04/22" title="04/22" >
	$count--;
}

#print "</map>\n";

