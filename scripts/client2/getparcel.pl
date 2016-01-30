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
    
    #Get the Parcel Number for the link
    # Get the Cover Report, Tax Assesment, Flowchart, and Historic maps first
    my $cell = $worksheet->get_cell( 1, 10 );

    my $parcelno = $cell->value();
    #Remove Auditor's Parcel No. from string
    #$parcelno =~ s/Auditor's Parcel No.//g;
    #remove leading and trailing whitespace
    #$parcelno =~ s/^\s+|\s+$//g;
    my @values = split(' ', $parcelno);
    print("$values[3]");
   
}
