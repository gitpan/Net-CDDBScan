$NAME     = 'Net::CDDBScan';
$VERSION  = '1.44';

BEGIN { require 5.002 }

use ExtUtils::MakeMaker;

sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 local($|) = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
				 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

chk_version(LWP::Simple => '1.32') or warn "\n" . "*** For Net::CDDBScan to work you need LWP::Simple version 1.32 or later.\n"
  ."     from CPAN/modules/by-module/LWP/libnet/libwww-perl-5.48.tar.gz\n\n";

WriteMakefile(
    VERSION     => $VERSION,
    NAME        => $NAME,
    AUTHOR      => 'David Shultz <dshultz@redchip.com>',
    ABSTRACT    => 'Module to extract album and song names from CDDB without CD ID.',
    PREREQ_PM   => { LWP::Simple => 1.32 }
);
