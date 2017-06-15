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
# Receives lines from a data source and calls a data handler for each new line received.
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::LineBuffer;

# Create a new instance. $dataHandler->($data) will get called. If we're in binary mode, $data
# is the remaining data. The handler should return undef if it processed all data or the number
# of bytes it processed. If we're not in binary mode, then $data is the current line without the
# CRLF part. It's not expected to return anything.
sub new {
	my ($class, $dataHandler) = @_;
	bless {
		data => "",
		newLineMode => 1,
		dataHandler => $dataHandler,
	}, $class;
}

sub setBinaryMode {
	my ($self, $isBinaryMode) = @_;
	$self->{newLineMode} = !$isBinaryMode;
}

# Add more data
sub addData {
	my ($self, $data) = @_;

	$self->{data} .= $data;
	$self->_dataAvailLoop(0);
}

# Send the remaining data to the data handler. Call this method when there's no more data to add.
sub flushData {
	shift->_dataAvailLoop(1);
}

sub _dataAvailLoop {
	my ($self, $flush) = @_;

	while (length $self->{data}) {
		my $dataUsed = 0;
		if ($self->{newLineMode}) {
			my $newLineIndex = index $self->{data}, "\x0A";
			return if $newLineIndex == -1 && !$flush;

			my $eol;
			if ($newLineIndex == -1) {
				$eol = $dataUsed = $newLineIndex = length $self->{data};
			}
			else {
				$dataUsed = $newLineIndex + 1;
				$eol = $newLineIndex;
			}
			if ($eol > 0 && substr($self->{data}, $eol-1, 1) eq "\x0D") {
				$eol--;
			}

			my $line = substr $self->{data}, 0, $eol;
			# Initialize $self->{data here in case flushData() is called in $self->{dataHandler()
			$self->{data} = substr $self->{data}, $dataUsed;
			$self->{dataHandler}->($line);
		}
		else
		{
			$dataUsed = $self->dataHandler($self->{data});
			if (!defined $dataUsed || $dataUsed <= 0) {
				$self->{data} = "";
				return;
			}
			$self->{data} = substr $self->{data}, $dataUsed;
		}
	}
}

1;
