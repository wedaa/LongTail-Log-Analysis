<?php // content="text/plain; charset=utf-8"
// Example for use of JpGraph,
//Lightly modified from http://jpgraph.net/download/manuals/chunkhtml/ch08s04.html

require_once ('/usr/local/php/jpgraph-3.5.0b1/src/jpgraph.php');
require_once ('/usr/local/php/jpgraph-3.5.0b1/src/jpgraph_bar.php');
require_once ('/usr/local/php/jpgraph-3.5.0b1/src/jpgraph_line.php');
require_once ('/usr/local/php/jpgraph-3.5.0b1/src/jpgraph_plotline.php');


// USAGE: php /usr/local/etc/LongTail_make_graph.php filename "header" "X-axis label" "Y-axis label"
// Must pass full filename to read and "Quote delimited text header"
// And redirect the output to a file
// php LongTail_make_graph.php /var/www/html/honey/current-top-20-root-passwords.data "Current top 20 root passwords" "X Title" "Y Title" "wide">current-top-20-root-passwords.png 
// php LongTail_make_graph.php /var/www/html/honey/current-top-20-root-passwords.data "Current top 20 root passwords" "X Title" "Y Title" "">current-top-20-root-passwords.png 

$maxvalue=0;

$file = $argv[1];
$header = $argv[2];
$x_axis_title =  $argv[3];
$y_axis_title =  $argv[4];
$size=$argv[5];
 
$min=$argv[6];
$max=$argv[7];
$average=$argv[8];
if (isset ($argv[9])){
	$show_max_attack=$argv[9];
}
$labelmax=$max;

//print "min is $min";
//print "max is $max";
//print "average is $average";
//exit;

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
		if (strpos($file, 'non-root-accounts.data') !== false) {
			// print "non-root-accounts.data found\n";
			if ("$account" != "root"){
				// print "non-root-accounts found --$account--\n";
				$datay[$counter]=$count;
				$datax[$counter]=$account;
				$counter++;
				if ( $count > $maxvalue ){$maxvalue=$count;}
			}
		}
		else {
			$datay[$counter]=$count;
			$datax[$counter]=$account;
			$counter++;
			if ( $count > $maxvalue ){$maxvalue=$count;}
		}
	}
    if (!feof($myfile)) {
        echo "Error: unexpected fgets() fail\n";
    }
    fclose($myfile);
}
$max_data_point=$maxvalue;


$maxvalue=$average*1.1;
if ($max_data_point >$max){
	$maxvalue=$max*1.10;
}
elseif ($max_data_point > $average*2){
	$maxvalue=$max*1.1;
}
elseif ($max_data_point < $average*(1.5)){
	$maxvalue=$average*1.1;
}
elseif ($max_data_point < $average*2){
	$maxvalue=$average*2;
}

if ($average*2 > $max){
	$maxvalue=$max*1.05;
}

if (isset ($show_max_attack) ){
	$maxvalue=$show_max_attack*1.05;
}


if ($max > $maxvalue){
	$maxvalue=$max*1.05;
}

// setup the graph.
if ($size == "wide"){
	$graph = new graph(810,300);
}
else {
	$graph = new graph(400,240);
}
$graph->img->setmargin(60,20,35,75);
$graph->SetScale("textlin");
$graph->SetMarginColor("lightblue:1.1");
$graph->SetShadow();
 
// Set up the title for the graph
$graph->title->Set("$header");
$graph->xaxis->title->Set("$x_axis_title","left");
$graph->yaxis->title->Set("$y_axis_title","middle");

// Setup font for axis
$graph->xaxis->SetFont(FF_VERDANA,FS_NORMAL,10);
$graph->yaxis->SetFont(FF_VERDANA,FS_NORMAL,10);

// Show 0 label on Y-axis (default is not to show)
$graph->yscale->ticks->SupressZeroLabel(false);

$graph->yaxis->scale->SetAutoMax($maxvalue);


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

$graph->legend->SetPos(0.5,0.97,'center','bottom');
$pline = new PlotLine(HORIZONTAL,$min,'blue',2);
$legend="Minimum($min)";
$pline->SetLegend($legend);
$graph->Add($pline);

$pline = new PlotLine(HORIZONTAL,$average,'green',1);
$legend="Average($average)";
$pline->SetLegend($legend);
$graph->Add($pline);

$pline = new PlotLine(HORIZONTAL,$max,'red',5);
$legend="Maximum($max)   Current Value($max_data_point) ";
$pline->SetLegend($legend);
$graph->Add($pline);

// Finally send the graph to the browser
$graph->Stroke();
?>
