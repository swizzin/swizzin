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
# Loaded by autodl-irssi.pl, and this is where all the startup code is.
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi;
use AutodlIrssi::Irssi;
use AutodlIrssi::Constants;
use AutodlIrssi::Globals;
use AutodlIrssi::Dirs;
use AutodlIrssi::FileUtils;
use AutodlIrssi::TrackerManager;
use AutodlIrssi::AutodlConfigFileParser;
use AutodlIrssi::DownloadHistory;
use AutodlIrssi::FilterManager;
use AutodlIrssi::IrcHandler;
use AutodlIrssi::TempFiles;
use AutodlIrssi::ActiveConnections;
use AutodlIrssi::ChannelMonitor;
use AutodlIrssi::Updater;
use AutodlIrssi::AutodlState;
use AutodlIrssi::GuiServer;
use AutodlIrssi::AutoConnector;
use AutodlIrssi::MessageBuffer;
use AutodlIrssi::EventManager;
use Net::SSLeay qw//;

#
# How often we'll check which IRC announcers haven't announced anything for a long time. Default is
# 10 mins.
#
use constant CHECK_BROKEN_ANNOUNCERS_SECS => 10*60;

#
# How often we'll check for updates to autodl-irssi and *.tracker files. Default is 24 hours.
#
use constant CHECK_FOR_UPDATES_SECS => 60*60*24;

#
# Wait at most this many seconds before closing the connection. Default is 10 mins.
#
use constant MAX_CONNECTION_WAIT_SECS => 10*60;

#
# How often we'll update the AutodlState.xml file. Default is 1 min.
#
use constant UPDATE_AUTODL_STATE_SECS => 60;

my $version = '1.62';
my $trackersVersion = '0';

# Called when we're enabled
sub enable {
	$AutodlIrssi::g->{messageBuffer} = new AutodlIrssi::MessageBuffer();

	createDirectories(getAutodlSettingsDir());

	message 0, "Missing configuration file: " . getAutodlCfgFile() unless -f getAutodlCfgFile();

	my $autodlState = readAutodlState();
	$trackersVersion = $autodlState->{trackersVersion};

	printVersionInfo();

	my $autodlCmd = {
		update => sub { manualCheckForUpdates() },
		whatsnew => sub { showWhatsNew() },
		version => sub { printVersionInfo() },
		reload => sub { irssi_command('script load autodl-irssi') },
		reloadtrackers => sub { reloadTrackerFiles() },
	};

	$AutodlIrssi::g->{eventManager} = new AutodlIrssi::EventManager();
	$AutodlIrssi::g->{trackerManager} = new AutodlIrssi::TrackerManager($autodlState->{trackerStates});
	$AutodlIrssi::g->{downloadHistory} = new AutodlIrssi::DownloadHistory(getDownloadHistoryFile());
	$AutodlIrssi::g->{filterManager} = new AutodlIrssi::FilterManager($autodlState->{filterStates});
	$AutodlIrssi::g->{tempFiles} = new AutodlIrssi::TempFiles();
	$AutodlIrssi::g->{activeConnections} = new AutodlIrssi::ActiveConnections();
	$AutodlIrssi::g->{channelMonitor} = new AutodlIrssi::ChannelMonitor($AutodlIrssi::g->{trackerManager});
	$AutodlIrssi::g->{autoConnector} = new AutodlIrssi::AutoConnector();
	$AutodlIrssi::g->{guiServer} = new AutodlIrssi::GuiServer($autodlCmd);

	reloadTrackerFiles();
	reloadAutodlConfigFile();
	readDownloadHistoryFile();

	$AutodlIrssi::g->{ircHandler} = new AutodlIrssi::IrcHandler($AutodlIrssi::g->{trackerManager},
																$AutodlIrssi::g->{filterManager},
																$AutodlIrssi::g->{downloadHistory});

	irssi_command_bind('autodl', \&command_autodl);

	irssi_timeout_add(1000, \&secondTimer, undef);
}

