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

package AutodlIrssi::InternetUtils;
use POSIX qw/ floor /;
use HTML::Entities qw/ decode_entities /;
use JSON qw/ decode_json encode_json /;
use Encode qw/ encode_utf8 /;
use base qw/ Exporter /;
our @EXPORT = qw/ isInternetAddress decodeHtmlEntities toUrlEncode appendUrlQuery base64Encode
				decodeJson encodeJson /;
our @EXPORT_OK = qw//;

# Returns true if it's an IP:port or hostname:port address, false otherwise
sub isInternetAddress {
	my $addr = shift;

	return scalar $addr =~ m!^[^:\s/\\]+:\d{1,5}$!;
}

sub decodeHtmlEntities {
	return decode_entities(shift);
}

# URL-encode a string
sub toUrlEncode {
	my $s = encode_utf8(shift);

	my $str = "";
	for (my $i = 0; $i < length $s; $i++) {
		my $c = ord substr $s, $i, 1;
		if ((0x30 <= $c && $c <= 0x39) || (0x41 <= $c && $c <= 0x5A) || (0x61 <= $c && $c <= 0x7A) ||
			$c == 0x2D || $c == 0x2E || $c == 0x5F || $c == 0x7E) {
			$str .= chr $c;
		}
		else {
			$str .= sprintf("%%%02X", $c);
		}
	}
	return $str;
}

sub appendUrlQuery {
	my ($url, $query) = @_;
	if (index($url, "?") == -1) {
		return "$url?$query";
	}
	return "$url&$query";
}

# Returns the base64 encoding of s
sub base64Encode {
	my $s = shift;

	my $rv = "";

	my @encoded = split //, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	my $extra = (3 - length($s) % 3) % 3;
	my $padding = "";
	$s .= "\0" x $extra;
	$padding .= "=" x $extra;

	for (my $i = 0; $i < length $s; $i += 3) {
		my $v = (ord(substr($s, $i, 1)) << 16) | (ord(substr($s, $i + 1, 1)) << 8) | ord(substr($s, $i + 2, 1));
		my $v0 = ($v >> 18) & 0x3F;
		my $v1 = ($v >> 12) & 0x3F;
		my $v2 = ($v >> 6) & 0x3F;
		my $v3 = $v & 0x3F;

		$rv .= $encoded[$v0] . $encoded[$v1] . $encoded[$v2] . $encoded[$v3];
	}

	return substr($rv, 0, length($rv) - length($padding)) . $padding;
}

sub decodeJson {
	my $s = shift;
	return decode_json $s;
}

sub encodeJson {
	my $obj = shift;
	return encode_json $obj;
}

1;
