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

# Saves autodl-irssi messages in a buffer for the ruTorrent plugin

use 5.008;
use strict;
use warnings;

package AutodlIrssi::MessageBuffer;
use AutodlIrssi::Globals;
use Encode;

use constant {
	# Keep startup messages this long
	KEEP_STARTUP_MESSAGES_SECS => 10,

	# Check for and remove old buffers this often
	REMOVE_OLD_BUFFERS_EVERY_SECS => 30,

	# Keep the buffer in memory at most this many secs
	MAX_BUFFER_AGE_SECS => 2*60,
};

sub new {
	my $class = shift;

	my $currentTime = time();
	bless {
		timeStarted => $currentTime,
		startupMessages => [],
		buffers => {},
		nextId => int(rand(0x7FFFFFFF)),
		lastRemoveCheck => $currentTime,
	}, $class;
}

sub cleanUp {
	my $self = shift;
}

sub onMessage {
	my ($self, $message) = @_;

	eval {
		my $currentTime = time();
		my $elem = {
			line => encode_utf8($message),
			time => $currentTime,
		};
		if ($currentTime - $self->{timeStarted} <= KEEP_STARTUP_MESSAGES_SECS) {
			push @{$self->{startupMessages}}, $elem;
		}
		while (my ($cid, $buffer) = each %{$self->{buffers}}) {
			push @{$buffer->{lines}}, $elem;
		}
	};
	if ($@) {
		# Do nothing. Can't call message() since it'll call us
	}
}

sub secondTimer {
	my $self = shift;

	eval {
		my $currentTime = time();
		if ($currentTime - $self->{timeStarted} > KEEP_STARTUP_MESSAGES_SECS) {
			$self->{startupMessages} = [];
		}
		if ($currentTime - $self->{lastRemoveCheck} > REMOVE_OLD_BUFFERS_EVERY_SECS) {
			$self->{lastRemoveCheck} = $currentTime;
			$self->_removeOldBuffers();
		}
	};
	if ($@) {
		chomp $@;
		message 0, "MessageBuffer::secondTimer: ex: $@";
	}
}

sub getBuffer {
	my ($self, $cid) = @_;

	if (!defined $cid || $cid !~ /^\d+$/) {
		$cid = $self->{nextId}++;
	}
	my $buffer = $self->{buffers}{$cid};
	if (!$buffer) {
		$cid = $self->{nextId}++;
		$self->{buffers}{$cid} = $buffer = {
			lines => [@{$self->{startupMessages}}],
		};
	}
	$buffer->{lastAccess} = time();

	my $rv = {
		lines => $buffer->{lines},
		cid => $cid,
	};
	$buffer->{lines} = [];
	return $rv;
}

sub _removeOldBuffers {
	my $self = shift;

	my $currentTime = time();
	while (my ($cid, $buffer) = each %{$self->{buffers}}) {
		next if $currentTime - $buffer->{lastAccess} < MAX_BUFFER_AGE_SECS;
		delete $self->{buffers}{$cid};
	}
}

1;
