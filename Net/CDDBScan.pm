package Net::CDDBScan;
require 5.004;

use strict;
use LWP::Simple;
use Data::Dumper;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw/new getsongs getalbums getartist/;
$VERSION = '2.00b';

1;

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->{ARG} = {@_};
	$self ? return $self : return undef;
}

sub getsongs {
	my $self = shift;
	if (@_) {
		$self->{URL} = shift;
		$self->{ERROR} = undef;
		print "$self>>Calling _getsongs();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$self = _getsongs($self);
		defined $self->{ERROR} ? return undef : return $self->{SONGS};
	}
	return undef;
}

sub getalbums {
	my $self = shift;
	if (@_) {
		$self->{URL} = shift;
		$self->{ERROR} = undef;
		print "$self>>Calling _getalbums();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$self = _getalbums($self);
		defined $self->{ERROR} ? return undef : return $self->{ALBUMS};
	}
	return undef;
}

sub getartist {
	my $self = shift;
	if (@_) {
		$self->{URL} = shift;
		$self->{ERROR} = undef;
		print "$self>>Calling _getartist();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$self = _getartist($self);
		defined $self->{ERROR} ? return undef : return $self->{ARTIST};
	}
	return undef;
}

sub DESTROY {
	my $self = shift;
	$self = {};
	return 1;
}

