#! /usr/bin/perl
use Spreadsheet::ParseExcel;

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($ARGV[0]);

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}

for my $worksheet ( $workbook->worksheets() ) {

    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    
    $count = 1;
    for my $row ( 2 .. $row_max ) {
	my @cols = (0); 
        for my $col (@cols) {

            my $cell = $worksheet->get_cell( $row, $col );
            next unless $cell;
	    push(@fname, $cell->value());
   	 }
	#remove leading and trailing whitespace
	#$fname[0] is the file name
	
   	if($fname[0]) {
    		print("$count%%Lease $fname[0]\n");
		$count++;
   	}
   	undef(@fname);
   }
}
