#!/usr/bin/perl

# Copyright 2011 Marcin Adamowicz <martin.adamowicz@gmail.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##### Description #####
# Asterisk CDR report for particuler extension
# Script connects to PostgreSQL Database with Asterisk CDR schema.
# Collects CDR data from 7days time frame and writes to PDF file.


# Pre-load custom modules to @INC
BEGIN { 
	use FindBin '$Bin';
	my $current_dir = "$Bin";
	push(@INC,"$current_dir/modules"); 
}

# CPAN modules
use DBI;
use PDF::Create;
use MIME::Lite; 

# Use custom module
use COUNTDATE;


# Database connection
my $dbengin	= "Pg";
my $host	= "localhost";
my $dbname	= "cdrdb";
my $dbuser	= "asteriskdb";
my $table	= "cdr";

# Set up time frame
my $start = COUNTDATE->date(); # 7 days ago
my $end = COUNTDATE->date(today); # take current date

# Set up report
my $exten = "";                                 # Report for Extension
my $filename = "cdr_report_for_$exten.pdf";
my $email = '';                                 # Recipient email address
my $cc = '';                                    # CC


# Open DB connection & send SQL query.
my $dbh = DBI->connect("dbi:$dbengin:dbname=$dbname;host=$host","$dbuser","$table");

my $report = $dbh->prepare("
        SELECT clid, calldate, dst, billsec, duration \
	FROM $table \
	WHERE dst = '$exten' \
	AND calldate::DATE \
	BETWEEN '$start'::DATE and '$end'::DATE
	");

$report->execute();

# -- Create PDF file.
my $pdf = new PDF::Create('filename'     => "$filename",
	'Version'      => 1.3,
	'PageMode'     => 'UseOutlines',
	'Author'       => 'Marcin Adamowicz',
	'Title'        => "CDR Report for exten: $exten",
	'CreationDate' => [ localtime ],
         );

# First page
my $root = $pdf->new_page('MediaBox' => [ 0, 0, 612, 792 ]);

# Add page based on  $root
my $page = $root->new_page;

# Set up fonts
my $f1 = $pdf->font('Subtype'  => 'Type1',
	'Encoding' => 'WinAnsiEncoding',
	'BaseFont' => 'Helvetica');

# Populate PDF file with data.
$page->stringl($f1, 16, 200, 750, "CDR REPORT FOR EXTEN $exten"); # Title
sub header {
	$page->string($f1, 8, 55, 715, "CALL DATE");    #column 1
	$page->string($f1, 8, 130, 715, "DESTINATION"); #column 2
	$page->string($f1, 8, 220, 715, "BILL SEC");    #column 3
	$page->string($f1, 8, 290, 715, "DURATION");    #column 4
	$page->string($f1, 8, 360, 715, "CALLER ID");   #column 5
};
&header();

# Start putting CDR report from line $line.
my $line = "700";
my $count_bill = "0";
my $count = "0";
while (my $ref = $report->fetchrow_hashref()) {

	#------------------------------------------
	## Add something to the first page

	$page->string($f1, 6, 50, $line, "$ref->{'calldate'}");
	$page->string($f1, 6, 150, $line, "$ref->{'dst'}");
	$page->string($f1, 6, 230, $line, "$ref->{'billsec'}");
	$page->string($f1, 6, 310, $line, "$ref->{'duration'}");
	$page->string($f1, 6, 360 , $line, "$ref->{'clid'}");
	$line = $line - 8;
	if ( $line lt "15" ) {
		$line = 700;
		$page = $root->new_page;
		&header();
	}
	$count_bill = $count_bill + $ref->{'billsec'};
	if ( $ref->{'billsec'} gt "0" ) {
		$count = $count + 1;
	}
}
$minute_bill = sprintf("%.2f", $count_bill / 60);
$page->string($f1, 10, 50, 40, "Total minutes: $minute_bill");
$page->string($f1, 10, 50, 20, "Total seconds: $count_bill");
$page->string($f1, 10, 250, 40, "Total active calls: $count");


$pdf->close;

# clean up
$dbh->disconnect();


#--- Email
my $msg = MIME::Lite->new(

	From	=>	'PBX@example.com',
	To	=>	"$email", 
	Cc	=>	"$cc", 
	Subject	=>	"CDR report for $exten in time frame $start - $end", 
	Data	=>	"$exten",
	Type	=>	'multipart/mixed'

); 
$msg->attach(
	Type    => 'TEXT',
	Data	=> "CDR report for $exten in time frame $start - $end"
);

$msg->attach(
	Type	=> 'image/pdf',
	Path	=> "./$filename",
	Filename	=> "$filename",
	Disposition	=> 'attachment'
);

$msg->send;
