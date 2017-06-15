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
# Parses good ol' config files
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::ConfigFileParser;
use AutodlIrssi::TextUtils;
use AutodlIrssi::Globals;

sub new {
	my $class = shift;
	bless {
		headers => {},
	}, $class;
}

# Parses a file and returns a hash of all headers. The key is the header type (lower case), and
# the value is an array of all headers of that type.
sub parse {
	my ($self, $pathname) = @_;

	$self->{pathname} = $pathname;

	open my $fh, "<:encoding(utf8)", $pathname or die "Could not open file '$pathname': $!\n";
	my $lineNumber = 1;
	my $header;
	while (<$fh>) {
		chomp;
		next if /^\s*#/;	# Ignore comments
		next if /^\s*$/;	# Skip empty lines
		my $line = $_;

		if (my ($headerType, $headerName) = $line =~ /^\s*\[\s*([\w\-]+)\s*(?:([^\]]+))?\s*]\s*$/) {
			$headerName = "" unless defined $headerName;
			$headerType = lc $headerType;
			$headerName = trim $headerName;

			$header = {
				file => $pathname,
				lineNumber => $lineNumber,
				name => $headerName,
				options => {},
			};
			push @{$self->{headers}{$headerType}}, $header;
			next;
		}
		elsif (my ($option, $value) = $line =~ /^\s*([\w\-]+)\s*=(.*)$/) {
			$option = lc $option;
			$value = trim $value;

			if (defined $header) {
				$header->{options}{$option} = {
					file => $pathname,
					lineNumber => $lineNumber,
					value => $value,
				};

				next;
			}
		}

		$self->error($lineNumber, "invalid line: $line");
	}
	continue {
		$lineNumber++;
	}

	return $self->{headers};
}

sub error {
	my ($self, $lineNumber, $msg) = @_;

	message 0, "$self->{pathname}: line $lineNumber: $msg";
}

1;
