package Net::CDDBScan;
require 5.004;

# Copyright 1998 David Shultz All rights reserved.
# This module may be used freely, but this copyright notice
# must remain in this file.  You can modify any and all parts,
# but if you redistribute a modfied version, please include
# a notice listing the modifications you made.

# You can obtain the most recent version either from CPAN
# or by emailing me a request at <dshultz@redchip.com>.
# 

use strict;
use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION/;

use Exporter;
my $VERSION = '1.44';
my $TYPE; # Can be one of the following: ARTIST ALBUM SONG

my (@urls, @songurls, %seen); #Globals

@ISA = qw/Exporter LWP::Simple/;

@EXPORT = qw/new/;
@EXPORT_OK = qw/getsongs getalbums getartist/;

%EXPORT_TAGS = ();

use LWP::Simple;

# PUBLIC FUNCTIONS:

# Constructor - returns a ref to a new CDDBScan object
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->{ARG} = (@_);
	$self ? return $self : return undef;
}

# Destructor - returns undef
sub close {
	my $self = shift;
	&DESTROY();
	return undef;
}

# Takes a url and returns the artist name (based on the url)
sub getartist {
	my $self = shift;
	if (@_) {
		push(@urls, shift);
		$self->{TYPE} = "ARTIST"; # this is so we remember the original request type
		$TYPE = "ARTIST";
		$self = _getlinks($self);
		return $self->{ARTIST};
	}

	# if no values passed, return undef
	return undef;
}

# Takes a url and returns a reference to an array of songs for the given artist (based on url)
sub getsongs {
	my $self = shift;
	if (@_) {
		push(@urls, shift);
		$self->{TYPE} = "SONG"; # this is so we remember the original request type
		$TYPE = "ALBUM"; # This is so _getlinks() will first process all links to determine all the albums before processing songs :)
		#print "Processing Albums";
		$self = _getlinks($self);
		print " \nProcessing songs";
		$TYPE = "SONG";
		@urls = [];
		@urls = @songurls;
		$self = _getlinks($self) foreach @urls;
		print " Done\n";
		if ($self->{SONGS}) {
			my %sseen = (); # NOTE: This was taken from the Perl Cookbook Chapter 4 on Arrays
			my @suniqu = grep { ! $sseen{$_} ++ } @{$self->{SONGS}};
			return \@suniqu;
		} else {
			return undef;
		}
		#$self->{SONGS} ? return sort(@{$self->{SONGS}}) : return undef;
	}
	# if no values passed, return undef
	return undef;
}

# Takes  a url and returns a reference to an array of album names for the given artist (based on url)
sub getalbums {
	my $self = shift;
	if (@_) {
		push(@urls, shift);
		$self->{TYPE} = "ALBUM"; # this is so we remember the original request type
		$TYPE = "ALBUM";
		print "Processing Albums";
		$self = _getlinks($self);
		print " Done\n";
		if ($self->{ALBUMS}) {
			my %aseen = (); # NOTE: This was taken from the Perl Cookbook Chapter 4 on Arrays
			my @auniqu = grep { ! $aseen{$_} ++ } @{$self->{ALBUMS}};
			return \@auniqu;
		} else {
			return undef;
		}
		#$self->{ALBUMS} ? return sort(@{$self->{ALBUMS}}) : return undef;
	}
	# if no values passed, return undef
	return undef;
}

# PRIVATE FUNCTIONS:

sub DESTROY {
	my $self = shift;
	$self = {};
	@urls = [];
	@songurls = [];
	return 1;
}

