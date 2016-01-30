#! /usr/bin/perl
use Text::Iconv;
my $converter = Text::Iconv -> new ("utf-8", "windows-1251");
 
# Text::Iconv is not really required.
# This can be any object with the convert method. Or nothing.

use Spreadsheet::XLSX;
my $excel = Spreadsheet::XLSX -> new ($ARGV[0], $converter);
foreach my $sheet (@{$excel -> {Worksheet}}) {
        foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
		
               # Get the Cover Report, Tax Assesment, Flowchart, and Historic maps first
               foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
			if ($row > 2 and $row < 7) {
       		        	my $cell = $sheet -> {Cells} [$row] [$col];
				#Skip if empty
				next unless $cell;
            			
				my $rname = $cell  -> {Val};
       			     	#remove leading and trailing whitespace
	       		     	$rname =~ s/^\s+|\s+$//g;
	
       				push(@hname, $rname);
   			}
		}
         	if($hname[0] and $hname[1]) {
               		print("$hname[0]%%$hname[1]\n");
         	}
         	undef(@hname);

	       #Now read the rest	
               foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
			if($row > 7) {
				my @cols = (0, 3, 4, 5);
				if($col ~~ @cols) { 
       		        		my $cell = $sheet -> {Cells} [$row] [$col];
					#Skip if empty
					next unless $cell;
            			
					push(@fname, $cell -> {Val});
				}
			}
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
