package Net::CDDBScan;
require 5.004;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use LWP::Simple;
#use HTTP::Status;
use URI::Escape;
#use Data::Dumper;

require Exporter;

@ISA = qw/Exporter/;
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw//;

@EXPORT_OK = qw/new getsongs getablums getartist/;

$VERSION = '2.01';

# constructor optional params are: DEBUG and CONT
# {{{ new

sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    $self->{ARG} = {@_};
    $self ? return $self : return undef;
}

# }}} new

# wrapper func to get songs from the given url
# {{{ getsongs

sub getsongs {
    my $self = shift;
    if (@_) {
	$self->{URL} = uri_escape(shift);
	$self->{ERROR} = undef;
	$self->{TYPE} = 'track';
	print "$self>>Calling _getsongs();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} == 2);
	$self = _getsongs($self);
	defined $self->{ERROR} ? return undef : return $self->{SONGS};
    }
    $self->{ERROR} = 'No url provided';
    return undef;
}

# }}} getsongs

# wrapper func to get albums from the given url
# {{{ getalbums

sub getalbums {
    my $self = shift;
    if (@_) {
	$self->{URL} = uri_escape(shift);
	$self->{ERROR} = undef;
	$self->{TYPE} = 'disc';
	print "$self>>Calling _getalbums();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} == 2);
	$self = _getalbums($self);
	defined $self->{ERROR} ? return undef : return $self->{ALBUMS};
    }
    $self->{ERROR} = 'No url provided';
    return undef;
}

# }}} getalbums

# wrapper func to get artist name(s) from the given url
# {{{ getartist

sub getartist {
    my $self = shift;
    if (@_) {
	$self->{URL} = uri_escape(shift);
	$self->{ERROR} = undef;
	$self->{TYPE} = 'artist';
	print STDOUT "$self>>Calling _getartist();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} == 2);
	$self = _getartist($self);
	defined $self->{ERROR} ? return undef : return $self->{ARTIST};
    }
    $self->{ERROR} = 'No url provided';
    return undef;
}

# }}} getartist

# destructor
# {{{ DESTROY

sub DESTROY {
    my $self = shift;
    $self = {};
    return 1;
}

# }}} DESTROY

# get html data based on the given url
# {{{ GetURL

sub GetURL {
    my $self = shift;
    if ($self->{URL} =~ /(www|\/|htm)/) {
	$self->{URL} =~ s!(.*cddb.com/|.*xm/)(.*)!$2!;
	$self->{URL} =~ s!^/?(.*)!$1!;
	$self->{URL} = 'http://www.cddb.com/xm/' . $self->{URL};
    } else {
	$self->{URL} = 'http://www.cddb.com/xm/search?q=' . $self->{URL};
#	$self->{URL} .= '&f=' . $self->{TYPE} if (($self->{TYPE} eq 'track') || ($self->{TYPE} eq 'artist'));
	$self->{URL} .= '&f=' . $self->{TYPE} if ($self->{TYPE} eq 'track');
    }

    print STDOUT "$self>>URL: $self->{URL}\n" if $self->{ARG}->{DEBUG};
    my $data = get($self->{URL});

    #    if (is_error($data)) {
    #	$self->{ERROR} = status_message($data);
    #	return undef;
    #    }
    $self->{DATA} = [split('\n', $data)];
    return $self
}

# }}} GetURL

# locates and returns a hash of url/names based on the given url
# {{{ _getalbums