sub _getlinks {
	print ".";
	my $self = shift;
	my ($data, $line);

	if ($urls[$#urls] =~ /(www|htm)/ || $urls[$#urls] =~ /^\/.*/) {
		&convert($self);
		$data = getmessage($self);
	} else {
		$data = GetURL($self);
	}
	foreach $line (@$data) {

		# Match <LI> tags and record data (be-it artist, album or song)
		my ($myurl, $myartist, $mydata);

		if ($TYPE eq "SONG") {
			if ($line =~ m!(\s+)?<LI[^N].*<A HREF=\"[^\"]+\">([^<]+)</A>.*!) {
				#print "Adding SONG: $2\n";
				push(@{$self->{SONGS}}, $2);
			}
		}

		if ($line =~ m!^\s*?<LI[^N].+<A HREF=\"([^\"]+)\"\s+?>([^/]+)\s/\s([^<]+)</A>.*$!) { # $1 is the URL $2 is the ARTIST $3 is the item (either album or song)
			($myurl, $myartist, $mydata) = ($1, $2, $3);

			if ($TYPE eq "ARTIST") {
				print "Setting ARTIST to: $myartist\n";
				$self->{ARTIST} = $myartist;
				return $self;
			}

			if ($TYPE eq "ALBUM") {
				#print "Adding ALBUM: $mydata\n";
				push(@{$self->{ALBUMS}}, $mydata);
				if ($self->{TYPE} eq "SONG") {
					push(@songurls, $myurl);
				}
			}

		}

		if ($TYPE ne "SONG") {
			if ($line =~ m!.*\[<A HREF=\"([^\"]+)\">[^<]+NEXT[^<]+</A>\].*!) {
				push(@urls, $1);
				$TYPE = "ALBUM";
				$self = _getlinks($self);
				$TYPE = $self->{TYPE};
			}
		}
	}
	return $self;
}

# Takes a CDDBScan object and returns an array of lines based on the objects {URL} member
sub GetURL {
	my $self = shift;
	$urls[$#urls] =~ s!\s!+!g;
	$urls[$#urls] = 'http://www.cddb.com/xm/search?q=' . $urls[$#urls] . '&f=artist';
	#print "GetURL: $urls[$#urls]...";
	my @data;
	if (@data = split('\n', get(pop(@urls)))) {
		#print "Done\n";
		return(\@data);
	} else {
		print "ERROR: Unable to download $urls[$#urls]\n";
	}
	return undef;
}

# Takes a CDDBScan object and returns an array of lines based on the onjects (URL) member
sub getmessage {
	my $self = shift;
	$urls[$#urls] =~ s/^\/(.*)/$1/;
	$urls[$#urls] = 'http://www.cddb.com/' . $urls[$#urls];
	#print "getmessages: $urls[$#urls]...";
	my @data;
	if (@data = split('\n', get(pop(@urls)))) {
		#print "Done\n";
		return(\@data);
	} else {
		print "ERROR: Unable to download $urls[$#urls]\n";
	}
	return undef;
}

# Takes a url and converts it to something logical for the cddb servers to take - returns the new version of the url
sub convert {
	my $self = shift;
	$urls[$#urls] =~ s!(.*cddb.com/|.*php)(.*)!$2!;
	$urls[$#urls] =~ s!^/?(.*)!$1!;
	return $self;
}

1;

=head1 NAME

Net::CDDBScan - Http Interface to CDDB database

=head1 SYNOPSIS

use Net::CDDBScan;

# Create a new cddb object
	$cddb = Net::CDDBScan->new();

# get an array ref to a list of albums for a given artist
	$albums = $cddb->getalbums("skinny puppy");

# get an array ref to a list of songs for for all albums of a given artist
	$songs = $cddb->getsongs("http://www.cddb.com/xm/search?f=artist&q=portishead");

=head1 DESCRIPTION

Net::CDDBScan is an interface to the www.cddb.com website; or more specifically
to their online search engine for the cddb database.  Originally created as a
small part of a greater application.  This module allows you to take any existing
string like "tricky" or "for whom the bell tolls" and get the artist name, all
albums from said artist and all songs on ANY album said artist has ever worked
on.  This is assuming the cddb database has a record of the given artist/album/song.

=head1 USING Net::CDDBScan

Net::CDDBScan is an object oriented module.

=over 4

=item B<1. Creating a Net::CDDBScan object>

You first must create a Net::CDDBScan object.

	my $cddb = Net::CDDBScan->new();

No existing options are available for the constructor.  Plans are to add
debug, continue, and other "not yet named" configuration options to the constructor.

=item B<2. Determining an Artist name based on an album or song name.>

"Mezzanine" is the name of a Massive Attach album
	$artist = $cddb->getartist("mezzanine");

or

"Less Than Strangers" is the name of a song on a Tracy Chapman album
	$artist = $cddb->getartist("telling stories");

=item B<3. Getting a list of all albums for a given artist.>

	$albums = $cddb->getalbums("medusa");
	print "$_\n" foreach @$albums;

B<getalbums()> returns a reference to an array of album names. This function
also takes any cddb.com url or partial url in the following formats:

B<http://www.cddb.com/xm/search?f=artist&q=medusa>

B<www.cddb.com/xm/search?f=artist&q=medusa>

B<medusa>

The reason for taking all these types of urls/strings is based on the internal usage
of this function.  These formats are not planned to change.  Though some of the internal
usage may change feel free be expect all these formats the continue to be accepted.

=item B<4. Getting a list of all songs for all albums of a given artist.>

	$songs = $cddb->getsongs("cocteau twins");
	print "$_\n" foreach $@songs;

This function also accepts all the url/string formats that B<getalbums()> takes.

=back

=head1 NOTICE

Be aware this module is in B<ALPHA> stage.  Big changes are expected which will allow much
cleaner usage, much more functionality and caching of data to a local cddb database (optional).
If you have any comments, suggestions and/or patches you'd like to submit.  Please email me at
dshultz@redchip.com

=head1 AUTHOR INFORMATION

Copyright 1998-2000, David J. Shultz All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
Address bug reports and comments to: dshultz@redchip.com

=head1 BUGS

This section intentionally left blank.

=head1 SEE ALSO

This section intentionally left blank.

=cut






