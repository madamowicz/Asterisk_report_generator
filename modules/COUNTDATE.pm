###filename: COUNTDATE.pm

package COUNTDATE;

sub date {

	$p0 = $_[0]; # Package name.
	$p1 = $_[1];

	if ( ($p1) eq 'today' ) {
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
	} else {
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time-86400*7);
		print "$p1\n";
	}

$year = $year + 1900;
$mon = $mon + 1;
$mon = &check_length($mon);
$mday = &check_length($mday);

	sub check_length {
		my $correct = $_[0];
			if (length($correct) eq 1) {
			$correct = "0".$correct;
			}
		return $correct;
	}

	my $date = "$year-$mon-$mday";
	return $date

}

1; #do not erse it.
