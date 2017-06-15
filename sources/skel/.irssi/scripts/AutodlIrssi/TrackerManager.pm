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
# Keeps track of all announce parsers
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::TrackerManager;
use AutodlIrssi::Globals;
use AutodlIrssi::TrackerXmlParser;
use AutodlIrssi::AnnounceParser;
use AutodlIrssi::TextUtils;
use File::Spec;

sub new {
	my ($class, $trackerStates) = @_;

	bless {
		trackerStates => $trackerStates,
		announceParsers => {},
	}, $class;
}

sub cleanUp {
	my $self = shift;
}

# Returns the number of trackers we support.
sub getNumberOfTrackers {
	return scalar keys %{shift->{announceParsers}};
}

# Returns an array of absolute pathnames to all *.tracker files.
sub getTrackerFiles {
	my ($self, $baseDir) = @_;

	my @files;

	my $dh;
	opendir $dh, $baseDir or return @files;
	for my $file (readdir $dh) {
		my $pathname = File::Spec->catfile($baseDir, $file);
		next unless -f $pathname;
		next unless $file =~ /\.tracker$/;
		push @files, $pathname;
	}

	return @files;
}

# Parses all *.tracker files in $baseDir and returns an array of all trackerInfos
sub getTrackerInfos {
	my ($self, $baseDir) = @_;

	my @trackerInfos;
	for my $filename ($self->getTrackerFiles($baseDir)) {
		next if -z $filename;
		my $parser = new AutodlIrssi::TrackerXmlParser();

		my $trackerInfo = eval { $parser->parse($filename) };
		if ($@) {
			chomp $@;
			message 0, "Could not parse '$filename': Error: $@";
		}
		else {
			push @trackerInfos, $trackerInfo;
		}
	}
	return \@trackerInfos;
}

sub reloadTrackerFiles {
	my ($self, $trackerFilesDir) = @_;

	my $oldAnnounceParsers = $self->{announceParsers};
	$self->{announceParsers} = {};
	$self->{servers} = {};
	$self->{announceNicks} = {};

	my $currTime = time();
	for my $trackerInfo (@{$self->getTrackerInfos($trackerFilesDir)}) {
		my $type = $trackerInfo->{type};
		if (exists $self->{announceParsers}{$type}) {
			message 0, "Tracker with type '$type' has already been added.";
			next;
		}

		my $state = $self->{trackerStates}{$type};
		$self->{trackerStates}{$type} = $state = {} unless $state;
		$state->{lastAnnounce} ||= $currTime;

		my $announceParser = new AutodlIrssi::AnnounceParser($trackerInfo, $state);
		if (my $oldAnnounceParser = $oldAnnounceParsers->{$type}) {
			$announceParser->addOptionsFrom($oldAnnounceParser);
		}
		$self->{announceParsers}{$type} = $announceParser;
		$self->addAnnounceParserToServerTable($announceParser);
	}

	if (%$oldAnnounceParsers) {
		$self->printNewTrackers($oldAnnounceParsers);
	}
}

sub printNewTrackers {
	my ($self, $oldAnnounceParsers) = @_;

	while (my ($type, $announceParser) = each %{$self->{announceParsers}}) {
		next if exists $oldAnnounceParsers->{$type};
		message 3, "\x02Added tracker\x02 \x0309" . $announceParser->getTrackerName() . "\x03";
	}
	while (my ($type, $announceParser) = each %$oldAnnounceParsers) {
		next if exists $self->{announceParsers}{$type};
		dmessage 3, "\x02Removed tracker\x02 \x0304" . $announceParser->getTrackerName() . "\x03";
	}
}

sub reportBrokenAnnouncers {
	my ($self, $trackerTypes) = @_;

	my $currTime = time();
	for my $trackerType (@$trackerTypes) {
		my $announceParser = $self->{announceParsers}{$trackerType};
		my $trackerState = $self->{trackerStates}{$trackerType};
		next unless defined $announceParser && defined $trackerState;

		$trackerState->{lastCheck} = $currTime unless defined $trackerState->{lastCheck};
		next if $currTime - $trackerState->{lastCheck} <= 6*60*60;
		$trackerState->{lastCheck} = $currTime;

		my $maxTimeSecs = $AutodlIrssi::g->{options}{debug} ? 12*60*60 : 24*60*60;
		if ($currTime - $trackerState->{lastAnnounce} >= $maxTimeSecs) {
			my $trackerInfo = $announceParser->getTrackerInfo();
			message(3, "\x0304WARNING\x03: \x02$trackerInfo->{longName}\x02: Nothing announced since " . localtime($trackerState->{lastAnnounce}));
		}
	}
}

