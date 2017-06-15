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
# Parse old announces from log files
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::TrackerLogChecker;
use AutodlIrssi::Globals;
use AutodlIrssi::FilterManager;
use AutodlIrssi::TextUtils;
use File::Spec;

sub getDirectoryEntries {
	my ($dir, $func) = @_;

	my $dh;
	return () unless opendir $dh, $dir;

	return map {
		my $path = File::Spec->catfile($dir, $_);
		$func->($path) ? $path : ();
	} readdir $dh;
}

sub getSortedDirectoryEntries {
	my ($dir, $func) = @_;

	return sort { lc $a cmp lc $b } getDirectoryEntries($dir, $func);
}

sub new {
	my ($class, $baseLogPath, $trackerManager) = @_;
	bless {
		baseLogPath => $baseLogPath,
		trackerManager => $trackerManager,
	}, $class;
}

sub addError {
	my $self = shift;
	$self->{numErrors}++;
	die "Too many errors found. Stopping.\n" if $self->{numErrors} >= 20;
}

sub verifyAllTrackers {
	my $self = shift;

	my $parsers = $self->{trackerManager}->getAnnounceParsers();
	for my $trackerType (keys %$parsers) {
		$self->verifyTracker($trackerType);
	}
}

sub verifyTracker {
	my ($self, $trackerType) = @_;

	$self->{numErrors} = 0;
	$self->{numAnnounceLines} = 0;

	my $announceParser = $self->{trackerManager}->findAnnounceParserFromType($trackerType);
	if (!$announceParser) {
		message(0, "Could not find tracker with type: $trackerType");
		return;
	}

	my $trackerInfo = $announceParser->getTrackerInfo();
	message(3, "Verifying tracker $trackerInfo->{longName} ($trackerInfo->{type})");

	eval {
		# Gets a little slow if this function is called so disable it
		no warnings;
		local *AutodlIrssi::AnnounceParser::extractReleaseNameInfo = sub {};
		use warnings;

		for my $serverInfo (@{$trackerInfo->{servers}}) {
			$self->verifyChannel($announceParser, $serverInfo);
		}
	};
	if ($@) {
		message(0, "Tracker: $trackerInfo->{longName}: Got an exception: " . formatException($@));
	}

	if ($self->{numErrors} > 0) {
		message(0, "\x0300,04 Done \x03; ERRORS: $self->{numErrors}; Checked $self->{numAnnounceLines} lines; tracker $trackerInfo->{longName} ($trackerInfo->{type})");
	}
	else {
		message(3, "\x0300,03 Done \x03; No errors; Checked $self->{numAnnounceLines} lines; tracker $trackerInfo->{longName} ($trackerInfo->{type})");
	}
}

sub verifyChannel {
	my ($self, $announceParser, $serverInfo) = @_;

	my $isChannelFileName = sub {
		my $filename = lc shift;
		for (split /,/, $serverInfo->{channelNames}) {
			my $name = lc trim $_;
			next unless $name;
			return 1 if index($filename, $name) == 0;
		}
		return 0;
	};

	my @entries = getSortedDirectoryEntries($self->{baseLogPath}, sub {
		my $entry = shift;
		my @dirs = File::Spec->splitdir($entry);
		my $name = $dirs[-1];
		return -d $entry && index(lc $name, lc $serverInfo->{name}) == 0;
	});
	for (@entries) {
		message(4, "Checking directory $_");

		my $dir = File::Spec->catdir($_, "channels");

		if (!-d $dir) {
			message(3, "No channels directory: $dir");
			next;
		}

		my @entries2 = getSortedDirectoryEntries($dir, sub {
			my $entry = shift;
			my @dirs = File::Spec->splitdir($entry);
			my $name = $dirs[-1];
			return -f $entry && $isChannelFileName->($name);
		});
		for my $file (@entries2) {
			message(4, "Checking file $file");
			$self->verifyFile($announceParser, $serverInfo, $file);
		}
	}
}

sub verifyFile {
	my ($self, $announceParser, $serverInfo, $file) = @_;

	open my $fh, "<:encoding(utf8)", $file or die "Could not open file '$file': $!\n";
	while (<$fh>) {
		chomp;
		chop if substr($_, -1) eq "\x0D";
		next unless /^\[([^\]]*)\] <([^>]*)> (.*)/;

		my $date = $1;
		my $user = $2;
		my $userLine = $3;

		next unless AutodlIrssi::FilterManager::checkFilterStrings($user, $serverInfo->{announcerNames});

		unless ($date =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) {
			die "Could not parse date: '$date'\n";
		}
		my $year = $1;
		my $month = $2;
		my $day = $3;
		my $hours = $4;
		my $minutes = $5;
		my $seconds = $6;

		$self->{numAnnounceLines}++;
		my $ti = $announceParser->onNewLine($userLine);
		if (!defined $ti) {
			$self->addError();
		}
	}
}

1;
