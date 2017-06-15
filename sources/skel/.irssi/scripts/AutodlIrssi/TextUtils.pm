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
# String utility functions
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::TextUtils;
use POSIX qw/ floor /;
use Encode;
use base qw/ Exporter /;
our @EXPORT = qw/ convertStringToBoolean convertStringToInteger trim removeInvisibleChars
				convertByteSizeString convertToByteSizeString convertTimeSinceString
				convertToTimeSinceString stripMircColorCodes canonicalizeReleaseName
				regexEscapeWildcardString removeExtraSpaces convertToValidPathName decodeOctets
				canonicalizeNetworkName canonicalizeServerName canonicalizeChannelName dataToHex /;
our @EXPORT_OK = qw//;


# Converts the string to 1 (true) or 0 (false)
sub convertStringToBoolean {
	my $s = lc shift;
	return 0 + !($s eq 'false' || $s eq 'off' || $s eq 'no' || $s eq '0' || $s eq '');
}

sub isNumber {
	my $s = shift;
	return 0 unless defined $s;
	return scalar $s =~ /^\s*-?\d+(?:\.\d+)?\s*$/;
}

# Converts $valueStr to an integer. $defaultValue is used if $valueStr isn't a number.
# $minValue and $maxValue are optional.
sub convertStringToInteger {
	my ($valueStr, $defaultValue, $minValue, $maxValue) = @_;

	my $value;
	if (!isNumber($valueStr)) {
		$value = $defaultValue;
	}
	else {
		$value = 0+$valueStr;
	}

	return if !defined $value;
	$value = $minValue if defined $minValue && $value < $minValue;
	$value = $maxValue if defined $maxValue && $value > $maxValue;

	return 0+floor($value);	# Make sure it's a number
}

sub trim {
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	return $s;
}

# Removes invisible chars and replaces them with spaces
sub removeInvisibleChars {
	my $s = shift;

	my $rv = "";

	my ($bg, $fg) = (-1, -2);
	for (my $i = 0; $i < length $s; $i++) {
		my $c = substr $s, $i, 1;

		if ($c eq "\x03") {
			my @ary = substr($s, $i) =~ /^(\x03(?:(\d{1,2})(?:,(\d{1,2}))?)?)/;
			my $fg2 = convertStringToInteger($ary[1]);
			my $bg2 = convertStringToInteger($ary[2]);
			$bg = $bg2 if defined $bg2;
			$fg = $fg2 if defined $fg2;
			$c = $ary[0];
			$i += length($c) - 1;
		}
		elsif (ord $c > 0x1F && $bg == $fg) {
			$c = " ";
		}

		$rv .= $c;
	}

	return $rv;
}

# Strips off any mIRC color codes from the string
sub stripMircColorCodes {
	my $s = shift;
	$s =~ s/\x03\d\d?,\d\d?//g;
	$s =~ s/\x03\d\d?//g;
	$s =~ s/[\x01-\x1F]//g;
	return $s;
}

my %mult = (
	"B"		=> 1,
	"KB"	=> 1024,
	"KIB"	=> 1024,
	"MB"	=> 1024*1024,
	"MIB"	=> 1024*1024,
	"GB"	=> 1024*1024*1024,
	"GIB"	=> 1024*1024*1024,
);

# Converts a size string to a number which is size in bytes, eg. string = "123 MB", "5.5GB", etc.
# Returns undef or the size in bytes
sub convertByteSizeString {
	my $s = shift;

	return unless defined $s;
	my @ary = $s =~ /^\s*([\d\.,]+)\s*(\w+)?\s*$/;
	return unless @ary;

	(my $amountStr = $ary[0]) =~ s/,//g;
	my $sizePrefix = uc (!defined $ary[1] ? "B" : $ary[1]);
	my $mult = $mult{$sizePrefix};
	return unless defined $mult;

	return unless isNumber($amountStr);
	return floor($amountStr * $mult);
}

sub convertToByteSizeString {
	my $size = shift;

	return unless defined $size;

	my $sizePrefix;
	if ($size >= 1024*1024*1000) {
		$size /= 1024*1024*1024;
		$sizePrefix = "GB";
	}
	elsif ($size >= 1024*1000) {
		$size /= 1024*1024;
		$sizePrefix = "MB";
	}
	elsif ($size >= 1000) {
		$size /= 1024;
		$sizePrefix = "KB";
	}
	else {
		$sizePrefix = "Bytes";
	}

	my $dot = index $size, ".";
	if ($dot != -1) {
		$size = sprintf('%.2f', $size);
	}

	return $size . " " . $sizePrefix;
}

