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
# Parses multi-line IRC announces
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::MultiLineParser;
use AutodlIrssi::Globals;
use constant MAX_AGE_IN_SECS => 15;

sub new {
	my ($class, $trackerName) = @_;
	bless {
		trackerName	=> $trackerName,
		announces	=> [],
		regexLines	=> [],
		optional	=> [],
	}, $class;
}

# Add a new regex for the next line. $optional is true if it's an optional line. $regex is the
# compiled regex.
sub addLineRegex {
	my ($self, $regex, $optional) = @_;
	push @{$self->{regexLines}}, $regex;
	push @{$self->{optional}}, $optional;
}

# Returns the index of the regex for which $line matches or undef if it didn't match any regex.
sub getLineNumber {
	my ($self, $line) = @_;

	my $len = @{$self->{regexLines}};
	for (my $i = 0; $i < $len; $i++) {
		return $i if $line =~ $self->{regexLines}[$i];
	}

	return;
}

sub getAnnounceIndex {
	my ($self, $lineNo) = @_;

	if ($lineNo eq 0) {
		my $index = @{$self->{announces}};
		push @{$self->{announces}}, {
			time	=> currentTime(),
			lines	=> [],
		};
		return $index;
	}

	my $len = @{$self->{announces}};
	for (my $i = 0; $i < $len; $i++) {
		my $announce = $self->{announces}[$i];
		for (my $j = @{$announce->{lines}}; $j < @{$self->{optional}}; $j++) {
			return $i if $j == $lineNo;
			last unless $self->{optional}[$j];
		}
	}

	return;
}

sub removeOld {
	my $self = shift;

	my $time = currentTime();

	my @removeIndexes;
	my $len = @{$self->{announces}};
	for (my $i = 0; $i < $len; $i++) {
		my $announce = $self->{announces}[$i];
		my $age = $time - $announce->{time};
		next if $age <= MAX_AGE_IN_SECS;

		push @removeIndexes, $i;
	}
	my $j = 0;
	for my $i (@removeIndexes) {
		splice @{$self->{announces}}, $i - $j, 1;
		$j++;
	}
}

# Add an announce line. Returns 0 if it didn't match, 1 if it matched, and a HASH ref if all
# lines have matched.
sub addLine {
	my ($self, $line) = @_;

	$self->removeOld();

	my $lineNumber = $self->getLineNumber($line);
	return 0 unless defined $lineNumber;
	my $index = $self->getAnnounceIndex($lineNumber);
	return 0 unless defined $index;

	for (my $i = @{$self->{announces}[$index]{lines}}; $i < $lineNumber; $i++) {
		push @{$self->{announces}[$index]{lines}}, undef;
	}
	push @{$self->{announces}[$index]{lines}}, $line;

	return 1 if $#{$self->{regexLines}} != $lineNumber;

	return shift @{$self->{announces}};
}

1;
