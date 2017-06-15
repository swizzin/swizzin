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
# Reads and writes the ~/.autodl/AutodlState.xml file
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::AutodlState;
use AutodlIrssi::XmlParser;
use AutodlIrssi::FileUtils;
use AutodlIrssi::FilterState;
use base qw/ AutodlIrssi::XmlParser /;

# Reads settings from the saved file
sub read {
	my ($self, $filename) = @_;

	my $autodlState = {
		trackersVersion => -1,
		trackerStates => {},
		filterStates => {},
	};

	return $autodlState unless -f $filename;
	my $doc = $self->openFile($filename);
	return $autodlState unless defined $doc;

	my $autodlElem = $self->getTheChildElement($doc, "autodl");

	my $trackersVersionElem = $self->getOptionalChildElement($autodlElem, "trackers-version");
	if ($trackersVersionElem) {
		$autodlState->{trackersVersion} = $self->readTextNodeInteger($trackersVersionElem, undef, -1);
	}

	my $trackersElem = $self->getTheChildElement($autodlElem, "trackers");
	my @trackerElems = $self->getChildElementsByTagName($trackersElem, "tracker");
	for my $trackerElem (@trackerElems) {
		my $trackerType = $self->readAttribute($trackerElem, "type");
		die "Invalid tracker type\n" unless defined $trackerType && $trackerType ne "";
		my $lastAnnounce = $self->readTextNodeInteger($trackerElem, "last-announce");

		$autodlState->{trackerStates}{$trackerType} = {
			lastAnnounce => $lastAnnounce,
		};
	}

	$autodlState->{filterStates} = $self->readFilters($autodlElem);

	return $autodlState;
}

sub readFilters {
	my ($self, $rootElem) = @_;

	my $states = {};

	my $filtersElem = $self->getOptionalChildElement($rootElem, "filters");
	return $states unless defined $filtersElem;

	my @filterElems = $self->getChildElementsByTagName($filtersElem, "filter");
	for my $filterElem (@filterElems) {
		my $filterName = $self->readAttribute($filterElem, "name", "");
		next if $filterName eq "";

		my $state = new AutodlIrssi::FilterState();

		my $hourElem = $self->getOptionalChildElement($filterElem, "hour-downloads");
		if ($hourElem) {
			$state->setHourInfo($self->readAttributeInteger($hourElem, "time"), $self->readAttributeInteger($hourElem, "downloads"));
		}

		my $dayElem = $self->getTheChildElement($filterElem, "day-downloads");
		$state->setDayInfo($self->readAttributeInteger($dayElem, "time"), $self->readAttributeInteger($dayElem, "downloads"));

		my $weekElem = $self->getTheChildElement($filterElem, "week-downloads");
		$state->setWeekInfo($self->readAttributeInteger($weekElem, "time"), $self->readAttributeInteger($weekElem, "downloads"));

		my $monthElem = $self->getTheChildElement($filterElem, "month-downloads");
		$state->setMonthInfo($self->readAttributeInteger($monthElem, "time"), $self->readAttributeInteger($monthElem, "downloads"));

		my $totalElem = $self->getOptionalChildElement($filterElem, "total-downloads");
		if ($totalElem) {
			$state->setTotalInfo($self->readAttributeInteger($totalElem, "time"), $self->readAttributeInteger($totalElem, "downloads"));
		}

		my $smartElem = $self->getOptionalChildElement($filterElem, "smart-episode");
		if ($smartElem) {
			$state->setSmartInfo(
				$self->readAttributeInteger($smartElem, "season"), $self->readAttributeInteger($smartElem, "episode"),
				$self->readAttributeInteger($smartElem, "year"), $self->readAttributeInteger($smartElem, "month"),
				$self->readAttributeInteger($smartElem, "day")
			);
		}

		$states->{$filterName} = $state;
	}

	return $states;
}

sub write {
	my ($self, $filename, $autodlState) = @_;

	my $doc = $self->createDocument();
	my $autodlElem = $doc->createElement("autodl");
	$doc->setDocumentElement($autodlElem);

	my $trackersVersionElem = $doc->createElement("trackers-version");
	$autodlElem->appendChild($trackersVersionElem);
	$trackersVersionElem->appendChild($doc->createTextNode($autodlState->{trackersVersion}));

	my $trackersElem = $doc->createElement("trackers");
	$autodlElem->appendChild($trackersElem);

	while (my ($trackerType, $info) = each %{$autodlState->{trackerStates}}) {
		my $trackerElem = $doc->createElement("tracker");
		$trackersElem->appendChild($trackerElem);

		$trackerElem->setAttribute("type", $trackerType);

		my $lastAnnounce = defined $info->{lastAnnounce} ? $info->{lastAnnounce} : "";
		my $lastAnnounceElem = $doc->createElement("last-announce");
		$lastAnnounceElem->appendChild($doc->createTextNode($lastAnnounce));

		$trackerElem->appendChild($lastAnnounceElem);
	}

	$autodlElem->appendChild($self->writeFilters($doc, $autodlState->{filterStates}));

	saveRawDataToFile($filename, $doc->toString(1));
}

sub writeFilters {
	my ($self, $doc, $filterStates) = @_;

	my $filtersElem = $doc->createElement("filters");

	while (my ($name, $state) = each %$filterStates) {
		next if $name eq "";

		my $filterElem = $doc->createElement("filter");
		$filtersElem->appendChild($filterElem);
		$filterElem->setAttribute("name", $name);

		my $hourElem = $doc->createElement("hour-downloads");
		$filterElem->appendChild($hourElem);
		$hourElem->setAttribute("time", $state->getHourTime());
		$hourElem->setAttribute("downloads", $state->getHourDownloads());

		my $dayElem = $doc->createElement("day-downloads");
		$filterElem->appendChild($dayElem);
		$dayElem->setAttribute("time", $state->getDayTime());
		$dayElem->setAttribute("downloads", $state->getDayDownloads());

		my $weekElem = $doc->createElement("week-downloads");
		$filterElem->appendChild($weekElem);
		$weekElem->setAttribute("time", $state->getWeekTime());
		$weekElem->setAttribute("downloads", $state->getWeekDownloads());

		my $monthElem = $doc->createElement("month-downloads");
		$filterElem->appendChild($monthElem);
		$monthElem->setAttribute("time", $state->getMonthTime());
		$monthElem->setAttribute("downloads", $state->getMonthDownloads());

		my $totalElem = $doc->createElement("total-downloads");
		$filterElem->appendChild($totalElem);
		$totalElem->setAttribute("time", $state->getTotalTime());
		$totalElem->setAttribute("downloads", $state->getTotalDownloads());

		my $smartElem = $doc->createElement("smart-episode");
		$filterElem->appendChild($smartElem);
		$smartElem->setAttribute("season", $state->getSmartSeason());
		$smartElem->setAttribute("episode", $state->getSmartEpisode());
		$smartElem->setAttribute("year", $state->getSmartYear());
		$smartElem->setAttribute("month", $state->getSmartMonth());
		$smartElem->setAttribute("day", $state->getSmartDay());
	}

	return $filtersElem;
}

1;