# Called when we're disabled
sub disable {
	eval {
		message 3, "\x02autodl-irssi\x02 \x02v$version\x02 is now disabled! ;-(";

		saveAutodlState();
		$AutodlIrssi::g->{tempFiles}->deleteAll() if $AutodlIrssi::g->{tempFiles};

		# Free the SSL_CTX created by SslSocket
		if (defined $AutodlIrssi::g->{ssl_ctx}) {
			Net::SSLeay::CTX_free($AutodlIrssi::g->{ssl_ctx});
		}

		$AutodlIrssi::g->{ircHandler}->cleanUp() if $AutodlIrssi::g->{ircHandler};
		$AutodlIrssi::g->{guiServer}->cleanUp() if $AutodlIrssi::g->{guiServer};
		$AutodlIrssi::g->{autoConnector}->cleanUp() if $AutodlIrssi::g->{autoConnector};
		$AutodlIrssi::g->{channelMonitor}->cleanUp() if $AutodlIrssi::g->{channelMonitor};
		$AutodlIrssi::g->{activeConnections}->cleanUp() if $AutodlIrssi::g->{activeConnections};
		$AutodlIrssi::g->{tempFiles}->cleanUp() if $AutodlIrssi::g->{tempFiles};
		$AutodlIrssi::g->{filterManager}->cleanUp() if $AutodlIrssi::g->{filterManager};
		$AutodlIrssi::g->{downloadHistory}->cleanUp() if $AutodlIrssi::g->{downloadHistory};
		$AutodlIrssi::g->{trackerManager}->cleanUp() if $AutodlIrssi::g->{trackerManager};
		$AutodlIrssi::g->{eventManager}->cleanUp() if $AutodlIrssi::g->{eventManager};
		$AutodlIrssi::g->{messageBuffer}->cleanUp() if $AutodlIrssi::g->{messageBuffer};
	};
	if ($@) {
		chomp $@;
		message 0, "disable: ex: $@";
	}
}

sub readAutodlState {

	my $autodlState = {
		trackersVersion => '0',
		trackerStates => {},
		filterStates => {},
	};

	eval {
		$autodlState = AutodlIrssi::AutodlState->new()->read(getAutodlStateFile());
	};
	if ($@) {
		chomp $@;
		message 0, "Could not read AutodlState.xml: ex: $@";
	}

	return $autodlState;
}

sub saveAutodlState {
	eval {
		my $autodlState = {
			trackersVersion => $trackersVersion,
			trackerStates => $AutodlIrssi::g->{trackerManager}->getTrackerStates(),
			filterStates => $AutodlIrssi::g->{filterManager}->getFilterStates(),
		};
		AutodlIrssi::AutodlState->new()->write(getAutodlStateFile(), $autodlState);
	};
	if ($@) {
		chomp $@;
		message 0, "Could not save AutodlState.xml: ex: $@";
	}
}

sub command_autodl {
	my ($data, $server, $witem) = @_;

	eval {
		if ($data =~ /^\s*update\s*$/i) {
			manualCheckForUpdates();
		}
		elsif ($data =~ /^\s*whatsnew\s*$/i) {
			showWhatsNew();
		}
		elsif ($data =~ /^\s*version\s*$/i) {
			printVersionInfo();
		}
		elsif ($data =~ /^\s*dumpvars\s*(\S+)\s*$/i) {
			dumpTrackerVars($1);
		}
		elsif ($data =~ /^\s*reload\s*$/i) {
			irssi_command('script load autodl-irssi');
		}
		elsif ($data =~ /^\s*reloadtrackers\s*$/i) {
			reloadTrackerFiles();
		}
		else {
			message 0, "Usage:";
			message 0, "    /autodl update";
			message 0, "    /autodl whatsnew";
			message 0, "    /autodl version";
			message 0, "    /autodl reload";
			message 0, "    /autodl reloadtrackers";
			message 0, "    /autodl dumpvars tracker-type";
		}
	};
	if ($@) {
		chomp $@;
		message 0, "command_autodl: ex: $@";
	}
}

sub manualCheckForUpdates {
	manualCheckForAutodlUpdates();
	manualCheckForTrackersUpdates();
}

sub showWhatsNew {
	showAutodlWhatsNew();
	showTrackersWhatsNew();
}

