#! /usr/bin/perl
#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################
use Spreadsheet::ParseExcel;

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($ARGV[0]);

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}

for my $worksheet ( $workbook->worksheets() ) {

    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    
    for my $row ( 3 .. $row_max ) {
	my @cols = (0, 1); 
        for my $col (@cols) {

            my $cell = $worksheet->get_cell( $row, $col );
            next unless $cell;
	    push(@fname, $cell->value());
   	 }
	#remove leading and trailing whitespace
	#$fname[0] is the Item Number
	#$fname[1] is the file name
	
	#Clear the "Doc" description out of the file name
	$fname[1] =~ s/Doc\ //g;

	$fname[1] =~ s/^\s+//; #remove leading spaces
	$fname[1] =~ s/\s+$//; #remove trailing spaces`

   	if($fname[1]) {
    		print("$fname[0]%%$fname[1]\n");
   	}
   	undef(@fname);
   }
}
