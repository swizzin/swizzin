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
# Parses IRC announces and creates a torrent info struct ($ti)
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::AnnounceParser;
use AutodlIrssi::Globals;
use AutodlIrssi::TextUtils;
use AutodlIrssi::InternetUtils;
use AutodlIrssi::MultiLineParser;
use AutodlIrssi::Constants;

sub new {
	my ($class, $trackerInfo, $state) = @_;
	my $self = bless {
		trackerInfo => $trackerInfo,
		state => $state,
		options => {},
		isDefaultOption => {},
	}, $class;

	$self->initializeOptions();

	if (defined $self->{trackerInfo}{parseInfo}{multilinepatterns}) {
		$self->{multiLineParser} = new AutodlIrssi::MultiLineParser($self->getTrackerName());
		my $multilinepatterns = $self->{trackerInfo}{parseInfo}{multilinepatterns};
		for my $obj (@$multilinepatterns) {
			$self->{multiLineParser}->addLineRegex($obj->{regexInfo}{regex}, $obj->{optional});
		}
	}

	return $self;
}

sub getTrackerInfo {
	return $_[0]->{trackerInfo};
}

sub getTrackerType {
	return $_[0]->{trackerInfo}->{type};
}

sub getTrackerName {
	return $_[0]->{trackerInfo}->{longName};
}

# Resets all options
sub resetOptions {
	shift->initializeOptions();
}

sub initializeOptions {
	my $self = shift;

	$self->{options} = {};
	$self->{isDefaultOption} = {};
	for my $setting (values %{$self->{trackerInfo}{settings}}) {
		$self->writeOption($setting->{name}, $setting->{defaultValue}, 1);
	}
}

# Returns an array reference of all download variables that have not been initialized
sub getUninitializedDownloadVars {
	my $self = shift;

	my $rv = [];
	for my $info (values %{$self->{trackerInfo}{settings}}) {
		next unless $info->{isDownloadVar};
		next if $self->readOption($info->{name}) ne '';
		push @$rv, $info->{name};
	}
	return $rv;
}

# Add options from an old announce parser. Make sure it has the same type as this one.
sub addOptionsFrom {
	my ($self, $other) = @_;

	die "Not same type of announce parser!\n" if $self->{trackerInfo}{type} ne $other->{trackerInfo}{type};

	$self->initializeOptions();
	while (my ($name, $value) = each %{$other->{options}}) {
		next if $other->{isDefaultOption}{$name};	# Don't use old default value, use current default value
		$self->writeOption($name, $value);
	}
}

# Returns true if the option exists
sub isOption {
	my ($self, $name) = @_;
	return defined ${$self->{trackerInfo}{settings}}{$name};
}

# Write a new value to a tracker option
sub writeOption {
	my ($self, $name, $value, $isDefaultValue) = @_;

	my $setting = ${$self->{trackerInfo}{settings}}{$name};
	return unless defined $setting;

	$self->{options}{$name} = "" . $value;
	$self->{isDefaultOption}{$name} = $isDefaultValue;
}

# Reads a tracker option. Returns undef if the option doesn't exist.
sub readOption {
	my ($self, $name) = @_;

	my $setting = ${$self->{trackerInfo}{settings}}{$name};
	return unless defined $setting;

	my $val = $self->{options}{$name};
	if ($setting->{type} eq "bool") {
		return convertStringToBoolean($val);
	}
	elsif ($setting->{type} eq "textbox") {
		return $val;
	}
	elsif ($setting->{type} eq "integer") {
		return convertStringToInteger($val);
	}
	else {
		die "$self->{trackerInfo}{longName}: Invalid setting type: $setting->{type}\n";
	}
}

# Returns true if we should ignore the line
sub shouldIgnoreLine {
	my ($self, $line) = @_;

	for my $ignore (@{$self->{trackerInfo}{parseInfo}{ignore}}) {

		# What the fuck is this??? You tell me! Remove this and all hell will break loose.
		# By removing this, Perl won't match my // (empty) regexes! There's something in my
		# code that will trigger this bug. If I test an empty // regex at startup, it works,
		# but not later.
		"" =~ /.?/;

		if (!($line =~ $ignore->{regex}) == !$ignore->{expected}) {
			return 1;
		}
	}

	return 0;
}

