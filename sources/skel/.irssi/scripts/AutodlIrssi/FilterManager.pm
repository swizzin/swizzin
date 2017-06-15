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
# Checks if an announced torrent matches a filter.
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::FilterManager;
use AutodlIrssi::TextUtils;
use AutodlIrssi::Constants;
use AutodlIrssi::FilterState;
use AutodlIrssi::Globals;

sub new {
	my ($class, $filterStates) = @_;
	bless {
		filters => [],
		filterStates => $filterStates,
	}, $class;
}

sub cleanUp {
	my $self = shift;
}

sub getFilterStates {
	return shift->{filterStates};
}

sub setFilters {
	my ($self, $filters) = @_;

	$self->{filters} = $filters;

	my $oldFilterStates = $self->{filterStates};
	$self->{filterStates} = {};

	for my $filter (@{$self->{filters}}) {
		my $name = $filter->{name};
		my $state = delete $oldFilterStates->{$name};
		$state = new AutodlIrssi::FilterState() unless defined $state;
		$filter->{state} = $state;
		$self->{filterStates}{$name} = $state;
	}
}

sub getNumFilters {
	return scalar @{shift->{filters}};
}

# Find a filter matching $ti. Returns the filter if it matched, else undef.
sub findFilter {
	my ($self, $ti) = @_;

	for my $filter (reverse sort {$a->{priority} <=> $b->{priority} or $b->{name} cmp $a->{name}} @{$self->{filters}}) {
		return $filter if $self->checkFilter($ti, $filter);
	}

	return;
}

# Returns true if $filter matches $ti
sub checkFilter {
	my ($self, $ti, $filter) = @_;

	return 0 if !$filter->{enabled};

	return 0 if $filter->{matchSites} ne '' && !checkSite($ti->{announceParser}, $filter->{matchSites});
	return 0 if $filter->{exceptSites} ne '' && checkSite($ti->{announceParser}, $filter->{exceptSites});

	return 0 if $filter->{resolutions} ne '' && !checkArySynonyms($ti->{resolution}, $filter->{resolutions}, $AutodlIrssi::Constants::tvResolutions);
	return 0 if $filter->{sources} ne '' && !checkArySynonyms($ti->{source}, $filter->{sources}, $AutodlIrssi::Constants::tvSources);
	return 0 if $filter->{encoders} ne '' && !checkArySynonyms($ti->{encoder}, $filter->{encoders}, $AutodlIrssi::Constants::tvEncoders);
	return 0 if $filter->{containers} ne '' && !checkFilterStrings($ti->{container}, $filter->{containers});

	return 0 if $filter->{years} ne '' && !checkFilterNumbers($ti->{year}, $filter->{years});
	return 0 if $filter->{seasons} ne '' && !checkFilterNumbers($ti->{season}, $filter->{seasons});
	return 0 if $filter->{episodes} ne '' && !checkFilterNumbers($ti->{episode}, $filter->{episodes});

	if ($filter->{useRegex} || $AutodlIrssi::g->{options}{useRegex}) {
		return 0 if $filter->{matchReleases} ne '' && !checkFilterRegex($ti->{torrentName}, $filter->{matchReleases});
		return 0 if $filter->{exceptReleases} ne '' && checkFilterRegex($ti->{torrentName}, $filter->{exceptReleases});
	}
	else {
		return 0 if $filter->{matchReleases} ne '' && !checkFilterStrings($ti->{torrentName}, $filter->{matchReleases});
		return 0 if $filter->{exceptReleases} ne '' && checkFilterStrings($ti->{torrentName}, $filter->{exceptReleases});
	}

	return 0 if $filter->{matchCategories} ne '' && !checkFilterStrings($ti->{category}, $filter->{matchCategories});
	return 0 if $filter->{exceptCategories} ne '' && checkFilterStrings($ti->{category}, $filter->{exceptCategories});

	return 0 if $filter->{matchReleaseTypes} ne '' && !checkFilterStrings($ti->{releaseType}, $filter->{matchReleaseTypes});
	return 0 if $filter->{exceptReleaseTypes} ne '' && checkFilterStrings($ti->{releaseType}, $filter->{exceptReleaseTypes});

	return 0 if $filter->{artists} ne '' && !checkName($ti->{name1}, $filter->{artists});
	return 0 if $filter->{albums} ne '' && !checkName($ti->{name2}, $filter->{albums});

	return 0 if $filter->{formats} ne '' && !checkFilterStrings($ti->{format}, $filter->{formats});
	return 0 if $filter->{bitrates} ne '' && !checkFilterBitrate($ti->{bitrate}, $filter->{bitrates});
	return 0 if $filter->{media} ne '' && !checkFilterStrings($ti->{media}, $filter->{media});

	return 0 if $filter->{tags} ne '' && !checkFilterTags($ti->{tags}, $filter->{tags}, $filter->{tagsAny});
	return 0 if $filter->{exceptTags} ne '' && checkFilterTags($ti->{tags}, $filter->{exceptTags}, $filter->{exceptTagsAny});
	return 0 if $filter->{scene} ne '' && !$ti->{scene} != !$filter->{scene};
	return 0 if $filter->{freeleech} ne '' && !$ti->{freeleech} != !$filter->{freeleech};
	return 0 if $filter->{freeleechPercents} ne '' && !checkFilterNumbers($ti->{freeleechPercent}, $filter->{freeleechPercents});
	return 0 if $filter->{origins} ne '' && !checkFilterStrings($ti->{origin}, $filter->{origins});
	return 0 if $filter->{releaseGroups} ne '' && !checkFilterStrings($ti->{releaseGroup}, $filter->{matchReleaseGroups});
	return 0 if $filter->{matchReleaseGroups} ne '' && !checkFilterReleaseGroups($ti, $filter->{matchReleaseGroups});
	return 0 if $filter->{exceptReleaseGroups} ne '' && checkFilterReleaseGroups($ti, $filter->{exceptReleaseGroups});
	return 0 if $filter->{log} ne '' && !$ti->{log} != !$filter->{log};
	return 0 if $filter->{logScores} ne '' && !checkFilterNumbers($ti->{logScore}, $filter->{logScores});
	return 0 if $filter->{cue} ne '' && !$ti->{cue} != !$filter->{cue};

	return 0 if $filter->{matchUploaders} ne '' && !checkFilterStrings($ti->{uploader}, $filter->{matchUploaders});
	return 0 if $filter->{exceptUploaders} ne '' && checkFilterStrings($ti->{uploader}, $filter->{exceptUploaders});

	my $torrentSize = convertByteSizeString($ti->{torrentSize});
	return 0 if !checkFilterSize($torrentSize, $filter);

	my $maxPreTime = convertTimeSinceString($filter->{maxPreTime});
	if (defined $maxPreTime) {
		my $preTime = convertTimeSinceString($ti->{preTime});
		return 0 if !defined $preTime || $preTime > $maxPreTime;
	}

	my $state = $filter->{state};
	$state->initializeTime();

	if ($filter->{maxDownloads} >= 0) {
		my $numDownloads;
		if ($filter->{maxDownloadsPer} eq "hour") {
			$numDownloads = $state->getHourDownloads();
		}
		elsif ($filter->{maxDownloadsPer} eq "day") {
			$numDownloads = $state->getDayDownloads();
		}
		elsif ($filter->{maxDownloadsPer} eq "week") {
			$numDownloads = $state->getWeekDownloads();
		}
		elsif ($filter->{maxDownloadsPer} eq "month") {
			$numDownloads = $state->getMonthDownloads();
		}
		elsif ($filter->{maxDownloadsPer} eq "" || $filter->{maxDownloadsPer} eq "forever") {
			$numDownloads = $state->getTotalDownloads();
		}
		return 0 if defined $numDownloads && $numDownloads >= $filter->{maxDownloads};
	}

	return 1;
}

