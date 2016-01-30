#!/usr/bin/perl -w
use strict;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::SaveParser;
use OLE::Storage_Lite;

#This is the remote directory that is used to build the link
my $remotedir = "http://aps.brightonresources.com/Shared";

#Check Parameters
if (@ARGV < 1) {
	print STDERR "Usage: writelink.pl filename\n";
	exit 1;
}
my $URL = $ARGV[1];

# Open the template with SaveParser
#This is the instance to MODIFY the file
my $parser   = new Spreadsheet::ParseExcel::SaveParser;
my $template = $parser->Parse($ARGV[0]);

#This is the instance to READ the file
my $parser_read   = Spreadsheet::ParseExcel->new();
my $workbook_read = $parser->parse($ARGV[0]);


my $sheet    = 0;
my $col      = 1;

# The SaveParser SaveAs() method returns a reference to a
# Spreadsheet::WriteExcel object. If you wish you can then
# use this to access any of the methods that aren't
# available from the SaveParser object. If you don't need
# to do this just use SaveAs().
#
my $workbook;

{
    # SaveAs generates a lot of harmless warnings about unset
    # Worksheet properties. You can ignore them if you wish.
    local $^W = 0;

    # Rewrite the file or save as a new file
    $workbook = $template->SaveAs($ARGV[0]);
}

#Set the format for the links
my $linkformat = $workbook->add_format(
                                    size => 8,
                                    align => 'center',
                                    underline => 1,
                                    color => 'blue',
                                    text_wrap => 1,
                                    top => 1,
                                    bottom => 1,
                                    left => 1,
                                    right => 1
                                 );
my $NFformat = $workbook->add_format(
                                    size => 8,
                                    align => 'center',
				    bold => 1,
                                    color => 'black',
                                    text_wrap => 1,
                                    top => 1,
                                    bottom => 1,
                                    left => 1,
                                    right => 1
                                 );


for my $worksheet_read ( $workbook_read->worksheets() ) {

    my ( $row_min, $row_max ) = $worksheet_read->row_range();
    my ( $col_min, $col_max ) = $worksheet_read->col_range();

    #Get the Parcel Number for the link
    # Get the Cover Report, Tax Assesment, Flowchart, and Historic maps first
    my $cell = $worksheet_read->get_cell( 1, 10 );

    my $parcelno = $cell->value();
    #Remove Auditor's Parcel No. from string
    #$parcelno =~ s/Auditor's Parcel No.//g;
    #remove leading and trailing whitespace
    my @values = split(' ', $parcelno);
    $parcelno = $values[3];

    $parcelno =~ s/^\s+|\s+$//g;

    #Set the variable to build the URL
    my $URL;
    my $format;

    # Get the Cover Report, Tax Assesment, Flowchart, and Historic maps first
     for my $row ( 3 .. 6 ) {
	my $rname;
        for my $col ( 2 ) {

            my $cell = $worksheet_read->get_cell( $row, $col );
            next unless $cell;

            $rname = $cell->value();
            #remove leading and trailing whitespace
            $rname =~ s/^\s+|\s+$//g;
         }
	if($rname =~ /^NF.*/) { 
		$URL = ""; 
		$format = $NFformat;
	} else { 
		$URL = "$remotedir/$parcelno/download.php?file=$rname.pdf"; 
		$format = $linkformat;
	}
	my $worksheet  = $workbook->sheets(0);
	$worksheet->write_url($row, 1, $URL, $rname, $format);
    }
    for my $row ( 7 .. $row_max ) {
	my $fname;
	my @fname;
        for my $col ( 3 .. 5 ) {

            my $cell = $worksheet_read->get_cell( $row, $col );
            next unless $cell;
            push(@fname, $cell->value());
         }
        #remove leading and trailing whitespace
        $fname = grep(s/\s*$//g, @fname);
	my $label;
        if($fname[0] and $fname[1] and $fname[2]) {
                $label = "$fname[0] $fname[1]-$fname[2]";
        } elsif($fname[0]) {
                $label = "$fname[0]";
        }
	if($label) {
		if($label =~ /^NF.*/) { 
			$URL = ""; 
			$format = $NFformat;
		} else { 
			$URL = "$remotedir/$parcelno/download.php?file=$label.pdf"; 
			$format = $linkformat;
		}
		my $worksheet  = $workbook->sheets(0);
		$worksheet->write_url($row, 1, $URL, $label, $format);
	}
        undef(@fname);
   }
}
$workbook->close();
