#!/usr/bin/perl
#
# This file assumes you are reading /var/www/html/honey/current-ip-addresses.txt
# or a similarly formatted file
#
if ( $ARGV[0] eq ""){
	print (STDERR "You forgot to add a filename to your command, exiting now\n");
	exit;
}


if (! -e $ARGV[0] ){
	print (STDERR "filename $ARGV[0] does not exist, exiting now.\n");
	exit;
}

print "
    <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>
    <script type=\"text/javascript\">
      google.load(\"visualization\", \"1\", {packages:[\"geochart\"]});
      google.setOnLoadCallback(drawRegionsMap);

      function drawRegionsMap() {
        var data = google.visualization.arrayToDataTable([
          ['Country', 'Attacks', 'IP Addresses'],

";

open (FILE, $ARGV[0]);
while (<FILE>){
	chomp;
	if (/#/){next;}
	$_ =~ s/\(..*\)//;
	$_ =~ s/ $//;
	$_ =~ s/^ +//;
	($count,$ip,$country)=split (/ +/,$_);
	if ($country eq "Hong_Kong"){$country="China";}
	if ($country ne ""){
		$attacks{$country}+=$count;
		$ip_addresses{$country}+=1;
	}
}
close (FILE);

$count=0;
foreach $name(keys %attacks){
$count++;
#	if ($attacks{$name} > 100){
		print "['$name', $attacks{$name}, $ip_addresses{$name} ],\n";
#	}
}
if ($count <1){
	print "['', 0, 0 ],\n";
}



print "
	]);

        var options = {
                <!-- colorAxis: {colors: ['#00853f', 'black', '#e31b23']}, -->
                <!--colorAxis: {colors: ['#000000', 'red', '#FF0000']},-->
                colorAxis: {colors: ['#0000F0', '#FF0000']},

        };

        var chart = new google.visualization.GeoChart(document.getElementById('regions_div'));

        chart.draw(data, options);
      }
    </script>

";

