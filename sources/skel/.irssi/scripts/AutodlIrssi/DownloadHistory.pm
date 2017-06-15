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
# Reads and writes ~/.autodl/DownloadHistory.txt
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::DownloadHistory;
use AutodlIrssi::Globals;
use AutodlIrssi::TextUtils;

sub new {
	my ($class, $filename) = @_;
	bless {
		filename => $filename,
		downloaded => {},
	}, $class;
}

sub cleanUp {
	my $self = shift;
}

sub getNumFiles {
	return scalar keys %{shift->{downloaded}};
}

sub loadHistoryFile {
	my $self = shift;

	return unless $AutodlIrssi::g->{options}{saveDownloadHistory};

	return unless open my $fh, "<:encoding(utf8)", $self->{filename};
	my @lines = <$fh>;
	close $fh;

	my $start = @lines - $AutodlIrssi::g->{options}{maxSavedReleases};
	@lines = splice @lines, $start if $start > 0;

	if (!open $fh, ">:utf8", $self->{filename}) {
		message 0, "Could not open '$self->{filename}' for writing: $!";
	}

	my %history;
	for my $line (@lines) {
		chomp $line;
		if (substr($line, -1) eq "\x0D") {
			chop $line;
		}
		my @ary = split /\t/, $line;
		next unless @ary == 5;

		my $release = {
			releaseName			=> $ary[0],
			time				=> sprintf("%d", $ary[1] / 1000),	# Convert to seconds
			torrentUrl			=> $ary[2],
			size				=> $ary[3] eq '' ? undef : $ary[3],
			canonicalizedName	=> $ary[4],
		};
		$history{$release->{canonicalizedName}} = $release;
		$self->writeReleaseToFile($fh, $release);
	}
	close $fh;
	$self->{downloaded} = \%history;
}

sub hasDownloaded {
	my ($self, $ti) = @_;
	return !!$self->{downloaded}{$ti->{canonicalizedName}};
}

# Returns true if we can download the release
sub canDownload {
	my ($self, $ti) = @_;
	return !$self->hasDownloaded($ti) || $ti->{filter}{downloadDupeReleases} || $AutodlIrssi::g->{options}{downloadDupeReleases};
}

sub addDownload {
	my ($self, $ti, $torrentUrl) = @_;

	my $release = {
		releaseName			=> $ti->{torrentName},
		time				=> currentTime(),
		torrentUrl			=> $torrentUrl,
		size				=> $ti->{torrentSizeInBytes},
		canonicalizedName	=> $ti->{canonicalizedName},
	};
	$self->{downloaded}{$ti->{canonicalizedName}} = $release;
	$self->saveReleaseToHistoryFile($release);
}

sub saveReleaseToHistoryFile {
	my ($self, $release) = @_;

	return unless $AutodlIrssi::g->{options}{saveDownloadHistory};

	my $fh;
	if (!open $fh, ">>:utf8", $self->{filename}) {
		message 0, "Could not open '$self->{filename}' for writing: $!";
		return;
	}
	$self->writeReleaseToFile($fh, $release);
	close $fh;
}

# Writes the release to the file
sub writeReleaseToFile {
	my ($self, $fh, $release) = @_;

	return unless $AutodlIrssi::g->{options}{saveDownloadHistory};

	my $msg = $release->{releaseName};
	$msg =~ s/\t/ /g;
	$msg .= "\t" . $release->{time}*1000;	# Save in ms
	$msg .= "\t" . $release->{torrentUrl};
	$msg .= "\t" . (defined $release->{size} ? $release->{size} : "");
	$msg .= "\t" . $release->{canonicalizedName};
	print $fh "$msg\n";
}

1;