sub _getalbums {
    my $self = shift;
    # setup some local vars
    my($line, $n1, $n2, $n3, $n4);

    print "$self>>Calling GetURL();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
    $self = GetURL($self);

    return $self if (!$self->{DATA});

    foreach $line (@{$self->{DATA}}) {
	if ($line =~ /^\s*?<LI[\s|>]/) {

	    if ($line =~ m!<A HREF=\"([^\"]+)\"\s?>\s?(([^<]+)\s?\/\s?)?([^<]+).*!) {
		($n1, $n2, $n3, $n4) = ($1, $2, $3, $4);
		push(@{$self->{OLDURL}}, $self->{URL});
		print "$self>> Got an album: '$n4'\n" if $self->{ARG}->{DEBUG};
		$self->{URL} = $n1;
		$self->{ALBUMS}->{$n1} = $n4;
	    }
	}

	if ($self->{ARG}->{CONT}) {

	    if ($line =~ m!.*\[<A HREF=(.*)">.+NEXT.*\]!) {
		push(@{$self->{OLDURL}}, $self->{URL});
		$self->{URL} = $1;
		print "$self>>Calling _getalbums();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		_getalbums($self);
	    }
	}
    }
    return $self;
}

# }}} _getalbums

# locates and returns an hash of url/names based on the given url
# {{{ _getsongs

sub _getsongs {
    my $self = shift;
    my($line, $n1, $n2, $n3, $n4);

    print "$self>>Calling GetURL();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
    $self = GetURL($self);

    return $self if (!$self->{DATA});

    foreach $line (@{$self->{DATA}}) {
	if ($line =~ /^\s*?<LI[\s|>]/) {

	    if ($line =~ m!<A HREF=\"([^\"]+)\"\s?>\s?(([^<]+)\s?\/\s?)?([^<]+).*!) {
		($n1, $n2, $n3, $n4) = ($1, $2, $3, $4);

		if ((defined $n2 && $n2 !~ /^(\s+)?$/) && (defined $n3 && $n3 !~ /^(\s+)?$/) && ($1 !~ /track/)) {
		    push(@{$self->{OLDURL}}, $self->{URL});
		    $self->{URL} = $n1;
		    print "$self>>Calling _getsongs();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		    _getsongs($self);
		    last unless $self->{ARG}->{CONT};
		} else {
		    push(@{$self->{OLDURL}}, $self->{URL});
		    print "$self>> Got a song: $n4\n" if $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} == 2;
		    $self->{URL} = $n1;
		    $self->{SONGS}->{$n1} = uri_unescape($n4);
		}
	    }
	}
    }
    if ($self->{ARG}->{CONT}) {
	foreach $line (@{$self->{DATA}}) {
	    if ($line =~ m!.*\[<A HREF="(.*)">.+NEXT.*\]!) {
		push(@{$self->{OLDURL}}, $self->{URL});
		$self->{URL} = $1;
		print "$self>>Calling _getsongs();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		_getsongs($self);
	    }
	}
    }
    $self->{DATA} = undef;
    return $self;
}

# }}} _getsongs

# locates and returns an artist based on the given url
# {{{ _getartist

sub _getartist {
    my $self = shift;
    my($line, $n1, $n2, $n3, $n4);

    print "$self>>Calling GetURL();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
    $self = GetURL($self);

    return $self if (!$self->{DATA});

    foreach $line (@{$self->{DATA}}) {
	if ($line =~ /^\s*?<LI[\s|>]/) {

	    if ($line =~ m!<A HREF=\"([^\"]+)\"\s?>\s?(([^\/]+)\/)?\s?([^<]+)</A>!) {
		($n1, $n2, $n3, $n4) = ($1, $2, $3, $4);
		if ($n3 !~ /^(\s+)?$/) {
		    $self->{ARTIST} = $n3;
		    last;
		}
		push(@{$self->{OLDURL}}, $self->{URL});
		$self->{URL} = $n1;
		print "$self>>Calling _getmessage();\n" if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} ==2);
		_getartist($self);
	    }
	}
    }
    $self->{DATA} = undef;
    return $self;
}

# }}} _getartist

# loads the master db hash from disk
sub load_data {
}

# writes the master db hash to disk
sub dump_data {
}

# takes a hashref off the master db hash and links it on the $self obj for current return data
sub link_data {
    my $self = shift;
}
1;
__END__

=head1 NAME

Net::CDDBScan - String search interface to CDDB datbase

=head1 SYNOPSIS

C<use Net::CDDBScan;>

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

C<my $cddb = Net::CDDBScan-E<gt>new()>

new() has the following optional parameters:

       DEBUG: Debug has 2 levels, the first level shows all urls, albums
and songs as it finds them. The second level also shows all internal function
calls.  You shouldn't ever need to use level 2 but it's there if you feel
the need.

B<DEBUG>

Level 1:
B<C<$cddb = Net::CDDBScan-E<gt>new(DEBUG =E<gt>1)>>

Level 2:
B<C<$cddb = Net::CDDBScan-E<gt>new(DEBUG =E<gt>2)>>

Pretty simple I would think.  These currently print to stdout, but I
may change that to stderr in the future as it would seem easier to redirect
to error logs all debug output without also getting the std output you may
still want in stdout.

B<CONT>

CONT is used to tell Net::CDDBScan if you want it to continue or not. Default
is no since it can take longer then you may desire. If you ask for a list of
albums for the band Portishead.

B<C<$albums = $cddb-E<gt>getalbums("portishead");>>

Net::CDDBScan will retrieve a list of albums, but only one page worth, that is
it will only grab 1 html page worth of data (usually 7-9 items).  But, if you
want Net::CDDBScan to get ALL albums for a band, then you can set CONT as:

B<C<$cddb = Net::CDDBScan-E<gt>new(CONT =E<gt>1);>>

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






