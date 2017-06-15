# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is IRC Auto Downloader
#
# The Initial Developer of the Original Code is
# David Nilsson.
# Portions created by the Initial Developer are Copyright (C) 2010, 2011
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#
# ***** END LICENSE BLOCK *****

#
# Parses a bencoded string, see http://wiki.theory.org/BitTorrentSpecification
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Benc;
use constant {
	DICTIONARY => 0,
	LIST => 1,
	STRING => 2,
	INTEGER => 3,
};

sub new {
	bless {}, shift;
}

sub isDictionary {
	return shift->{type} == DICTIONARY;
}

sub isList {
	return shift->{type} == LIST;
}

sub isString {
	return shift->{type} == STRING;
}

sub isInteger {
	return shift->{type} == INTEGER;
}

sub readDictionary {
	my ($self, $name) = @_;
	return unless $self->isDictionary();
	return $self->{dict}{$name};
}

package AutodlIrssi::Bencoding;
use base qw/ Exporter /;
our @EXPORT = qw/ parseBencodedString /;
our @EXPORT_OK = qw//;

# Parses a bencoded string and returns a Benc object. undef is returned if an error occurs.
sub parseBencodedString {
	my $s = shift;

	my $rv = eval {
		my $benc = _parseBencodedStringInternal($s, 0, 0);
		if (!$benc->isDictionary()) {
			die "Root of bencoded data must be a dictionary\n";
		}
		return $benc;
	};
	if ($@) {
		return;
	}
	return $rv;
}

sub _parseBencodedStringInternal {
	my ($s, $index, $level) = @_;

	my $nextChar = sub {
		die "Bencoded string is missing data\n" if $index >= length $s;
		return substr $s, $index++, 1;
	};
	my $peekChar = sub {
		my $c = $nextChar->();
		$index--;
		return $c;
	};
	my $isInteger = sub {
		my $c = shift;
		return '0' le $c && $c le '9';
	};

	die "Too many recursive calls\n" if $level++ >= 100;

	my $benc = new AutodlIrssi::Benc();
	$benc->{start} = $index;

	my $c = $peekChar->();
	if ($c eq "d") {
		$nextChar->();

		$benc->{type} = AutodlIrssi::Benc::DICTIONARY();
		$benc->{dict} = {};

		while ($peekChar->() ne "e") {
			my $key = _parseBencodedStringInternal($s, $index, $level);
			$index = $key->{end};
			my $value = _parseBencodedStringInternal($s, $index, $level);
			$index = $value->{end};

			die "Invalid dictionary element; key part must be a string\n" unless $key->isString();

			$benc->{dict}{$key->{string}} = $value;
		}
		$nextChar->();
	}
	elsif ($c eq "l") {
		$nextChar->();

		$benc->{type} = AutodlIrssi::Benc::LIST();
		$benc->{list} = [];

		while ($peekChar->() ne "e") {
			my $elem = _parseBencodedStringInternal($s, $index, $level);
			$index = $elem->{end};
			push @{$benc->{list}}, $elem;
		}
		$nextChar->();
	}
	elsif ($isInteger->($c)) {
		$benc->{type} = AutodlIrssi::Benc::STRING();

		my $colon = index $s, ":", $index;
		die "Missing colon" if $colon == -1;
		my $len = substr $s, $index, $colon - $index;
		$index = $colon + 1;
		my $ilen = 0+$len;
		if ($ilen < 0 || $ilen ne $len || $index + $ilen > length $s) {
			die "Byte string with invalid length\n";
		}
		$benc->{string} = substr $s, $index, $ilen;
		$index += $ilen;
	}
	elsif ($c eq "i") {
		$nextChar->();

		$benc->{type} = AutodlIrssi::Benc::INTEGER();

		my $eindex = index $s, "e", $index;
		die "Missing terminating 'e'\n" if $eindex == -1;
		$benc->{integer} = substr $s, $index, $eindex - $index;
		$index = $eindex + 1;
	}
	else {
		die "Invalid character found at index $index\n";
	}

	$benc->{end} = $index;
	return $benc;
}

1;