# Called each time a new announce line is received. Returns a $ti if it was parsed successfully,
# else undef is returned.
sub onNewLine {
	my ($self, $line) = @_;

	my $origLine = $line;
	$line = removeInvisibleChars($line);
	$line = stripMircColorCodes($line);
	$line = decodeHtmlEntities($line);

	my $ti = {
		releaseType			=> "",
		freeleech			=> "",
		freeleechPercent	=> "",
		origin				=> "",
		releaseGroup		=> "",
		category			=> "",
		torrentName			=> "",
		uploader			=> "",
		torrentSize			=> "",
		preTime				=> "",
		torrentUrl			=> "",
		torrentSslUrl		=> "",
		year				=> "",
		name1				=> "",		# artist, show, movie
		name2				=> "",		# album
		season				=> "",
		episode				=> "",
		resolution			=> "",
		source				=> "",
		encoder				=> "",
		container			=> "",
		format				=> "",
		bitrate				=> "",
		media				=> "",
		tags				=> "",
		scene				=> "",
		log					=> "",
		logScore			=> "",
		cue					=> "",
		line				=> $line,
		origLine			=> $origLine,
		site				=> $self->{trackerInfo}{siteName},
		httpHeaders			=> {},
		announceParser		=> $self,
	};

	my $val = eval {
		my $rv;
		if ($self->{trackerInfo}{parseInfo}{linepatterns}) {
			$rv = $self->parseSingleLine($line, $ti);
		}
		else {
			$rv = $self->parseMultiLine($line, $ti);
		}

		return $ti if $rv;
		return;
	};
	if ($@) {
		message 0, "Got exception in onNewLine: " . formatException($@);
		return;
	}

	return $ti if defined $val;
	return;
}

# Returns true if successful, and false if we couldn't parse the line.
sub parseSingleLine {
	my ($self, $line, $ti) = @_;

	for my $extractInfo (@{$self->{trackerInfo}{parseInfo}{linepatterns}}) {
		my @ary = $line =~ $extractInfo->{regexInfo}{regex};
		if (@ary) {
			my $tempVariables = {};
			$self->extractMatched($extractInfo, \@ary, $ti, $tempVariables);
			$self->onAllLinesMatched($ti, $tempVariables);
			return 1;
		}
	}

	if (!$self->shouldIgnoreLine($line)) {
		dmessage 0, $self->getTrackerName() . ": did not match line '$line'";
		return 0;
	}
	return 1;
}

# Returns true if successful, and false if we couldn't parse the line.
sub parseMultiLine {
	my ($self, $line, $ti) = @_;

	my $rv = $self->{multiLineParser}->addLine($line);
	if (ref $rv) {
		# Nothing
	}
	elsif ($rv) {
		return 1;
	}
	else {
		if (!defined $self->{multiLineParser}->getLineNumber($line) && !$self->shouldIgnoreLine($line)) {
			dmessage 0, $self->getTrackerName() . ": did not match line '$line'";
			return 0;
		}
		return 1;
	}

	my $tempVariables = {};
	my $i = -1;
	for my $extractInfo (@{$self->{trackerInfo}{parseInfo}{multilinepatterns}}) {
		$i++;
		next unless @{$extractInfo->{vars}};	# Some lines don't have any capturing parentheses
		my $line = $rv->{lines}[$i];
		next unless defined $line;	# Optional line
		my @ary = $line =~ $extractInfo->{regexInfo}{regex};
		$self->extractMatched($extractInfo, \@ary, $ti, $tempVariables);
	}
	$self->onAllLinesMatched($ti, $tempVariables);
	return 1;
}

# Called whenever an announce line matched an announce regex. $ary is the array reference of the
# extracted variables.
sub extractMatched {
	my ($self, $extractInfo, $ary, $ti, $tempVariables) = @_;

	if (@$ary != @{$extractInfo->{vars}}) {
		message 0, $self->getTrackerName() . ": invalid extractInfo.vars.length";
		return;
	}

	my $len = @{$extractInfo->{vars}};
	for (my $i = 0; $i < $len; $i++) {
		my $value = defined $ary->[$i] ? $ary->[$i] : "";
		$value = trim $value;
		$self->setVariable($extractInfo->{vars}[$i], $value, $ti, $tempVariables);
	}
}

