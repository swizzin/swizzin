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
# Remembers and deletes old temporary files
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::TempFiles;
use AutodlIrssi::Globals;
use constant MAX_AGE_IN_SECS => 30;

sub new {
	my $class = shift;
	bless {
		files => [],
	}, $class;
}

sub cleanUp {
	my $self = shift;
}

# Add a file to be deleted
sub add {
	my ($self, $pathname) = @_;

	push @{$self->{files}}, {
		time => time(),
		pathname => $pathname,
	};
}

# Delete all files
sub deleteAll {
	shift->deleteOld(0);
}

# Delete all files whose age >= $ageInSecs.
sub deleteOld {
	my ($self, $ageInSecs) = @_;

	$ageInSecs = MAX_AGE_IN_SECS unless defined $ageInSecs;

	my $currTime = time();
	while (@{$self->{files}}) {
		my $fileInfo = $self->{files}[0];
		last if ($currTime - $fileInfo->{time}) < $ageInSecs;
		shift @{$self->{files}};

		if (!unlink($fileInfo->{pathname}) && -f $fileInfo->{pathname}) {
			message 0, "Could not delete temporary file '$fileInfo->{pathname}'";
		}
		else {
			message 4, "Deleted temporary file '$fileInfo->{pathname}'";
		}
	}
}

1;
