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
# Parses ~/.autodl/autodl.cfg
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::AutodlConfigFileParser;
use AutodlIrssi::Constants;
use AutodlIrssi::TextUtils;
use base qw/ AutodlIrssi::ConfigFileParser /;

sub defaultOptions {
	return {
		updateCheck => 'ask',	# auto, ask, disabled
		githubToken => '',
		userAgent => 'autodl-irssi',
		userAgentTracker => '',
		peerId => '',
		maxSavedReleases => 1000,
		saveDownloadHistory => 1,
		downloadDupeReleases => 0,
		maxDownloadRetryTimeSeconds => 5*60,
		level => 3,
		debug => 0,
		advancedOutputSites => '',
		useRegex => 0,
		uploadType => AutodlIrssi::Constants::UPLOAD_WATCH_FOLDER(),
		uploadWatchDir => '',
		uploadFtpPath => '',
		uploadCommand => '',
		uploadArgs => '',
		uploadDyndir => '',
		rtDir => '',
		rtCommands => '',
		rtLabel => '',
		rtRatioGroup => '',
		rtChannel => '',
		rtPriority => '',
		rtIgnoreScheduler => 0,
		rtDontAddName => 0,
		rtAddress => '',
		pathToUtorrent => '',
		memoryLeakCheck => 0,
		guiServerPort => 0,
		guiServerPassword => '',
		allowed => '',
		uniqueTorrentNames => 0,

		webui => {
			user => '',
			password => '',
			hostname => '',
			port => 0,
			ssl => 0,
		},

		ftp => {
			user => '',
			password => '',
			hostname => '',
			port => 0,
		},

		irc => {
			autoConnect => 1,
			userName => '',
			realName => '',
			outputServer => '',
			outputChannel => '',
			closeNickserv => 0,
		}
	};
}

sub _convertPriority {
	my $prio = lc shift;

	return "" if $prio eq "";
	return 3 if $prio eq "high";
	return 2 if $prio eq "normal";
	return 1 if $prio eq "low";
	return 0 if $prio eq "dont-download";
	return $prio if $prio =~ /^[0-3]$/;

	return "";
}

sub new {
	my ($class, $trackerManager) = @_;

	my $self = $class->SUPER::new();

	$self->{trackerManager} = $trackerManager;
	$self->{filters} = [];
	$self->{options} = defaultOptions();
	$self->{servers} = {};

	return $self;
}

sub getFilters {
	return shift->{filters};
}

sub getOptions {
	return shift->{options};
}

sub getServers {
	return shift->{servers};
}

sub parse {
	my ($self, $pathname) = @_;

	my $headers = $self->SUPER::parse($pathname);
	$self->{trackerManager}->resetTrackerOptions() if $self->{trackerManager};

	while (my ($headerType, $aryHeader) = each %$headers) {
		if ($headerType eq 'filter') {
			$self->doHeaderFilter($aryHeader);
		}
		elsif ($headerType eq 'options') {
			$self->doHeaderOptions($aryHeader);
		}
		elsif ($headerType eq 'webui') {
			$self->doHeaderWebui($aryHeader);
		}
		elsif ($headerType eq 'ftp') {
			$self->doHeaderFtp($aryHeader);
		}
		elsif ($headerType eq 'irc') {
			$self->doHeaderIrc($aryHeader);
		}
		elsif ($headerType eq 'tracker') {
			$self->doHeaderTracker($aryHeader);
		}
		elsif ($headerType eq 'server') {
			$self->doHeaderServer($aryHeader);
		}
		elsif ($headerType eq 'channel') {
			$self->doHeaderChannel($aryHeader);
		}
		else {
			$self->doHeaderUnknown($aryHeader, $headerType);
		}
	}
}

