#!/usr/bin/perl -w

# Test ability to retrieve Album and song info

use lib '../blib/lib','../blib/arch';

BEGIN {$| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::CDDBScan;
$loaded = 1;
print "ok 1\n";

my $cddba = Net::CDDBScan->new();
my $a = $cddba->getalbums("tricky");
my @albums = @$a;
if ($#albums > 0) {print "ok 2\n"; } else { print "not ok 2\n"; }
$cddba->close();

my $cddbb = Net::CDDBScan->new();
my $s = $cddbb->getsongs("tricky");
my @songs = @$s;
if ($#songs > 0) {print "ok 3\n";} else {print "not ok 3\n";}
$cddbb->close();
