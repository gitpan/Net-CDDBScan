use lib '../blib/lib','../blib/arch';

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::CDDBScan;

$loaded = 1;
print "ok 1\n";

my $cddba = Net::CDDBScan->new();
my $songs = $cddba->getsongs('skinny puppy');
push(@s, $songs->{$_}) foreach keys %{$songs};
if ($#s > 0) { print "ok 2\n"; } else { print "not ok 2\n"; }

my $cddbb = Net::CDDBScan->new();
my $albums = $cddbb->getalbums('skinny Puppy');
push(@a, $albums->{$_}) foreach keys %{$albums};
if ($#a > 0) { print "ok 3\n"; } else { print "not ok 3\n" }

my $cddbc = Net::CDDBScan->new();
my $artist = $cddbc->getartist('tiny warnings');
if ($artist) { print "ok 4\n"; } else { print "not ok 4\n"; }