# Write a variable. It's either in $ti or $tempVariables
sub setVariable {
	my ($self, $varName, $value, $ti, $tempVariables) = @_;

	$value = "" unless defined $value;

	if (exists $ti->{$varName} && !ref $ti->{$varName}) {
		$ti->{$varName} = $value;
	}
	else {
		$tempVariables->{$varName} = $value;
	}
}

# Read a variable. It's either in $ti, tracker's options, or $tempVariables
sub getVariable {
	my ($self, $varName, $ti, $tempVariables) = @_;

	my $rv;
	if (exists $ti->{$varName} && !ref $ti->{$varName}) {
		$rv = $ti->{$varName};
	}
	elsif (exists $self->{options}{$varName}) {
		$rv = $self->{options}{$varName};
	}
	else {
		$rv = $tempVariables->{$varName};
	}

	return defined $rv ? $rv : "";
}

sub handleExtractInfo {
	my ($self, $ti, $tempVariables, $extractInfo) = @_;

	my $value = $self->getVariable($extractInfo->{srcvar}, $ti, $tempVariables);

	my @ary = $value =~ $extractInfo->{regexInfo}{regex};
	return 0 unless @ary;

	$self->extractMatched($extractInfo, \@ary, $ti, $tempVariables);
	return 1;
}

sub postProcess {
	my ($self, $ti, $tempVariables, $children) = @_;

	for my $obj (@$children) {
		if ($obj->{type} eq "var" || $obj->{type} eq "http") {
			$self->onVarOrHttp($obj, $ti, $tempVariables);
		}
		elsif ($obj->{type} eq "extract") {
			if (!$self->handleExtractInfo($ti, $tempVariables, $obj->{extract}) && !$obj->{extract}{optional}) {
				message 0, "extract: Did not match regex: " . $obj->{extract}{regexInfo}{regex} . ", varName: '" . $obj->{extract}{srcvar} . "'";
			}
		}
		elsif ($obj->{type} eq "extractone") {
			my $extracted = 0;
			for my $extractInfo (@{$obj->{ary}}) {
				if ($self->handleExtractInfo($ti, $tempVariables, $extractInfo)) {
					$extracted = 1;
					last;
				}
			}
			if (!$extracted) {
				message 0, "extractone: Did not match any regex.";
			}
		}
		elsif ($obj->{type} eq "extracttags") {
			$self->handleExtractTags($ti, $tempVariables, $obj);
		}
		elsif ($obj->{type} eq "varreplace") {
			$self->handleVarreplace($ti, $tempVariables, $obj);
		}
		elsif ($obj->{type} eq "setregex") {
			$self->handleSetregex($ti, $tempVariables, $obj);
		}
		elsif ($obj->{type} eq "if") {
			$self->handleIf($ti, $tempVariables, $obj);
		}
		else {
			die "Invalid obj.type: " . $obj->{type} . "\n";
		}
	}
}