sub printVersionInfo {
	message 3, "You are running \x02autodl-irssi\x02 \x02v$version\x02 | \x02autodl-trackers\x02 \x02v$trackersVersion\x02";
	message 3, "\x02\x0309Bugs and Requests\x03\x02 \x02https://github.com/autodl-community/autodl-irssi/issues\x02";
	message 3, "\x02\x0309Help and Discussion\x03\x02 \x02#autodl-community on irc.p2p-network.net\x02";
}

sub dumpTrackerVars {
	my $type = shift;

	my $announceParser = $AutodlIrssi::g->{trackerManager}->findAnnounceParserFromType($type);
	if (!$announceParser) {
		message 0, "Unknown tracker type $type";
		return;
	}

	message 3, "Tracker options ($type):";
	my $options = $announceParser->{options};
	while (my ($name, $value) = each %$options) {
		message 3, "    $name: '$value'";
	}
}

sub readDownloadHistoryFile {
	eval {
		$AutodlIrssi::g->{downloadHistory}->loadHistoryFile();
	};
	if ($@) {
		message 0, "Error when reading download history file: " . formatException($@);
	}
	else {
		my $numLoaded = $AutodlIrssi::g->{downloadHistory}->getNumFiles();
		message 3, "Loaded \x02" . $numLoaded . "\x02 release" . ($numLoaded == 1 ? "" : "s") . " from history file.";
	}
}

sub reloadTrackerFiles {
	eval {
		$AutodlIrssi::g->{trackerManager}->reloadTrackerFiles(getTrackerFilesDir());
	};
	if ($@) {
		message 0, "Error when reading tracker files: " . formatException($@);
	}
	else {
		message 3, "Successfully loaded tracker files";
	}
}

my %autodlCfgFiles = (
	autodl => {
		filename => getAutodlCfgFile(),
		mtime => undef,
	},
	autodl2 => {
		filename => getAutodl2CfgFile,
		mtime => undef,
	},
	etc => {
		filename => getEtcAutodlCfgFile(),
		mtime => undef,
	},
);

sub checkReloadFile {
	my $fileInfo = shift;

	return 0 unless -f $fileInfo->{filename};

	my $reload = 0;
	if (!defined $fileInfo->{mtime}) {
		$reload = 1;
	}
	else {
		my $newTime = (stat $fileInfo->{filename})[9];	# Get mtime
		$reload = 1 if $newTime > $fileInfo->{mtime};
	}

	if ($reload) {
		$fileInfo->{mtime} = (stat $fileInfo->{filename})[9];	# Get mtime
	}
	return $reload;
}

sub parseConfigFile {
	my ($fileInfo, $trackerManager) = @_;

	return unless -f $fileInfo->{filename};

	my $configFileParser = new AutodlIrssi::AutodlConfigFileParser($trackerManager);
	$configFileParser->parse($fileInfo->{filename});
	return $configFileParser;
}

sub reloadAutodlConfigFile {

	eval {
		my $reloadAutodl = checkReloadFile($autodlCfgFiles{autodl});
		my $reloadAutodl2 = checkReloadFile($autodlCfgFiles{autodl2});
		my $reloadEtcAutodl = checkReloadFile($autodlCfgFiles{etc});

		# Always read in this order: autodl.cfg, autodl2.cfg, /etc/autodl.cfg
		$reloadAutodl2 = $reloadEtcAutodl = 1 if $reloadAutodl;
		$reloadEtcAutodl = 1 if $reloadAutodl2;

		return unless $reloadAutodl || $reloadAutodl2 || $reloadEtcAutodl;

		message 3, "Reading configuration files";

		my $configFileParser;
		my $servers;
		if ($reloadAutodl) {
			$configFileParser = parseConfigFile($autodlCfgFiles{autodl}, $AutodlIrssi::g->{trackerManager});

			$AutodlIrssi::g->{filterManager}->setFilters($configFileParser->getFilters());
			$AutodlIrssi::g->{options} = $configFileParser->getOptions();
			$AutodlIrssi::g->{options}{rtAddress} = "";	# It's not allowed in autodl.cfg
			$servers = $configFileParser->getServers();
		}

		if ($reloadAutodl2) {
			$configFileParser = parseConfigFile($autodlCfgFiles{autodl2});

			if ($configFileParser) {
				my $options = $configFileParser->getOptions();
				$AutodlIrssi::g->{options}{guiServerPort} = $options->{guiServerPort} if $options->{guiServerPort} != 0;
				$AutodlIrssi::g->{options}{guiServerPassword} = $options->{guiServerPassword} if $options->{guiServerPassword} ne "";
				$AutodlIrssi::g->{options}{rtAddress} = $options->{rtAddress} if $options->{rtAddress} ne "";
			}
		}

		if ($reloadEtcAutodl) {
			$configFileParser = parseConfigFile($autodlCfgFiles{etc});

			if ($configFileParser) {
				my $options = $configFileParser->getOptions();
				$AutodlIrssi::g->{options}{allowed} = $options->{allowed} if $options->{allowed} ne "";
			}
		}

		$AutodlIrssi::g->{guiServer}->setListenPort($AutodlIrssi::g->{options}{guiServerPort});

		if ($AutodlIrssi::g->{options}{irc}{autoConnect}) {
			$AutodlIrssi::g->{autoConnector}->setNames();
			$AutodlIrssi::g->{autoConnector}->setServers($servers) if defined $servers;
		}
		else {
			$AutodlIrssi::g->{autoConnector}->disable();
		}

		message 3, "Configuration files loaded";
	};
	if ($@) {
		chomp $@;
		message 0, "Error when reading the config file: $@";
	}
}

