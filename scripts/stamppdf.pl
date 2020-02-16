#! /usr/bin/perl
#################################################################################
# Written by Steven M Japalucci <steve.japalucci@gmail.com>, August 2013
#################################################################################
use PDF::Reuse;

$width       = $ARGV[0];
$height      = $ARGV[1];
$itemno      = $ARGV[2];
$filename    = $ARGV[3];
$pgcount     = $ARGV[4];

$file = "/usr/local/bin/aps/template.pdf";
prFile($file);
prCompress (1);
prMbox(0, 0, $width, $height);

#Get x/y for placement of strings
#calculate the center by dividing
#the width in half and subtracting the width of the string
#$xtitle = prStrWidth($itemno, "Helvetica", 10);
$x = $width - 100;#($xtitle / 2);
$xbottom = $width - 100;
$ytop = $height - 20;

prFontSize(8);
prAdd("1.0 0.0 0.0 rg");
my ($from, $pos) = prText($x, $ytop, $itemno);
my ($from, $pos) = prText($xbottom, 30, $filename);
my ($from, $pos) = prText($xbottom, 10, $pgcount);

prEnd();
