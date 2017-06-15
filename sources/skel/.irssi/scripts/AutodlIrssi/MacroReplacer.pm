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
# Replaces macros in strings with their values
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::MacroReplacer;
use AutodlIrssi::TextUtils;
use POSIX qw/ floor /;

sub new {
	my $class = shift;
	bless {
		macros => {},
	}, $class;
}

sub add {
	my ($self, $name, $value) = @_;
	$self->{macros}{$name} = $value;
}

sub addTimes {
	my ($self, $time) = @_;
	$time = time() unless defined $time;

	my @ary = localtime $time;
	my $millis = floor(($time - floor($time)) * 1000);

	$self->add("year", sprintf("%04d", $ary[5] + 1900));
	$self->add("month", sprintf("%02d", $ary[4] + 1));
	$self->add("day", sprintf("%02d", $ary[3]));
	$self->add("hour", sprintf("%02d", $ary[2]));
	$self->add("minute", sprintf("%02d", $ary[1]));
	$self->add("second", sprintf("%02d", $ary[0]));
	$self->add("milli", sprintf("%03d", $millis));
}

sub addTorrentInfo {
	my ($self, $ti) = @_;

	$self->add("Category", $ti->{category});
	$self->add("TorrentName", $ti->{torrentName});
	$self->add("Uploader", $ti->{uploader});
	$self->add("TorrentSize", convertToByteSizeString(convertByteSizeString($ti->{torrentSize})) || "");
	$self->add("PreTime", convertToTimeSinceString(convertTimeSinceString($ti->{preTime})) || "");
	$self->add("TorrentUrl", $ti->{torrentUrl});
	$self->add("TorrentSslUrl", $ti->{torrentSslUrl});

	my $fmtNum = sub {
		my ($fmt, $arg) = @_;
		return "" if $arg eq "";
		return sprintf($fmt, $arg);
	};

	$self->add("TYear", $ti->{year});
	$self->add("Artist", $ti->{name1});
	$self->add("Show", $ti->{name1});
	$self->add("Movie", $ti->{name1});
	$self->add("Name1", $ti->{name1});
	$self->add("Album", $ti->{name2});
	$self->add("Name2", $ti->{name2});
	$self->add("Season", $ti->{season});
	$self->add("Season2", $fmtNum->("%02d", $ti->{season}));
	$self->add("Episode", $ti->{episode});
	$self->add("Episode2", $fmtNum->("%02d", $ti->{episode}));
	$self->add("Resolution", $ti->{resolution});
	$self->add("ReleaseType", $ti->{releaseType});
	$self->add("Source", $ti->{source});
	$self->add("Encoder", $ti->{encoder});
	$self->add("Container", $ti->{container});
	$self->add("Format", $ti->{format});
	$self->add("Bitrate", $ti->{bitrate});
	$self->add("Media", $ti->{media});
	$self->add("Tags", $ti->{tags});
	$self->add("Scene", $ti->{scene});
	$self->add("Freeleech", $ti->{freeleech});
	$self->add("FreeleechPercent", $ti->{freeleechPercent});
	$self->add("Origin", $ti->{origin});
	$self->add("ReleaseGroup", $ti->{releaseGroup});
	$self->add("Log", $ti->{log});
	$self->add("LogScore", $ti->{logScore});
	$self->add("Cue", $ti->{cue});

	$self->add("Site", $ti->{site});

	$self->add("FilterName", $ti->{filter}{name}) if defined $ti->{filter};

	# ti.tracker isn't saved when serializing 'ti'
	if ($ti->{announceParser}) {
		my $trackerInfo = $ti->{announceParser}->getTrackerInfo();
		$self->add("Tracker", $trackerInfo->{longName});
		$self->add("TrackerShort", $trackerInfo->{shortName});
	}
}

sub replace {
	my ($self, $s) = @_;

	while (my ($name, $value) = each %{$self->{macros}}) {
		$s =~ s/\$\($name\)/$value/ig;
	}
	return $s;
}

1;