# It's called once every second by Irssi
sub secondTimer {
	eval {
		$AutodlIrssi::g->{tempFiles}->deleteOld();
		reloadAutodlConfigFile();
		activeConnectionsCheck();
		reportBrokenAnnouncers();
		updateAutodlState();
		$AutodlIrssi::g->{messageBuffer}->secondTimer();
		checkForAutodlUpdates();
		checkForTrackersUpdates();
	};
	if ($@) {
		message 0, "secondTimer: ex: " . formatException($@);
	}
}

{
	my $counter = 0;
	sub activeConnectionsCheck {
		return unless ++$counter >= 60;
		$counter = 0;
		$AutodlIrssi::g->{activeConnections}->reportMemoryLeaks();
	}
}

{
	my $counter = 0;
	sub reportBrokenAnnouncers {
		return unless ++$counter >= CHECK_BROKEN_ANNOUNCERS_SECS;
		$counter = 0;

		eval {
			my $channels = getActiveAnnounceParserTypes();
			$AutodlIrssi::g->{trackerManager}->reportBrokenAnnouncers($channels);
		};
		if ($@) {
			chomp $@;
			message 0, "reportBrokenAnnouncers: ex: $@";
		}
	}
}

{
	my $counter = 0;
	sub updateAutodlState {
		return unless ++$counter >= UPDATE_AUTODL_STATE_SECS;
		$counter = 0;

		eval {
			saveAutodlState();
		};
		if ($@) {
			chomp $@;
			message 0, "updateAutodlState: ex: $@";
		}
	}
}

# Returns an array ref of all monitored channels we've joined
sub getActiveAnnounceParserTypes {
	my $hash = {map {
		if ($_->{joined}) {
			my $networkName = $_->{server}->isupport('NETWORK');
			my $serverName = $_->{server}{address};
			my $channelName = $_->{name};
			my $announceParser = $AutodlIrssi::g->{trackerManager}->getAnnounceParserFromChannel($networkName, $serverName, $channelName);
			$announceParser ? ($announceParser->getTrackerInfo()->{type}, undef) : ();
		}
		else {
			()
		}
	} irssi_channels()};
	return [keys %$hash];
}