sub GetURL {
	my $self = shift;
	$self->{URL} =~ s!\s!+!g;
	$self->{URL} = 'http://www.cddb.com/xm/search?q=' . $self->{URL} . '&f=artist';
	my($package, $filename, $mline) = caller;

	# Wow, this is REALLY bad!!!  I'm working on it... please be patient.
	$self->{URL} =~ s!artist!disc! if $mline == 216;
	print "$self>>URL: $self->{URL}\n" if $self->{ARG}->{DEBUG};
	my @data = split('\n', get($self->{URL}));
	if (($#data -1) < 0) {
		$self->{ERROR} = 'NO DATA FOUND';
		# NOTE: We should really grab the error from LWP::Simple::get();
		# Or better, maybe we should inheret the function and capture the error directly
		return $self;
	}
	return(\@data);
}

sub getmessage {
	my $self = shift;
	$self->{URL} = 'http://www.cddb.com/xm/' . $self->{URL};
	print "$self>>URL: $self->{URL}\n" if $self->{ARG}->{DEBUG};
	my @data = split('\n', get($self->{URL}));
	if (($#data -1) < 0) {
		$self->{ERROR} = 'NO DATA FOUND';
		# NOTE: We should really grab the error from LWP::Simple::get();
		# Or better, maybe we should inheret the function and capture the error directly
		return $self;
	}
	return(\@data);
}

sub convert {
	my $localurl = shift;
	$localurl =~ s!(.*cddb.com/|.*xm/)(.*)!$2!;
	$localurl =~ s!^/?(.*)!$1!;
	return $localurl;
}

sub _getalbums {
	my $self = shift;
	my ($line, $data, $n1, $n2, $n3, $n4);

	if ($self->{URL} =~ m!(www|/|htm)!) {
		$self->{URL} = convert($self->{URL});
		print "$self>>Calling getmessage();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$data = getmessage($self);
	} else {
		print "$self>>Calling GetURL();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$data = GetURL($self);
	}
	if (!$self->{ERROR}) {
		foreach $line (@$data) {
			if ($line =~ /^\S*<LI/) {

# Sample of line we are trying to match
#<LI type=circle><FONT face="Arial, Helvetica, sans-serif"><B><!-- START ITEM --><!-- REL 100 ENDREL --><A HREF="/xm/cd/misc/283491e4acaf867123e876dd96a592d9.html" >Tricky / Broken Homes</A><!-- END ITEM -->         </B></FONT><div align=right><i><a href=http://www.gracenote.com/xm/refer?TAG:half&http://bot.half.com/texis/thunderstone/search/search/search.html?&product=music&search_by=artist&query=Tricky&ad=13461 target=buy>buy used</a> &nbsp;<a href=/fansites.html?Art=Tricky target=fans>fansites</a></i>&nbsp;&nbsp;</div><BR clear=all>

				if ($line =~ m!<A HREF=\"([^\"]+)\"\s?>\s?(([^<]+)\s?\/\s?)?([^<]+).*!) {
					($n1, $n2, $n3, $n4) = ($1, $2, $3, $4);
					$self->{OLDURL} = $self->{URL};
					print "$self>> Got an album: '$n4'\n" if $self->{ARG}->{DEBUG};
					$self->{URL} = $n1;
					$self->{ALBUMS}->{$n1} = $n4;
				}
			}

			if ($self->{ARG}->{CONT}) {

				if ($line =~ m!.*\[<A HREF=(.*)">.+NEXT.*\]!) {
					$self->{OLDURL} = $self->{URL};
					$self->{URL} = $1;
					print "$self>>Calling _getalbums();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
					_getalbums($self);
				}
			}
		}
	}
	return $self;
}

sub _getsongs {
	my $self = shift;
	my ($line, $data, $n1, $n2, $n3, $n4);

	if ($self->{URL} =~ m!(www|/|htm)!) {
		$self->{URL} = convert($self->{URL});
		print "$self>>Calling getmessage();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$data = getmessage($self);
	} else {
		print "$self>>Calling GetURL();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$data = GetURL($self);
	}

	if (!$self->{ERROR}) {

		foreach $line (@$data) {

			if ($line =~ /^\s*?<LI[\s|>]/) {
#.*<A HREF="/xm/cd/misc/1d5a47e10d45906a40f1c0f5e6fe48bf.html" >Tricky / Makes Me Wanna Die CD1</A>.*

				if ($line =~ m!<A HREF=\"([^\"]+)\"\s?>\s?(([^\/]+)\/)?\s?([^<]+)</A>!) {
					($n1, $n2, $n3, $n4) = ($1, $2, $3, $4);

					if ((defined $n2 && $n2 !~ /^(\s+)?$/) && (defined $n3 && $n3 !~ /^(\s+)?$/) && ($1 !~ /track/)) {
						$self->{OLDURL} = $self->{URL};
						$self->{URL} = $n1;
						print "$self>>Calling _getsongs();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
						_getsongs($self);
						last unless $self->{ARG}->{CONT};
					} else {
						$self->{OLDURL} = $self->{URL};
						print "$self>> Got a song: $n4\n" if $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} == 2;
						$self->{URL} = $n1;
						$self->{SONGS}->{$n1} = $n4;
					}
				}
			}
		}
		if ($self->{ARG}->{CONT}) {

			foreach $line (@$data) {

				if ($line =~ m!.*\[<A HREF="(.*)">.+NEXT.*\]!) {
					$self->{OLDURL} = $self->{URL};
					$self->{URL} = $1;
					print "$self>>Calling _getsongs();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
					_getsongs($self);
				}
			}
		}
	}
RETURN:
	return $self;
}

sub _getartist {
	my $self = shift;
	my ($line, $data, $n1, $n2, $n3, $n4);

	if ($self->{URL} =~ m!(www|\|htm)!) {
		$self->{URL} = convert($self->{URL});
		#print "URL: $url\n";
		print "$self>>Calling getmessage();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$data = getmessage($self);
	} else {
		print "$self>>Calling GetURL();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		$data = GetURL($self);
	}

	if (!$self->{ERROR}) {

		foreach $line (@$data) {

			if ($line =~ /^\s*<LI/) {

				if ($line =~ m!<A HREF=\"([^\"]+)\"\s?>\s?(([^\/]+)\/)?\s?([^<]+)</A>!) {
					($n1, $n2, $n3, $n4) = ($1, $2, $3, $4);
					if ($n3 !~ /^(\s+)?$/) {
						$self->{ARTIST} = $n3;
						last;
					}
					$self->{OLDURL} = $self->{URL};
					$self->{URL} = $n1;
					print "$self>>Calling _getmessage();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
					_getartist($self);
				}
			}
		}
	}
	return $self;
}

sub close () { &DESTROY; }
__END__

=head1 NAME

Net::CDDBScan - String search interface to CDDB datbase

=head1 SYNOPSIS

use Net::CDDBScan;

        Grab a list of all songs for Madonna
	$cddb = Net::CDDBScan->new(CONT =>1);
        $songs = $cddb->getsongs("madonna");
        print $songs{$_},'\n' foreach %{$songs};
        $cddb->close();

=head1 DESCRIPTION

Net::CDDBScan is an interface to the www.cddb.com website; or more specifically
to their online search engine for the cddb database.  Originally created as a
small part of a greater application.  This module allows you to take any existing
string like "tricky" or "for whom the bell tolls" and get the artist name, all
albums from said artist and all songs on ANY album said artist has ever worked
on. (Or close enough: This is assuming the cddb database has a record of the
given artist/album/song.)

=head1 USING Net::CDDBScan

=over 4

=item B<1. Creating a Net::CDDBScan object>

You first must create a Net::CDDBScan object.

my $cddb = Net::CDDBScan->new();

new() has the following optional parameters:

       DEBUG: Debug has 2 levels, the first level shows all urls, albums
and songs as it finds them. The second level also shows all internal function
calls.  You shouldn't ever need to use level 2 but it's there if you feel
the need.

B<DEBUG>

Level 1:
$cddb = Net::CDDBScan->new(DEBUG =>1);

Level 2:
$cddb = Net::CDDBScan->new(DEBUG =>2);

Pretty simple I would think.  These currently print to stdout, but I
may change that to stderr in the future as it would seem easier to redirect
to error logs all debug output without also getting the std output you may
still want in stdout.

B<CONT>

CONT is used to tell Net::CDDBScan if you want it to continue or not. Default
is no since it can take longer then you may desire. If you ask for a list of
albums for the band Portishead.

$albums = $cddb->getalbums("portishead");

Net::CDDBScan will retrieve a list of albums, but only one page worth, that is
it will only grab 1 html page worth of data (usually 7-9 items).  But, if you
want Net::CDDBScan to get ALL albums for a band, then you can set CONT as:

$cddb = Net::CDDBScan->new(CONT =>1);

This will cause Net::CDDBScan to continue through all pages gathering albums
until none are left.  NOTE: This also works for songs, but not for artist
(since one entry is enough to tell us who the artist is. This may change in
the future as you may want to know all possible artists for a song or album).

=item B<2. Getting a list of all albums for a given artist.>

getalbums()

NOTE: Must use the B<CONT> contructor option to get 'ALL' albums

$albums = $cddb->getalbums("medusa");

print $albums{$_},'\n' foreach (keys %$albums);

Returns a reference to a hash of album urls and names (The key is the
url and the value is the album name). This function also takes any cddb.com url
or partial url in the following formats:

B<http://www.cddb.com/xm/search?f=artist&q=medusa>

B<www.cddb.com/xm/search?f=artist&q=medusa>

B</xm/search?f=artist&q=medusa>

B</xm/search?q=medusa>

B<medusa> etc... you get the idea.

The reason for taking all these types of urls/strings is based on the internal usage
of this function.  These formats are not planned to change.

=item B<3. Getting a list of all songs for all albums of a given artist.>

getsongs()

	$songs = $cddb->getsongs("cocteau twins");
	print $songs{$_},'\n' foreach (keys %$songs);

This function accepts all the url/string formats that B<getalbums()> takes and
otherwise acts just like getalbums() including returning a hashref of urls and
song names.

=item B<4. Determining an Artist name based on an album or song name.>

getartist()

"Mezzanine" is the name of a Massive Attach album

$artist = $cddb->getartist("mezzanine");

NOTE: Currently you cannot do:

$artist = $cddb->getartist('less then strangers');

i.e. You cannot use ANY string for an artist search.  Sorry, it's a limitation
of the cddb.com search engine.  I'm currently working on a work-around. You can
use any of the cddb url formats listed above.

$songs = $cddb->getsongs('less then strangers');

@urls = key %{$songs};

$artist = $cddb->getartist($urls[0]);

=back

=head1 NOTICE

Be aware this module is in B<BETA> stage.  Some major changes have happened as I said they would. The biggest change is that getalbums() and getsongs() return hashrefs instead of arrayrefs now. Sorry for the change, but this makes room for much more functionality down the road. More changes are expected which will allow much cleaner usage, much more functionality and caching of data to a local cddb database (optional). If you have any comments, suggestions and/or patches you'd like to submit.  Please email me at dshultz@redchip.com

=head1 AUTHOR

Copyright 1998-2000, David J. Shultz All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
Address bug reports and comments to: dshultz@redchip.com

=head1 BUGS

This section intentionally left blank.

=head1 SEE ALSO

perl(1).

=cut