sub checkFilterRegex {
	my ($name, $filterList) = @_;
	my @ary = split /,/, $filterList;
	return checkRegexArray($name, \@ary);
}

# Returns true if name matches one of the words in filterWordsAry
#	@param name	The string to check
#	@param filterWordsAry	Array containing all regex strings
sub checkRegexArray {
	my ($name, $filterWordsAry) = @_;

	for my $temp (@$filterWordsAry) {
		my $filterWord = trim $temp;
		next unless $filterWord;
		return 1 if $name =~ /$filterWord/i;
	}

	return 0;
}

sub checkFilterReleaseGroups {
	my ($ti, $releaseGroups) = @_;

	if ($ti->{releaseGroup}) {
		return checkFilterStrings($ti->{releaseGroup}, $releaseGroups);
	}
	else {
		my @ary = split /,/, regexEscapeWildcardString($releaseGroups);

		for my $temp (@ary) {
			my $releaseGroup = trim $temp;

			if ($ti->{torrentName} =~ /^\[$releaseGroup\]|\[$releaseGroup\]$|-\s*$releaseGroup$/i) {
				$ti->{releaseGroup} = $releaseGroup;
				return 1;
			}
		}
	}

	return 0;
}

sub checkFilterStrings {
	my ($name, $filterList) = @_;
	my @ary = split /,/, regexEscapeWildcardString($filterList);
	return checkStringArray($name, \@ary);
}

