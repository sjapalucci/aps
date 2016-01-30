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
    
    # Get the Cover Report, Tax Assesment, Flowchart, and Historic maps first
     for my $row ( 3 .. 6 ) {
	my @fcols = (0, 2);
        for my $col (@fcols) {

            my $cell = $worksheet->get_cell( $row, $col );
            next unless $cell;
	    
            $rname = $cell->value();
	    $rname =~ s/^\s+|\s+$//g;
	    #remove leading and trailing whitespace

	    #Skip if empty
	    push(@hname, $rname);
         }
         if($hname[0] and $hname[1]) {
	 	print("$hname[0]%%$hname[1]\n");
	 }
	 undef(@hname);
   }


    for my $row ( 7 .. $row_max ) {
	my @cols = (0, 3, 4, 5); 
        for my $col (@cols) {

            my $cell = $worksheet->get_cell( $row, $col );
            next unless $cell;
	    
            #print "Value       = ", $cell->value(),       "\n";
	    push(@fname, $cell->value());
   	 }
	#remove leading and trailing whitespace
	$fname = grep(s/\s*$//g, @fname);
   	if($fname[1] and $fname[2] and $fname[3]) {
    		print("$fname[0]%%$fname[1] $fname[2]-$fname[3]\n");
   	} elsif($fname[0] and $fname[1]) {
		print("$fname[0]%%$fname[1]\n");
   	}
   	undef(@fname);
   }
}
