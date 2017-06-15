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
# Prints messages when we join/leave a supported IRC announce channel
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::ChannelMonitor;
use AutodlIrssi::Irssi;
use AutodlIrssi::Globals;
use AutodlIrssi::TextUtils;

sub new {
	my ($class, $trackerManager) = @_;
	my $self = bless {
		trackerManager => $trackerManager,
	}, $class;

	$self->_createSignalsTable();
	$self->_installHandlers();

	return $self;
}

sub cleanUp {
	my $self = shift;

	$self->_removeHandlers();

	$self->{signals} = undef;	# Required so the handlers aren't holding a ref to us
	$self->{trackerManager} = undef;
}

sub _createSignalsTable {
	my $self = shift;

	$self->{signals} = [
		["server disconnected", sub { $self->_onMessageDisconnect(@_) }],
		["message join", sub { $self->_onMessageJoin(@_) }],
		["message part", sub { $self->_onMessagePart(@_) }],
		["message kick", sub { $self->_onMessageKick(@_) }],
	];
}

sub _installHandlers {
	my $self = shift;

	$AutodlIrssi::g->{eventManager}->installHandlers($self->{signals});
}

sub _removeHandlers {
	my $self = shift;

	$AutodlIrssi::g->{eventManager}->removeHandlers($self->{signals});
}

# Returns the channel if it exists
sub _findChannel {
	my ($self, $serverName, $channelName) = @_;

	$serverName = canonicalizeServerName($serverName);
	$channelName = canonicalizeChannelName($channelName);

	for my $channel (irssi_channels()) {
		if ($channelName eq canonicalizeChannelName($channel->{name}) &&
			$serverName eq canonicalizeServerName($channel->{server}{address})) {
			return $channel;
		}
	}
	return;
}

sub _isMonitoredChannel {
	my ($self, $networkName, $serverName, $channelName) = @_;

	$channelName = canonicalizeChannelName($channelName);
	my @channels = $self->{trackerManager}->getChannels($networkName, $serverName);
	for my $name (@channels) {
		return 1 if $channelName eq canonicalizeChannelName($name);
	}
	return 0;
}

# Called when a server is disconnected
sub _onMessageDisconnect {
	my ($self, $server) = @_;

	eval {
		my $networkName = $server->isupport('NETWORK');
		my $serverName = $server->{address};
		my @channels = $self->{trackerManager}->getChannels($networkName, $serverName);

		for my $channelName (@channels) {
			next unless $self->_findChannel($serverName, $channelName);
			$self->_notMonitoringChannel($serverName, $channelName, "disconnected");
		}
	};
	if ($@) {
		chomp $@;
		message 0, "_onMessageDisconnect: ex: $@";
	}
}

# Called when we've joined a channel
sub _onMessageJoin {
	my ($self, $server, $channelName, $nick, $address) = @_;

	eval {
		my $networkName = $server->isupport('NETWORK');
		my $serverName = $server->{address};
		return unless $server->{nick} eq $nick;
		return unless $self->_isMonitoredChannel($networkName, $serverName, $channelName);
		$self->_monitoringChannel($serverName, $channelName, "/join");
	};
	if ($@) {
		chomp $@;
		message 0, "_onMessageJoin: ex: $@";
	}
}

# Called when we've parted a channel
sub _onMessagePart {
	my ($self, $server, $channelName, $nick, $address, $reason) = @_;

	eval {
		my $networkName = $server->isupport('NETWORK');
		my $serverName = $server->{address};
		return unless $server->{nick} eq $nick;
		return unless $self->_isMonitoredChannel($networkName, $serverName, $channelName);
		$self->_notMonitoringChannel($serverName, $channelName, "/part");
	};
	if ($@) {
		chomp $@;
		message 0, "_onMessagePart: ex: $@";
	}
}

# Called when we've been kicked out of a channel
sub _onMessageKick {
	my ($self, $server, $channelName, $nick, $kicker, $address, $reason) = @_;

	eval {
		my $networkName = $server->isupport('NETWORK');
		my $serverName = $server->{address};
		return unless $server->{nick} eq $nick;
		return unless $self->_isMonitoredChannel($networkName, $serverName, $channelName);
		$self->_notMonitoringChannel($serverName, $channelName, "/kick - $reason");
	};
	if ($@) {
		chomp $@;
		message 0, "_onMessageKick: ex: $@";
	}
}

sub _notMonitoringChannel {
	my ($self, $serverName, $channelName, $reason) = @_;

	my $msg = "$serverName: Not monitoring channel $channelName";
	$msg .= " ($reason)" if $reason;
	message 0, $msg;
}

sub _monitoringChannel {
	my ($self, $serverName, $channelName, $reason) = @_;

	my $msg = "$serverName: Monitoring channel $channelName";
	$msg .= " ($reason)" if $reason;
	message 3, $msg;
}

1;
