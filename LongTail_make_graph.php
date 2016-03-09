<?php // content="text/plain; charset=utf-8"
// Example for use of JpGraph,
//Lightly modified from http://jpgraph.net/download/manuals/chunkhtml/ch08s04.html

require_once ('/usr/local/php/jpgraph-3.5.0b1/src/jpgraph.php');
require_once ('/usr/local/php/jpgraph-3.5.0b1/src/jpgraph_bar.php');

$date=`date +"%Y-%m-%d %H:%M"`;
$URL_LINE="http://longtail.it.marist.edu";


// USAGE: php /usr/local/etc/LongTail_make_graph.php filename "header" "X-axis label" "Y-axis label"
// Must pass full filename to read and "Quote delimited text header"
// And redirect the output to a file
// php LongTail_make_graph.php /var/www/html/honey/current-top-20-root-passwords.data "Current top 20 root passwords" "X Title" "Y Title" "wide">current-top-20-root-passwords.png 
// php LongTail_make_graph.php /var/www/html/honey/current-top-20-root-passwords.data "Current top 20 root passwords" "X Title" "Y Title" "">current-top-20-root-passwords.png 

$file = $argv[1];
$header = $argv[2];
$x_axis_title =  $argv[3];
$y_axis_title =  $argv[4];
$size=$argv[5];
 
// We need some data
$counter=0;
# Initialize it just in case there's no data
$datay[$counter]=0;
$datax[$counter]="NO DATA";
 
$myfile = fopen($file, "r") 
	or die("Unable to open file!");
if ($myfile) {
	while (($buffer = fgets($myfile, 4096)) !== false) {
		list($count,$account) = explode(" ",$buffer);
		$account = chop($account);
		$account = str_replace("&nbsp;[preauth]","",$account);
		if (strpos($file, 'non-root-accounts.data') !== false) {
			// print "non-root-accounts.data found\n";
			if ("$account" != "root"){
				// print "non-root-accounts found --$account--\n";
				$datay[$counter]=$count;
				$datax[$counter]=$account;
				$counter++;
			}
		}
		else {
			$datay[$counter]=$count;
			$datax[$counter]=$account;
			$counter++;
		}
	}
    if (!feof($myfile)) {
        echo "Error: unexpected fgets() fail\n";
    }
    fclose($myfile);
}


// TEST DATA if I need it
// $datay=array(1300,555,21,5,31,6,5,4,3,2,1,12,13,14,15,16,17,18,19,20);
// $datax=array("root","admin","oracle","test","ralph","june","test5","test4","test3","test2","test1","test1","test1","test1","test1","test1","test1","test1","test1","test1");


// Setup the graph.
if ($size == "wide"){
	$graph = new Graph(810,240);
}
else {
	$graph = new Graph(400,240);
}
$graph->img->SetMargin(60,20,35,75);
$graph->SetScale("textlin");
$graph->SetMarginColor("lightblue:1.1");
$graph->SetShadow();
 
// Set up the title for the graph
$graph->title->Set("$header");
$graph->subtitle->Set("$URL_LINE $date");

//$graph->title->Set("$header\n$URL_LINE $date");
$graph->xaxis->title->Set("$x_axis_title","left");
$graph->yaxis->title->Set("$y_axis_title","middle");

// Setup font for axis
$graph->xaxis->SetFont(FF_VERDANA,FS_NORMAL,10);
$graph->yaxis->SetFont(FF_VERDANA,FS_NORMAL,10);

// Show 0 label on Y-axis (default is not to show)
$graph->yscale->ticks->SupressZeroLabel(false);

// Setup X-axis labels
$graph->xaxis->SetTickLabels($datax);
$graph->xaxis->SetLabelAngle(45);

// Create the bar pot
$bplot = new BarPlot($datay);
$bplot->SetWidth(0.6);

// Setup color for gradient fill style
$bplot->SetFillGradient("navy:0.9","navy:1.85",GRAD_LEFT_REFLECTION);

// Set color for the frame of each bar
$bplot->SetColor("white");
$graph->Add($bplot);

// Finally send the graph to the browser

// Finally send the graph to the browser
$graph->Stroke();
?>