{
	my $autodlUpdater;
	my $lastUpdateCheck;
	my $updateCheck;

	sub checkForAutodlUpdates {
		eval {
			my $elapsedSecs = defined $lastUpdateCheck ? time - $lastUpdateCheck : -1;
			if ($elapsedSecs >= MAX_CONNECTION_WAIT_SECS && defined $autodlUpdater && $autodlUpdater->isSendingRequest()) {
				cancelCheckForUpdates("Stuck connection!");
				return;
			}
			return if $elapsedSecs >= 0 && $elapsedSecs < CHECK_FOR_UPDATES_SECS;
			$updateCheck = $AutodlIrssi::g->{options}{updateCheck} || 'ask';
			_checkForAutodlUpdates();
		};
		if ($@) {
			chomp $@;
			message 0, "checkForAutodlUpdates: ex: $@";
		}
	}

	sub manualCheckForAutodlUpdates {
		eval {
			$updateCheck = 'manual';
			_checkForAutodlUpdates();
		};
		if ($@) {
			chomp $@;
			message 0, "manualCheckForAutodlUpdates: ex: $@";
		}
	}

	sub showAutodlWhatsNew {
		eval {
			$updateCheck = 'whatsnew';
			_checkForAutodlUpdates();
		};
		if ($@) {
			chomp $@;
			message 0, "showAutodlWhatsNew: ex: $@";
		}
	}

	sub updateAutodlFailed {
		my $errorMessage = shift;
		$autodlUpdater = undef;
		message 0, $errorMessage;
	}

	sub cancelCheckForAutodlUpdates {
		my $errorMessage = shift;

		$errorMessage ||= "Cancelling update!";
		return unless defined $autodlUpdater;

		$autodlUpdater->cancel($errorMessage);
		$autodlUpdater = undef;
	}

	sub _checkForAutodlUpdates {
		cancelCheckForAutodlUpdates('Update autodl check cancelled!');
		message 5, "Checking for autodl updates...";
		$lastUpdateCheck = time;
		$autodlUpdater = new AutodlIrssi::Updater();
		$autodlUpdater->checkAutodlUpdate(\&onAutodlUpdateDataDownloaded);
	}

	sub onAutodlUpdateDataDownloaded {
		my $errorMessage = shift;

		return updateAutodlFailed("Could not check for autodl updates: $errorMessage") if $errorMessage;
		message 5, "Downloaded autodl update data";

		my $autodlUpdateAvailable = $autodlUpdater->hasAutodlUpdate($version);
		my $updateAutodl = $autodlUpdateAvailable;

		if ($updateCheck eq 'manual') {
			if (!$autodlUpdateAvailable) {
				message 3, "\x0309You are using the latest\x03 \x02autodl-irssi\x02 \x02v$version\x02";
			}
		}
		elsif ($updateCheck eq 'auto') {
			# Nothing
		}
		elsif ($updateCheck eq 'ask') {
			if ($autodlUpdateAvailable) {
				message 3, "\x0309A new autodl version is available!\x03 Type \x02/autodl update\x02 to update or \x02/autodl whatsnew\x02.";
			}
			$updateAutodl = 0;
		}
		elsif ($updateCheck eq 'whatsnew') {
			if (!$autodlUpdateAvailable) {
				message 3, "\x0309You are using the latest\x03 \x02autodl-irssi\x02 \x02v$version\x02";
			}
			else {
				message 3, "\x0309Changes in\x03 \x02autodl-irssi\x02 \x02v$autodlUpdater->{autodl}{version}:\x02\n" . $autodlUpdater->getAutodlWhatsNew();
			}
			$updateAutodl = 0;
		}
		else {	# 'disabled' or unknown
			$updateAutodl = 0;
		}

		if ($updateAutodl) {
			message 3, "Downloading autodl update...";
			$autodlUpdater->updateAutodl(getIrssiScriptDir(), \&onUpdatedAutodl);
			return;
		}

		$autodlUpdater = undef;
	}

	sub onUpdatedAutodl {
		my $errorMessage = shift;

		$autodlUpdater = undef;
		return updateFailed("Could not update autodl-irssi: $errorMessage") if $errorMessage;

		message 3, "Reloading autodl-irssi...";
		message 3, "\x0309You are now using\x03 \x02autodl-irssi\x02 \x02v$version\x02";
		irssi_command('script load autodl-irssi');
	}
}