# Converts a string like "5 mins, 2 secs" to time in seconds or null
sub convertTimeSinceString {
	my $s = shift;

	return unless defined $s;
	my @ary = $s =~ /\d+\s*\w+/g;
	return unless @ary;

	my $rv = 0;
	for my $timeStr (@ary) {
		my @ary2 = $timeStr =~ /(\d+)\s*(\w+)/;
		return unless @ary2;
		my $numStr = $ary2[0];
		my $typeStr = lc $ary2[1];
		my $mult;
		if ($typeStr =~ /^sec/ || $typeStr eq "s") {
			$mult = 1;
		}
		elsif ($typeStr =~ /^min/ || $typeStr eq "m") {
			$mult = 60;
		}
		elsif ($typeStr =~ /^(?:hour|hr)/ || $typeStr eq "h") {
			$mult = 60*60;
		}
		elsif ($typeStr =~ /^day/ || $typeStr eq "d") {
			$mult = 60*60*24;
		}
		elsif ($typeStr =~ /^(?:week|wk)/ || $typeStr eq "w") {
			$mult = 60*60*24*7;
		}
		else {
			return;
		}

		$rv += $numStr * $mult;
	}

	return $rv;
}

sub convertToTimeSinceString {
	my $seconds = shift;

	return unless defined $seconds;

	my $weeks = floor($seconds / (60*60*24*7));
	my $days = floor($seconds / (60*60*24) % 7);
	my $hours = floor($seconds / (60*60) % 24);
	my $mins = floor($seconds / 60 % 60);
	my $secs = floor($seconds % 60);

	my @ary;
	if ($weeks > 0) {
		push @ary, "" . $weeks . " week" . ($weeks != 1 ? "s" : "");
	}
	if ($days > 0) {
		push @ary, "" . $days . " day" . ($days != 1 ? "s" : "");
	}
	if ($hours > 0) {
		push @ary, "" . $hours . " hour" . ($hours != 1 ? "s" : "");
	}
	if ($mins > 0) {
		push @ary, "" . $mins . " minute" . ($mins != 1 ? "s" : "");
	}
	if ($secs > 0 || @ary == 0) {
		push @ary, "" . $secs . " second" . ($secs != 1 ? "s" : "");
	}

	return join " ", @ary;
}

# Returns the canonicalized release name
sub canonicalizeReleaseName {
	shift =~ /^(.*?)(?:\.avi|\.mkv|\.mpg|\.mpeg|\.wmv|\.ts|\.mp4)?$/i;
	my $rv = $1;
	# Replace most non alpha numerics < 0x80 with spaces
	$rv =~ s/[\x00-\x1F\x2D\x2E\x5F\x7F]+/ /g;
#	$rv =~ s/[\x00-\x1F\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F]+/ /g;
	$rv =~ s/\s+/ /g;
	$rv = lc trim $rv;
	return $rv;
}

sub regexEscapeWildcardString {
	my $s = shift;
	$s =~ s/([\^\$\.\+\=\!\:\|\\\/\(\)\[\]\{\}])/\\$1/g;
	$s =~ s/([*])/.$1/g;
	$s =~ s/([?])/.{1}/g;
	return $s;
}

sub removeExtraSpaces {
	my $s = shift;
	$s =~ s/\s+/ /g;
	return $s;
}

# Convert the path name (no path separators) to a valid file/dir name
sub convertToValidPathName {
	my $s = shift;
	$s =~ s![\x00-\x1F/\\:*?"<>|]!_!g;
	return $s;
}

# Tries to detect the encoding and decodes it
sub decodeOctets {
	my $octets = shift;

	my $flags = Encode::FB_CROAK | Encode::LEAVE_SRC;
	my $string = eval { decode("utf-8", $octets, $flags) };
	if ($@) {
		$string = eval { decode("iso-8859-1", $octets, $flags) };
		if ($@) {
			$string = $octets;
		}
	}

	return $string;
}

# Returns a canonicalized network name
sub canonicalizeNetworkName {
	my $network = shift;
	return "" if !defined $network || $network eq "";
	return "NETWORK-\L$network";
}

# Returns a canonicalized server name
sub canonicalizeServerName {
	shift =~ /^([^:]*)/;
	return lc $1;
}

# Returns a canonicalized channel name
sub canonicalizeChannelName {
	return lc shift;
}

# Convert binary data string to a hex string
sub dataToHex {
	use bytes;
	return join "", map {
		sprintf("%02X", ord($_))
	} split //, shift;
}

1;
