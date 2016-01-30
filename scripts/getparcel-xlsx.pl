#! /usr/bin/perl
#################################################################################
# Copyright (C) Steven M. Japalucci - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Written by Steven M Japalucci RHCE RHCT <steve.japalucci@gmail.com>, August 2013
#################################################################################
use Text::Iconv;
my $converter = Text::Iconv -> new ("utf-8", "windows-1251");
 
# Text::Iconv is not really required.
# This can be any object with the convert method. Or nothing.

use Spreadsheet::XLSX;
my $excel = Spreadsheet::XLSX -> new ($ARGV[0], $converter);
foreach my $sheet (@{$excel -> {Worksheet}}) {
       $sheet -> {MaxRow} ||= $sheet -> {MinRow};
        foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
               $sheet -> {MaxCol} ||= $sheet -> {MinCol};
               foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
		       if ($row == 1 and $col == 10) {
                       		my $cell = $sheet -> {Cells} [$row] [$col];
                       		if ($cell) {
					my $parcelno = $cell -> {Val};
    					my @values = split(' ', $parcelno);
    					print("$values[3]\n");
                       		}
			}
               }
       }
}