{
	my $trackersUpdater;
	my $lastUpdateCheck;
	my $updateCheck;

	sub checkForTrackersUpdates {
		eval {
			my $elapsedSecs = defined $lastUpdateCheck ? time - $lastUpdateCheck : -1;
			if ($elapsedSecs >= MAX_CONNECTION_WAIT_SECS && defined $trackersUpdater && $trackersUpdater->isSendingRequest()) {
				cancelCheckForUpdates("Stuck connection!");
				return;
			}
			return if $elapsedSecs >= 0 && $elapsedSecs < CHECK_FOR_UPDATES_SECS;
			$updateCheck = $AutodlIrssi::g->{options}{updateCheck} || 'ask';
			_checkForTrackersUpdates();
		};
		if ($@) {
			chomp $@;
			message 0, "checkForTrackersUpdates: ex: $@";
		}
	}

	sub manualCheckForTrackersUpdates {
		eval {
			$updateCheck = 'manual';
			_checkForTrackersUpdates();
		};
		if ($@) {
			chomp $@;
			message 0, "manualCheckForTrackersUpdates: ex: $@";
		}
	}

	sub showTrackersWhatsNew {
		eval {
			$updateCheck = 'whatsnew';
			_checkForTrackersUpdates();
		};
		if ($@) {
			chomp $@;
			message 0, "showTrackersWhatsNew: ex: $@";
		}
	}

	sub updateTrackersFailed {
		my $errorMessage = shift;
		$trackersUpdater = undef;
		message 0, $errorMessage;
	}

	sub cancelCheckForTrackersUpdates {
		my $errorMessage = shift;

		$errorMessage ||= "Cancelling update!";
		return unless defined $trackersUpdater;

		$trackersUpdater->cancel($errorMessage);
		$trackersUpdater = undef;
	}

	sub _checkForTrackersUpdates {
		cancelCheckForTrackersUpdates('Update trackers check cancelled!');
		message 5, "Checking for trackers updates...";
		$lastUpdateCheck = time;
		$trackersUpdater = undef;
		$trackersUpdater = new AutodlIrssi::Updater();
		$trackersUpdater->checkTrackersUpdate(\&onTrackersUpdateDataDownloaded);
	}

	sub onTrackersUpdateDataDownloaded {
		my $errorMessage = shift;

		return updateTrackersFailed("Could not check for trackers updates: $errorMessage") if $errorMessage;
		message 5, "Downloaded trackers update data";

		my $trackerUpdateAvailable = $trackersUpdater->hasTrackersUpdate($trackersVersion);
		my $updateTrackers = $trackerUpdateAvailable;

		if ($updateCheck eq 'manual') {
			if (!$trackerUpdateAvailable) {
				message 3, "\x0309You are using the latest\x03 \x02autodl-trackers\x02 \x02v$trackersVersion\x02";
			}
		}
		elsif ($updateCheck eq 'auto') {
			# Nothing
		}
		elsif ($updateCheck eq 'ask') {
			if ($trackerUpdateAvailable) {
				message 3, "\x0309A new trackers version is available!\x03 Type \x02/autodl update\x02 to update or \x02/autodl whatsnew\x02.";
			}
			$updateTrackers = 0;
		}
		elsif ($updateCheck eq 'whatsnew') {
			if (!$trackerUpdateAvailable) {
				message 3, "\x0309You are using the latest\x03 \x02autodl-trackers\x02 \x02v$trackersVersion\x02";
			}
			else {
				message 3, "\x0309Changes in\x03 \x02autodl-trackers\x02 \x02v$trackersUpdater->{trackers}{version}:\x02\n" . $trackersUpdater->getTrackersWhatsNew();
			}
			$updateTrackers = 0;
		}
		else {	# 'disabled' or unknown
			$updateTrackers = 0;
		}

		if ($updateCheck eq 'manual' || $updateCheck eq 'auto') {
			if ($trackerUpdateAvailable) {
				message 4, "Updating tracker files...";
				$trackersUpdater->updateTrackers(getTrackerFilesDir(), \&onUpdatedTrackers);
				return;
			}
		}

		$trackersUpdater = undef;
	}

	sub onUpdatedTrackers {
		my $errorMessage = shift;

		return updateFailed("Could not update trackers: $errorMessage") if $errorMessage;

		message 3, "Trackers updated";
		$trackersVersion = $trackersUpdater->getTrackersVersion();
		message 3, "\x0309You are now using\x03 \x02autodl-trackers\x02 \x02v$trackersVersion\x02";
		$trackersUpdater = undef;
		reloadTrackerFiles();
	}
}

1;