sub fixHostname {
	my $hostname = shift;
	return '' unless $hostname =~ m{^(?:\w+://)?([^:/\s]+)};
	return $1;
}

sub checkValidUploadType {
	my ($self, $uploadType, $info) = @_;

	$uploadType = lc $uploadType;

	my @ary = (
		AutodlIrssi::Constants::UPLOAD_WATCH_FOLDER(),
		AutodlIrssi::Constants::UPLOAD_WEBUI(),
		AutodlIrssi::Constants::UPLOAD_FTP(),
		AutodlIrssi::Constants::UPLOAD_TOOL(),
		AutodlIrssi::Constants::UPLOAD_DYNDIR(),
		AutodlIrssi::Constants::UPLOAD_RTORRENT(),
	);
	for my $name (@ary) {
		return 1 if lc $name eq $uploadType;
	}

	$self->error($info->{lineNumber}, "Invalid upload-type '$uploadType'");
	return 0;
}

sub mergeHeaderOptions {
	my $aryHeader = shift;

	my $options = {};

	for my $header (@$aryHeader) {
		@$options{keys %{$header->{options}}} = values %{$header->{options}};
	}

	return $options;
}

sub readOption {
	my ($self, $options, $name) = @_;
	my $option = $options->{$name};
	return unless defined $option;
	return $option->{value};
}

sub setOptions {
	my ($self, $type, $dest, $options, $nameToOptionsVar) = @_;

	while (my ($name, $option) = each %$options) {
		my $destName = $nameToOptionsVar->{$name};
		if (!defined $destName || !exists $dest->{$destName} || ref $dest->{$destName}) {
			$self->error($option->{lineNumber}, "$type: Unknown option '$name'");
			next;
		}

		my $value = $option->{value};
		next if $value eq '';

		if ($value =~ m/^[*?]+$/) {
			$self->error($option->{lineNumber}, "$name set to bare wildcard. This is unnecessary and unsupported by some options.");
			next;
		}

		$dest->{$destName} = $value;
	}
}

# Initialize options from all [filter] headers
sub doHeaderFilter {
	my ($self, $aryHeader) = @_;

	for my $header (@$aryHeader) {
		my $filter = {
			name => '',
			enabled => 1,
			matchReleases => '',
			exceptReleases => '',
			matchCategories => '',
			exceptCategories => '',
			matchUploaders => '',
			exceptUploaders => '',
			matchSites => '',
			exceptSites => '',
			minSize => '',
			maxSize => '',
			maxPreTime => '',
			seasons => '',
			episodes => '',
			smartEpisode => 0,
			resolutions => '',
			sources => '',
			encoders => '',
			containers => '',
			years => '',
			artists => '',
			albums => '',
			matchReleaseTypes => '',
			exceptReleaseTypes => '',
			formats => '',
			bitrates => '',
			media => '',
			tags => '',
			tagsAny => 1,
			exceptTags => '',
			exceptTagsAny => 1,
			scene => '',
			freeleech => '',
			freeleechPercents => '',
			origins => '',
			releaseGroups => '',
			matchReleaseGroups => '',
			exceptReleaseGroups => '',
			log => '',
			logScores => '',
			cue => '',
			maxDownloads => '',
			maxDownloadsPer => '',
			downloadDupeReleases => 0,
			priority => 0,
			useRegex => 0,
			uploadType => '',
			uploadWatchDir => '',
			uploadFtpPath => '',
			uploadCommand => '',
			uploadArgs => '',
			uploadDyndir => '',
			rtDir => '',
			rtCommands => '',
			rtLabel => '',
			rtRatioGroup => '',
			rtChannel => '',
			rtPriority => '',
			rtIgnoreScheduler => 0,
			rtDontAddName => 0,
			wolMacAddress => '',
			wolIpAddress => '',
			wolPort => '',
			uploadDelaySecs => 0,
		};

		my $options = $header->{options};
		$self->setOptions('FILTER', $filter, $options, {
			'enabled' => 'enabled',
			'match-releases' => 'matchReleases',
			'except-releases' => 'exceptReleases',
			'match-categories' => 'matchCategories',
			'except-categories' => 'exceptCategories',
			'match-uploaders' => 'matchUploaders',
			'except-uploaders' => 'exceptUploaders',
			'match-sites' => 'matchSites',
			'except-sites' => 'exceptSites',
			'min-size' => 'minSize',
			'max-size' => 'maxSize',
			'max-pretime' => 'maxPreTime',
			'seasons' => 'seasons',
			'episodes' => 'episodes',
			'smart-episode' => 'smartEpisode',
			'resolutions' => 'resolutions',
			'sources' => 'sources',
			'encoders' => 'encoders',
			'containers' => 'containers',
			'years' => 'years',
			'shows' => 'artists',
			'match-release-types' => 'matchReleaseTypes',
			'except-release-types' => 'exceptReleaseTypes',
			'albums' => 'albums',
			'formats' => 'formats',
			'bitrates' => 'bitrates',
			'media' => 'media',
			'tags' => 'tags',
			'tags-any' => 'tagsAny',
			'except-tags' => 'exceptTags',
			'except-tags-any' => 'exceptTagsAny',
			'scene' => 'scene',
			'freeleech' => 'freeleech',
			'freeleech-percents' => 'freeleechPercents',
			'origins' => 'origins',
			'release-groups' => 'matchReleaseGroups',
			'match-release-groups' => 'matchReleaseGroups',
			'except-release-groups' => 'exceptReleaseGroups',
			'log' => 'log',
			'log-scores' => 'logScores',
			'cue' => 'cue',
			'max-downloads' => 'maxDownloads',
			'max-downloads-per' => 'maxDownloadsPer',
			'download-duplicates' => 'downloadDupeReleases',
			'priority' => 'priority',
			'use-regex' => 'useRegex',
			'upload-type' => 'uploadType',
			'upload-watch-dir' => 'uploadWatchDir',
			'upload-ftp-path' => 'uploadFtpPath',
			'upload-command' => 'uploadCommand',
			'upload-args' => 'uploadArgs',
			'upload-dyndir' => 'uploadDyndir',
			'rt-dir' => 'rtDir',
			'rt-commands' => 'rtCommands',
			'rt-label' => 'rtLabel',
			'rt-ratio-group' => 'rtRatioGroup',
			'rt-channel' => 'rtChannel',
			'rt-priority' => 'rtPriority',
			'rt-ignore-scheduler' => 'rtIgnoreScheduler',
			'rt-dont-add-name' => 'rtDontAddName',
			'wol-mac-address' => 'wolMacAddress',
			'wol-ip-address' => 'wolIpAddress',
			'wol-port' => 'wolPort',
			'upload-delay-secs' => 'uploadDelaySecs',
		});
		$filter->{name} = $header->{name};

		if ($filter->{uploadType} ne '') {
			$self->checkValidUploadType($filter->{uploadType}, $options->{'upload-type'});
		}
		$filter->{enabled} = convertStringToBoolean($filter->{enabled});
		$filter->{smartEpisode} = convertStringToBoolean($filter->{smartEpisode});
		$filter->{scene} = convertStringToBoolean($filter->{scene}) if $filter->{scene};
		$filter->{freeleech} = convertStringToBoolean($filter->{freeleech}) if $filter->{freeleech};
		$filter->{log} = convertStringToBoolean($filter->{log}) if $filter->{log};
		$filter->{cue} = convertStringToBoolean($filter->{cue}) if $filter->{cue};
		$filter->{maxDownloads} = convertStringToInteger($filter->{maxDownloads}, -1);
		$filter->{downloadDupeReleases} = convertStringToBoolean($filter->{downloadDupeReleases});
		$filter->{useRegex} = convertStringToBoolean($filter->{useRegex});
		$filter->{rtPriority} = _convertPriority($filter->{rtPriority});
		$filter->{rtIgnoreScheduler} = convertStringToBoolean($filter->{rtIgnoreScheduler});
		$filter->{rtDontAddName} = convertStringToBoolean($filter->{rtDontAddName});
		$filter->{tagsAny} = convertStringToBoolean($filter->{tagsAny});
		$filter->{exceptTagsAny} = convertStringToBoolean($filter->{exceptTagsAny});
		$filter->{uploadDelaySecs} = convertStringToInteger($filter->{uploadDelaySecs}, -1);

		push @{$self->{filters}}, $filter;
	}
}

# Initialize options from all [options] headers
sub doHeaderOptions {
	my ($self, $aryHeader) = @_;

	my $options = mergeHeaderOptions($aryHeader);
	$self->setOptions('OPTIONS', $self->{options}, $options, {
		'update-check' => 'updateCheck',
		'github-token' => 'githubToken',
		'user-agent' => 'userAgent',
		'user-agent-tracker' => 'userAgentTracker',	# Not used anymore
		'peer-id' => 'peerId',						# Not used anymore
		'max-saved-releases' => 'maxSavedReleases',
		'save-download-history' => 'saveDownloadHistory',
		'download-duplicates' => 'downloadDupeReleases',
		'download-retry-time-seconds' => 'maxDownloadRetryTimeSeconds',
		'output-level' => 'level',
		'debug' => 'debug',
		'advanced-output-sites' => 'advancedOutputSites',
		'use-regex' => 'useRegex',
		'upload-type' => 'uploadType',
		'upload-watch-dir' => 'uploadWatchDir',
		'upload-ftp-path' => 'uploadFtpPath',
		'upload-command' => 'uploadCommand',
		'upload-args' => 'uploadArgs',
		'upload-dyndir' => 'uploadDyndir',
		'rt-dir' => 'rtDir',
		'rt-commands' => 'rtCommands',
		'rt-label' => 'rtLabel',
		'rt-ratio-group' => 'rtRatioGroup',
		'rt-channel' => 'rtChannel',
		'rt-priority' => 'rtPriority',
		'rt-ignore-scheduler' => 'rtIgnoreScheduler',
		'rt-dont-add-name' => 'rtDontAddName',
		'rt-address' => 'rtAddress',
		'path-utorrent' => 'pathToUtorrent',
		'memory-leak-check' => 'memoryLeakCheck',
		'gui-server-port' => 'guiServerPort',
		'gui-server-password' => 'guiServerPassword',
		'allowed' => 'allowed',
		'unique-torrent-names' => 'uniqueTorrentNames',
	});

	$self->checkValidUploadType($self->{options}{uploadType}, $options->{'upload-type'});
	$self->{options}{maxSavedReleases} = convertStringToInteger($self->{options}{maxSavedReleases}, 1000, 0);
	$self->{options}{saveDownloadHistory} = convertStringToBoolean($self->{options}{saveDownloadHistory});
	$self->{options}{downloadDupeReleases} = convertStringToBoolean($self->{options}{downloadDupeReleases});
	$self->{options}{maxDownloadRetryTimeSeconds} = convertStringToInteger($self->{options}{maxDownloadRetryTimeSeconds}, 5*60, 0);
	$self->{options}{level} = convertStringToInteger($self->{options}{level}, 3, -1, 5);
	$self->{options}{debug} = convertStringToBoolean($self->{options}{debug});
	$self->{options}{useRegex} = convertStringToBoolean($self->{options}{useRegex});
	$self->{options}{memoryLeakCheck} = convertStringToBoolean($self->{options}{memoryLeakCheck});
	$self->{options}{uniqueTorrentNames} = convertStringToBoolean($self->{options}{uniqueTorrentNames});
	if ($self->{options}{updateCheck} ne "auto" &&
		$self->{options}{updateCheck} ne "ask" &&
		$self->{options}{updateCheck} ne "disabled") {
		$self->{options}{updateCheck} = "ask";
	}
	$self->{options}{rtPriority} = _convertPriority($self->{options}{rtPriority});
	$self->{options}{rtIgnoreScheduler} = convertStringToBoolean($self->{options}{rtIgnoreScheduler});
	$self->{options}{rtDontAddName} = convertStringToBoolean($self->{options}{rtDontAddName});
}

# Initialize options from all [webui] headers
sub doHeaderWebui {
	my ($self, $aryHeader) = @_;

	my $options = mergeHeaderOptions($aryHeader);
	$self->setOptions('WEBUI', $self->{options}{webui}, $options, {
		user => 'user',
		password => 'password',
		hostname => 'hostname',
		port => 'port',
		ssl => 'ssl',
	});

	$self->{options}{webui}{hostname} = fixHostname($self->{options}{webui}{hostname});
	$self->{options}{webui}{port} = convertStringToInteger($self->{options}{webui}{port}, 0, 0, 65535);
	$self->{options}{webui}{ssl} = convertStringToBoolean($self->{options}{webui}{ssl});
}

# Initialize options from all [ftp] headers
sub doHeaderFtp {
	my ($self, $aryHeader) = @_;

	my $options = mergeHeaderOptions($aryHeader);
	$self->setOptions('FTP', $self->{options}{ftp}, $options, {
		user => 'user',
		password => 'password',
		hostname => 'hostname',
		port => 'port',
	});

	$self->{options}{ftp}{hostname} = fixHostname($self->{options}{ftp}{hostname});
	$self->{options}{ftp}{port} = convertStringToInteger($self->{options}{ftp}{port}, 0, 0, 65535);
}

sub doHeaderIrc {
	my ($self, $aryHeader) = @_;

	my $options = mergeHeaderOptions($aryHeader);
	$self->setOptions('IRC', $self->{options}{irc}, $options, {
		'auto-connect' => 'autoConnect',
		'user-name' => 'userName',
		'real-name' => 'realName',
		'output-server' => 'outputServer',
		'output-channel' => 'outputChannel',
		'close-nickserv' => 'closeNickserv',
	});

	$self->{options}{irc}{autoConnect} = convertStringToBoolean($self->{options}{irc}{autoConnect});
	$self->{options}{irc}{closeNickserv} = convertStringToBoolean($self->{options}{irc}{closeNickserv});
}

# Initialize options from all [tracker] headers
sub doHeaderTracker {
	my ($self, $aryHeader) = @_;

	return unless defined $self->{trackerManager};

	for my $header (@$aryHeader) {
		my $trackerType = $header->{name};
		my $announceParser = $self->{trackerManager}->findAnnounceParserFromType($trackerType);
		if (!defined $announceParser) {
			next;
		}

		while (my ($name, $option) = each %{$header->{options}}) {
			my $value = $option->{value};
			if (!$announceParser->isOption($name) && $name ne 'checkregd') {
				$self->error($option->{lineNumber}, "$trackerType: Unknown tracker option '$name'");
				next;
			}

			$announceParser->writeOption($name, $value);
		}

		my $uninitialized = $announceParser->getUninitializedDownloadVars();
		my $isEnabled = $announceParser->readOption("enabled");
		if ($isEnabled && @$uninitialized) {
			my $uninitializedStr = join ", ", @$uninitialized;
			$self->error($header->{lineNumber}, "$trackerType: Missing option(s): $uninitializedStr");
		}
	}
}

sub doHeaderUnknown {
	my ($self, $aryHeader, $headerType) = @_;
	for my $header (@$aryHeader) {
		$self->error($header->{lineNumber}, "Unknown header '$headerType'");
	}
}

sub getServerInfo {
	my ($self, $serverName) = @_;

	$serverName = canonicalizeServerName($serverName);
	my $serverInfo = $self->{servers}{$serverName};
	if (!defined $serverInfo) {
		$self->{servers}{$serverName} = $serverInfo = {
			server => $serverName,
			enabled => 'true',
			port => "",
			ssl => "",
			nick => "",
			bnc=>'false',
			identPassword => "",
			identEmail => "",
			channels => {},
			serverPassword => "",
		};
	}
	return $serverInfo;
}

sub doHeaderServer {
	my ($self, $aryHeader) = @_;

	for my $header (@$aryHeader) {
		my $serverInfo = $self->getServerInfo($header->{name});
		$self->setOptions('SERVER', $serverInfo, $header->{options}, {
			enabled => 'enabled',
			port => 'port',
			ssl => 'ssl',
			nick => 'nick',
			bnc => 'bnc',
			'ident-password' => 'identPassword',
			'ident-email' => 'identEmail',
			'server-password' => 'serverPassword',
		});
	}
}

sub doHeaderChannel {
	my ($self, $aryHeader) = @_;

	for my $header (@$aryHeader) {
		my $serverInfo = $self->getServerInfo($header->{name});

		my $channelName = canonicalizeChannelName($self->readOption($header->{options}, 'name') || "");
		if ($channelName !~ /^#./) {
			$self->error($header->{lineNumber}, "Invalid or missing channel name");
			next;
		}

		my $channelInfo = $serverInfo->{channels}{$channelName};
		if (!defined $channelInfo) {
			$serverInfo->{channels}{$channelName} = $channelInfo = {
				name => "",
				inviteCommand => "",
				inviteHttpData => "",
				inviteHttpHeader => "",
				inviteHttpUrl => "",
				password => "",
			};
		}

		$self->setOptions('CHANNEL', $channelInfo, $header->{options}, {
			name => 'name',
			'invite-command' => 'inviteCommand',
			'invite-http-data' => 'inviteHttpData',
			'invite-http-header' => 'inviteHttpHeader',
			'invite-http-url' => 'inviteHttpUrl',
			password => 'password',
		});
	}
}

1;