sub onAllLinesMatched {
	my ($self, $ti, $tempVariables) = @_;

	$self->{state}{lastAnnounce} = $self->{state}{lastCheck} = time();
	$ti->{torrentName} = trim $ti->{torrentName};

	$self->postProcess($ti, $tempVariables, $self->{trackerInfo}{parseInfo}{linematched});

	# Some trackers are "secret" so we can't use their names or domain names.
	if ($ti->{site} eq "") {
		my @ary = $ti->{torrentUrl} =~ /:\/\/([^\/:]*)/;
		if (@ary) {
			$ti->{site} = $ary[0];
		}
	}

	extractReleaseNameInfo($ti, $ti->{torrentName});

	$ti->{torrentSize} = convertToByteSizeString(convertByteSizeString($ti->{torrentSize})) || "";
	$ti->{preTime} = convertToTimeSinceString(convertTimeSinceString($ti->{preTime})) || "";
	$ti->{scene} = convertStringToBoolean($ti->{scene}) if $ti->{scene};
	$ti->{freeleech} = convertStringToBoolean($ti->{freeleech}) if $ti->{freeleech};
	$ti->{log} = convertStringToBoolean($ti->{log}) if $ti->{log};
	$ti->{cue} = convertStringToBoolean($ti->{cue}) if $ti->{cue};

	my $canonicalizeIt = sub {
		my ($name, $ary) = @_;
		$name = lc $name;
		for my $ary2 (@$ary) {
			for my $name2 (@$ary2) {
				if ($name eq lc $name2) {
					return $ary2->[0];
				}
			}
		}

		return $name;
	};
	$ti->{resolution} = $canonicalizeIt->($ti->{resolution}, $AutodlIrssi::Constants::tvResolutions);
	$ti->{source} = $canonicalizeIt->($ti->{source}, $AutodlIrssi::Constants::tvSources);
	$ti->{encoder} = $canonicalizeIt->($ti->{encoder}, $AutodlIrssi::Constants::tvEncoders);

	$ti->{canonicalizedName} = canonicalizeReleaseName($ti->{torrentName});

	my @outputSites = split /,/, $AutodlIrssi::g->{options}{advancedOutputSites};

	if (checkRegexArray($self->getTrackerType(), \@outputSites)) {
		my $msg = "\x02\x0303" . $self->getTrackerName() . "\x03\x02";
		my $dumpVars = sub {
			my $base = shift;

			for my $o (sort keys %$base) {
				my $v = $base->{$o};
				next if !defined $v || $v eq "" || ref $v;
				next if $o eq "line" || $o eq "origLine";
				if ($o eq "cookie") {
					$v =~ s/(?<=[=])(.+?)(?=;|$)/<removed>/g;
				}
				$msg .= " : \x02\x0306" . $o . "\x03\x02: '\x02\x0304" . $v . "\x03\x02'";
			}
		};
		$dumpVars->($ti);
		$dumpVars->($tempVariables);
		$dumpVars->($ti->{httpHeaders});

		# Censor private information from torrentUrl.
		$msg =~ s/(?<=authkey=)([\da-zA-Z]+)/<removed>/;
		$msg =~ s/(?<=passkey=)([\da-zA-Z]+)/<removed>/;
		$msg =~ s/(?<=torrent_pass=)([\da-zA-Z]+)/<removed>/;

		# Special treatment for some trackers is needed.
		$msg =~ s/(\/(?:rss\/download|rssdownload\.php|download\.php)\/\d+\/)([\da-zA-Z]+)(\/.*.torrent)/$1<removed>$3/;
		$msg =~ s/(?<=secret_key=)([\da-zA-Z]+)/<removed>/;
		$msg =~ s/(?<=pk=)([\da-zA-Z]+)/<removed>/;
		$msg =~ s/(?<=\/)([\da-zA-Z]{32})(?=\/)/<removed>/;

		umessage $msg;
	}

	if ($ti->{torrentSslUrl} eq "") {
		($ti->{torrentSslUrl} = $ti->{torrentUrl}) =~ s/^https?/https/;
	}
}

sub checkRegexArray {
	my ($name, $filterWordsAry) = @_;

	for my $temp (@$filterWordsAry) {
		my $filterWord = trim $temp;
		next unless $filterWord;
		my $s = '^' . $filterWord . '$';
		return 1 if $name =~ /$s/i || $filterWord eq "all";
	}

	return 0;
}

sub handleExtractTags {
	my ($self, $ti, $tempVariables, $obj) = @_;

	my $varValue = $self->getVariable($obj->{srcvar}, $ti, $tempVariables);
	my $s = $obj->{split};
	for my $temp (split /$s/, $varValue) {
		my $tagName = trim $temp;
		next unless $tagName;

		my $hasSetVar = 0;
		for my $setvarifInfo (@{$obj->{ary}}) {
			$hasSetVar = $self->handleSetvarifInfo($ti, $tempVariables, $setvarifInfo, $tagName);
			last if $hasSetVar;
		}
	}
}

sub handleVarreplace {
	my ($self, $ti, $tempVariables, $obj) = @_;

	my $varreplace = $obj->{varreplace};
	my $srcvar = $self->getVariable($varreplace->{srcvar}, $ti, $tempVariables);
	my ($qr, $new) = ($varreplace->{regex}, $varreplace->{replace});
	(my $newValue = $srcvar) =~ s/$qr/$new/g;
	$self->setVariable($varreplace->{name}, $newValue, $ti, $tempVariables);
}