sub getTrackerStates {
	my $self = shift;

	# Don't save invalid tracker types
	return {
		map {
			exists $self->{announceParsers}{$_} ? ($_, $self->{trackerStates}{$_}) : ()
		} keys %{$self->{trackerStates}}
	};
}

# Splits a comma-separated string and returns a reference to an array of strings. Empty strings are
# not returned.
sub splitCommaSeparatedList {
	my $s = shift;
	my @ary = map {
		my $a = trim $_;
		$a ne "" ? $a : ()
	} split /,/, $s;
	return \@ary;
}

# Adds the announce parser's channels to the server table.
sub addAnnounceParserToServerTable {
	my ($self, $announceParser) = @_;

	my $trackerInfo = $announceParser->getTrackerInfo();
	for my $server (@{$trackerInfo->{servers}}) {
		# This is the canonicalized server name or network name
		my $canonName = $server->{name};
		for my $channelName (@{splitCommaSeparatedList($server->{channelNames})}) {
			my $announcerNames = splitCommaSeparatedList($server->{announcerNames});

			my $channel = {
				announceParser	=> $announceParser,
				name			=> $channelName,
				announcerNames	=> $announcerNames,
			};

			$self->_addAnnounceNicks($announcerNames);

			my $canonChannelName = canonicalizeChannelName($channelName);
			$self->{servers}{$canonName}{$canonChannelName} = $channel;
		}
	}
}

sub _addAnnounceNicks {
	my ($self, $announcerNames) = @_;

	for my $tmp (@$announcerNames) {
		my $announcerName = lc $tmp;
		$self->{announceNicks}{$announcerName} = 1;
	}
}

# Returns the server info struct if there is one or undef otherwise
sub _findServerInfo {
	my ($self, $networkName, $serverName) = @_;

	$serverName = canonicalizeServerName($serverName);
	if (exists $self->{servers}{$serverName}) {
		return $self->{servers}{$serverName};
	}

	$networkName = canonicalizeNetworkName($networkName);
	if (exists $self->{servers}{$networkName}) {
		return $self->{servers}{$networkName};
	}

	return;
}

# Returns the channel info struct if there is one or undef otherwise
sub _findChannelInfo {
	my ($self, $networkName, $serverName, $channelName) = @_;

	my $server = $self->_findServerInfo($networkName, $serverName);
	return unless defined $server;

	$channelName = canonicalizeChannelName($channelName);
	return $server->{$channelName};
}

# Returns the announce parser or undef if none found
#	$networkName	=> undef/empty or the (005) ISUPPORT NETWORK name
sub findAnnounceParser {
	my ($self, $networkName, $serverName, $channelName, $announcerName) = @_;

	$announcerName = lc $announcerName;
	return unless $self->{announceNicks}{$announcerName};

	my $channel = $self->_findChannelInfo($networkName, $serverName, $channelName);
	return unless defined $channel;

	for my $name (@{$channel->{announcerNames}}) {
		if (lc(trim $name) eq $announcerName) {
			return $channel->{announceParser};
		}
	}
	return;
}

# Returns the AnnounceParser or undef if it doesn't exist. $type is the unique tracker type.
sub findAnnounceParserFromType {
	my ($self, $type) = @_;
	return $self->{announceParsers}{$type};
}

sub getAnnounceParsers {
	return shift->{announceParsers};
}

# Returns a list of all monitored channels for this $serverName
sub getChannels {
	my ($self, $networkName, $serverName) = @_;

	my $server = $self->_findServerInfo($networkName, $serverName);
	return () unless defined $server;
	return map { $_->{name} } values %$server;
}

# Returns the announce parser or undef if none found
sub getAnnounceParserFromChannel {
	my ($self, $networkName, $serverName, $channelName) = @_;

	my $channel = $self->_findChannelInfo($networkName, $serverName, $channelName);
	return unless defined $channel;
	return $channel->{announceParser};
}

# Resets all tracker options
sub resetTrackerOptions {
	my $self = shift;

	while (my ($trackerType, $announceParser) = each %{$self->{announceParsers}}) {
		$announceParser->resetOptions();
	}
}

1;
