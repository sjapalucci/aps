#! /usr/bin/perl
#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################

use PDF::API2;

# Create a blank PDF file
$pdf = PDF::API2->new();
$pdf = PDF::API2->open($ARGV[0]);

#Get the parcel no for the title
$title = $ARGV[1] or die("Usage: bmark.pl filename parcelno\n");

#Set the Bookmarks to be onened for Initial View
$pdf->preferences(
        -outlines => 1,
	);

#Setup some PDF Information
$pdf->info(
        'Author'       => "APS (Automated Packaging System)",
        'Creator'      => "APS (Automated Packaging System)",
        'Producer'     => "mkpdf.sh",
        'Title'        => "$title",
    );

# Save the PDF
$pdf->saveas($ARGV[0]);