sub handleSetregex {
	my ($self, $ti, $tempVariables, $obj) = @_;

	my $setregex = $obj->{setregex};
	my $srcvar = $self->getVariable($setregex->{srcvar}, $ti, $tempVariables);
	if ($srcvar =~ $setregex->{regex}) {
		$self->setVariable($setregex->{varName}, $setregex->{newValue}, $ti, $tempVariables);
	}
}

sub handleIf {
	my ($self, $ti, $tempVariables, $obj) = @_;

	my $if = $obj->{if};
	my $srcvar = $self->getVariable($if->{srcvar}, $ti, $tempVariables);
	if ($srcvar =~ $if->{regex}) {
		$self->postProcess($ti, $tempVariables, $if->{children});
	}
}

sub handleSetvarifInfo {
	my ($self, $ti, $tempVariables, $setvarifInfo, $tagName) = @_;

	if (defined $setvarifInfo->{value}) {
		return 0 if lc $setvarifInfo->{value} ne lc $tagName;
	}
	else {
		return 0 if $tagName !~ $setvarifInfo->{regex};
	}

	my $newValue = $setvarifInfo->{newValue} || $tagName;
	$self->setVariable($setvarifInfo->{varName}, $newValue, $ti, $tempVariables);
	return 1;
}

sub onVarOrHttp {
	my ($self, $obj, $ti, $tempVariables) = @_;

	my $newValue = "";
	for my $o (@{$obj->{vars}}) {
		if ($o->{type} eq "var") {
			$newValue .= $self->getVariable($o->{name}, $ti, $tempVariables);
		}
		elsif ($o->{type} eq "varenc") {
			my $name = $o->{name};
			my $value = $self->getVariable($name, $ti, $tempVariables);
			$value =~ s![/\\]!_!g;	# Replace invalid chars or the download could fail
			$newValue .= toUrlEncode($value);
		}
		elsif ($o->{type} eq "string") {
			$newValue .= $o->{value};
		}
		elsif ($o->{type} eq "delta") {
			$newValue .= $self->getVariable($o->{name1}, $ti, $tempVariables) +
						 $self->getVariable($o->{name2}, $ti, $tempVariables);
		}
		else {
			die "Invalid o.type: " . $o->{type} . "\n";
		}
	}

	if ($obj->{type} eq "http") {
		$ti->{httpHeaders}{$obj->{name}} = $newValue;
	}
	else {
		$self->setVariable($obj->{name}, $newValue, $ti, $tempVariables);
	}
}