# Returns true if name matches one of the words in filterWordsAry
#	@param name	The string to check
#	@param filterWordsAry	Array containing all regex strings
sub checkStringArray {
	my ($name, $filterWordsAry) = @_;

	for my $temp (@$filterWordsAry) {
		my $filterWord = trim $temp;
		next unless $filterWord;
		my $s = '^' . $filterWord . '$';
		return 1 if $name =~ /$s/i;
	}

	return 0;
}

sub checkSite {
	my ($announceParser, $sitesFilter) = @_;

	my $trackerInfo = $announceParser->getTrackerInfo();
	return checkFilterStrings($trackerInfo->{siteName}, $sitesFilter) ||
		   checkFilterStrings($trackerInfo->{type}, $sitesFilter) ||
		   checkFilterStrings($trackerInfo->{longName}, $sitesFilter);
}

sub checkFilterNumbers {
	my ($num, $filterNums) = @_;

	$num = convertStringToInteger($num);
	return 0 unless defined $num;

	for my $temp (split /,/, $filterNums) {
		my $yearWord = trim $temp;
		my @ary = $yearWord =~ /^(\d+)(?:\s*-\s*(\d+))?$/;
		next unless @ary;

		my $n1 = convertStringToInteger($ary[0]);
		my $n2 = defined $ary[1] ? convertStringToInteger($ary[1]) : $n1;
		next unless defined $n1 && defined $n2;

		($n1, $n2) = ($n2, $n1) if $n2 < $n1;

		return 1 if $n1 <= $num && $num <= $n2;
	}

	return 0;
}

sub checkName {
	my ($name, $filterName) = @_;

	# first part is all ASCII chars except "a-zA-Z0-9*?,". Not same as [^a-zA-Z\d\*\?,].
	my $nregex = qr/[\x00-\x1F\x21-\x29\x2B\x2D-\x2F\x3A-\x3E\x40\x5B-\x60\x7B-\x7F\*\?,]/;
	my $fregex = qr/[\x00-\x1F\x21-\x29\x2B\x2D-\x2F\x3A-\x3E\x40\x5B-\x60\x7B-\x7F]/;
	$name =~ s/$nregex//g;
	$name = removeExtraSpaces($name);
	$filterName =~ s/$fregex//g;
	$filterName = removeExtraSpaces($filterName);
	return checkFilterStrings($name, $filterName);
}

sub checkArySynonyms {
	my ($value, $filterString, $arySynonyms) = @_;

	$value = lc $value;
	my $aryValidValues;
OUTER:
	for my $ary (@$arySynonyms) {
		for my $synonym (@$ary) {
			if ($value eq lc $synonym) {
				$aryValidValues = $ary;
				last OUTER;
			}
		}
	}
	return 0 unless defined $aryValidValues;

	for my $synonym (@$aryValidValues) {
		return 1 if checkFilterStrings($synonym, $filterString);
	}

	return 0;
}

sub checkFilterBitrate {
	my ($bitrate, $filterBitrates) = @_;

	$bitrate = canonicalizeBitrate($bitrate);
	for my $temp (split /,/, $filterBitrates) {
		my $filterBitrate = canonicalizeBitrate($temp, 1);
		return 1 if checkFilterStrings($bitrate, $filterBitrate);
	}

	return 0;
}

sub canonicalizeBitrate {
	my ($s, $isFilter) = @_;

	my $regex = '[^a-zA-Z\d.';
	$regex .= '*?' if $isFilter;
	$regex .= ']';

	$s =~ s/$regex//g;
	return lc $s;
}

sub checkFilterTags {
	my ($tags, $filterTags, $tagsAny) = @_;

	my $fixit = sub {
		my $s = shift;
		$s =~ s/[._]/ /g;
		$s =~ s/\s+/ /g;
		return [split /,/, $s];
	};

	my $aryTags = $fixit->($tags);
	my $aryFilterTags = $fixit->($filterTags);

	# Returns true if $filterTag is in @$aryTags
	my $isInTags = sub {
		my $filterTag = shift;
		$filterTag = trim $filterTag;
		for my $temp (@$aryTags) {
			my $tag = trim $temp;
			return 1 if checkFilterStrings($tag, $filterTag);
		}

		return 0;
	};

	if ($tagsAny) {
		for my $filterTag (@$aryFilterTags) {
			return 1 if $isInTags->($filterTag);
		}
	}
	else {
		for my $filterTag (@$aryFilterTags) {
			return 0 unless $isInTags->($filterTag);
		}
		return 1;
	}

	return 0;
}

sub checkFilterSize {
	my ($torrentSize, $filter) = @_;

	return 1 unless defined $torrentSize;

	my $minSize = convertByteSizeString($filter->{minSize});
	my $maxSize = convertByteSizeString($filter->{maxSize});

	return 0 if defined $minSize && $torrentSize < $minSize;
	return 0 if defined $maxSize && $torrentSize > $maxSize;
	return 1;
}

1;
