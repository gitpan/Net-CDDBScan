BEGIN { require 5.002 }

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);

#--- MY package

sub MY::libscan
{
 my($self,$path) = @_;

 return '' 
	if($path =~ m:/(RCS|CVS|SCCS)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej|nfs)$:
	  );
 $path;
}

#--- Installation check

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

sub MY::post_initialize
{
 my ($self) = @_;
}

#--- Check for Socket

chk_version(LWP::Simple => '1.32') or
    warn  "\n"
 . "*** For Net::CDDBScan to work you require version 1.32, or later, of\n"
	. "    LWP::Simple from CPAN/modules/by-module/LWP/libnet/libwww-perl-5.48.tar.gz\n\n";

chk_version(URI::Escape => '3.16') or
    warn  "\n"
 . "*** For Net::CDDBScan to work you require version 3.16, or later, of\n"
	. "    URI::Escape from CPAN/modules/by-module/URI/URI-1.10.tar.gz\n\n";

#--- Write the Makefile

WriteMakefile(
	VERSION   => '2.01',
	NAME      => 'Net::CDDBScan',
	AUTHOR    => 'David Shultz <dshultz@redchip.com>',
	ABSTRACT  => 'Module to extract album and song names from CDDB database without needing CD ID.',
	PREREQ_PM => {
		      LWP::Simple => 1.32,
		      URI::Escape => 3.16,
		    },
);