sub extractReleaseNameInfo {
	my ($out, $releaseName) = @_;

	my $canonicalize = sub {
		my $s = shift;
		$s =~ s/[^a-zA-Z0-9]/ /g;
		return $s;
	};

	my $setVariable = sub {
		my ($name, $value) = @_;
		if (!$out->{$name}) {
			$out->{$name} = $value;
		}
	};

	my $data;

	my $canonReleaseName = $canonicalize->($releaseName);

	my $findLast = sub {
		my ($s, $regex) = @_;
		my $rv = {};
		for (my $indexBase = 0; $s; ) {
			last unless $s =~ /$regex/g;

			$rv->{index} = $indexBase + length $`;
			$rv->{value} = $1;
			$indexBase += pos($s);
			$s = substr $s, pos($s);
		}

		return unless defined $rv->{index};
		return $rv;
	};

	my $indexYear;
	if ($data = $findLast->($canonReleaseName, qr/(?:^|\D)(19[3-9]\d|20[01]\d)(?:\D|$)/)) {
		$indexYear = $data->{index};
		$setVariable->("year", 0 + $data->{value});
	}

	my $indexSeason;
	if (($data = $findLast->($canonReleaseName, qr/\sS(\d+)\s?[ED]\d+/i)) ||
		($data = $findLast->($canonReleaseName, qr/\s(?:S|Season\s*)(\d+)/i)) ||
		($data = $findLast->($canonReleaseName, qr/\s((?<!\d)\d{1,2})x\d+/i))) {
		$indexSeason = $data->{index};
		$setVariable->("season", 0 + $data->{value});
	}

	my $indexEpisode;
	if (($data = $findLast->($canonReleaseName, qr/\sS\d+\s?E(\d+)/i)) ||
		($data = $findLast->($canonReleaseName, qr/\s(?:E|Episode\s*)(\d+)/i)) ||
		($data = $findLast->($canonReleaseName, qr/\s(?<!\d)\d{1,2}x(\d+)/i))) {
		$indexEpisode = $data->{index};
		$setVariable->("episode", 0 + $data->{value});
	}

	# Year month day must be part of canonicalized name if it's present.
	my $indexYmd;
	if ($data = $findLast->($canonReleaseName, qr/(?:^|\D)((?:19[3-9]\d|20[01]\d)\s\d{1,2}\s\d{1,2})(?:\D|$)/)) {
		$indexYmd = $data->{index};
		$setVariable->("ymd", $data->{value});
	}

	my $startIndex = my_max(0, $indexSeason, $indexEpisode, $indexYmd);
	my $find = sub {
		my ($aryStrings, $isCaseSensitive) = @_;

		my $rv = {
			index	=> 99999999999,
			value	=> "",
		};

		for my $strings (@$aryStrings) {
			for my $searchString (@$strings) {
				my $canonSearchString = $canonicalize->($searchString);
				my $regexStr = "\\s$canonSearchString(?:\\s|\$)";
				my $qr = $isCaseSensitive ? qr/$regexStr/ : qr/$regexStr/i;
				my $tmp = $findLast->($canonReleaseName, $qr);
				if (defined $tmp && $tmp->{index} >= $startIndex && $tmp->{index} < $rv->{index}) {
					$rv->{index} = $tmp->{index};
					$rv->{value} = $searchString;
				}
			}
		}

		return $rv if $rv->{value};
		return;
	};

	my $indexResolution;
	if ($data = $find->($AutodlIrssi::Constants::tvResolutions)) {
		$indexResolution = $data->{index};
		$out->{resolution} = $data->{value};
	}

	my $indexSource;
	if ($data = $find->($AutodlIrssi::Constants::tvSources)) {
		$indexSource = $data->{index};
		$out->{source} = $data->{value};
	}

	my $indexEncoder;
	if ($data = $find->($AutodlIrssi::Constants::tvEncoders)) {
		$indexEncoder = $data->{index};
		$out->{encoder} = $data->{value};
	}

	my $indexIgnore;
	if (($data = $find->($AutodlIrssi::Constants::otherReleaseNameStuff, 1)) ||
		($data = $find->($AutodlIrssi::Constants::otherReleaseNameStuffLowerCase, 1))) {
		$indexIgnore = $data->{index};
	}

	# Some MP3 releases contain the tag "WEB"
	my $isTvOrMovie = !!($out->{resolution} || ($out->{source} && lc($out->{source}) ne "web") ||
						$out->{encoder} || $out->{season} || $out->{episode});

	if ($isTvOrMovie) {
		# Don't use the year index if it's a TV show since the year may be part of the name.
		my $yindex = $indexYear;
		if ($out->{season} || $out->{episode} || ($out->{source} && $out->{source} =~ /HDTV|PDTV/i)) {
			if ($canonReleaseName !~ /(?:^|\D)(?:19[4-9]\d|20[01]\d)\s+\d\d\s+\d\d(?:\D|$)/) {
				$yindex = undef;
			}
		}
		my $indexMin = my_min($indexResolution, $indexSource, $indexEncoder, $indexIgnore,
							$yindex, $indexSeason, $indexEpisode, $indexYmd);

		if (defined $indexMin) {
			my $name1 = substr $releaseName, 0, $indexMin;
			$name1 =~ s/[^a-zA-Z0-9]/ /g;
			$name1 =~ s/\s+/ /g;
			$name1 = trim $name1;
			$setVariable->("name1", $name1);
		}
	}
}

sub my_min {
	my $rv;
	for my $v (@_) {
		if (defined $v && (!defined $rv || $v < $rv)) {
			$rv = $v;
		}
	}
	return $rv;
}

sub my_max {
	my $rv;
	for my $v (@_) {
		if (defined $v && (!defined $rv || $v > $rv)) {
			$rv = $v;
		}
	}
	return $rv;
}

1;
