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
# Base class of all sockets
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::SocketBase;
use AutodlIrssi::Globals;
use AutodlIrssi::Irssi;
use Socket;
use Fcntl;
use Irssi;

# Set file handle to non-blocking mode
sub _setNonblocking {
	my $fh = shift;

	my $flags = fcntl($fh, F_GETFL, 0) or die "fcntl(F_GETFL) failed: $!\n";
	$flags |= O_NONBLOCK;
	fcntl($fh, F_SETFL, $flags) or die "fcntl(F_SETFL) failed: $!\n";
}

# Sets autoflush on the file handle
sub _setAutoFlush {
	my $fh = shift;

	my $oldh = select($fh);
	$| = 1;
	select($oldh);
}

# Returns a reference to a sockaddr_in struct
sub _createSockaddrIn {
	my ($hostname, $port) = @_;

	my $addr = inet_aton($hostname) or die "Couldn't get address: $!\n";
	return sockaddr_in($port, $addr);
}

sub new {
	my $class = shift;
	bless {
		socket => undef,
		isConnected => 0,
		readq => {
			tag => undef,
			list => [],
			type => INPUT_READ(),
		},
		writeq => {
			tag => undef,
			list => [],
			type => INPUT_WRITE(),
		},
		hasReadHandler => 0,	# true when the user wants to read data
	}, $class;
}

sub DESTROY {
	my $self = shift;

	$self->_cleanUp("SocketBase::DESTROY called");

	if (defined $self->{connId}) {
		$AutodlIrssi::g->{activeConnections}->remove($self->{connId});
	}
}

sub _cleanUp {
	my ($self, $errorMessage) = @_;
	$errorMessage = "SocketBase::_cleanUp called" unless defined $errorMessage;

	$self->_removeAllHandlers($errorMessage);

	close $self->{socket} if defined $self->{socket};
	$self->{socket} = undef;
	$self->{isConnected} = 0;
}

sub _removeAllHandlers {
	my ($self, $errorMessage) = @_;

	$self->{hasReadHandler} = 0;

	$self->_emptyQueue($self->{readq}, $errorMessage);
	$self->_emptyQueue($self->{writeq}, $errorMessage);

	$self->_removeQueueTag($self->{readq});
	$self->_removeQueueTag($self->{writeq});
}

# Empty the queue by calling all callbacks with an error message
sub _emptyQueue {
	my ($self, $queue, $errorMessage) = @_;

	while (@{$queue->{list}}) {
		my $info = pop @{$queue->{list}};
		eval { $info->{func}->($errorMessage) };
	}
	$self->_removeQueueTag($queue);
}

# Remove all read and write handlers
sub removeAllHandlers {
	my ($self, $errorMessage) = @_;
	$self->_removeAllHandlers($errorMessage);
}

sub close {
	my ($self, $errorMessage) = @_;
	$self->_cleanUp($errorMessage);
}

# Initialize socket to non-blocking and auto flush
sub _initSocket {
	my $self = shift;
	_setNonblocking($self->{socket});
	_setAutoFlush($self->{socket});
}

# Creates a socket that is non-blocking and auto-flushable.
sub _createSocket {
	my $self = shift;

	die "Socket already created\n" if defined $self->{socket};

	socket($self->{socket}, AF_INET, SOCK_STREAM, getprotobyname('tcp'));
	$self->_initSocket();
}

# Creates a unix domain socket that is non-blocking and auto-flushable.
sub _domain_createSocket {
	my $self = shift;

	die "Socket already created\n" if defined $self->{socket};

	socket($self->{socket}, PF_UNIX, SOCK_STREAM, 0);
	$self->_initSocket();
}

sub setSocket {
	my ($self, $socket) = @_;

	die "Socket already created\n" if defined $self->{socket};

	$self->{socket} = $socket;
	$self->_initSocket();

	$self->_nowConnected();
}

# Calls connect() and returns if successful. Will throw if connect() reports an error other than
# EINPROGRESS.
sub _startConnect {
	my ($self, $hostname, $port) = @_;

	die "_startConnect() already called\n" if defined $self->{connId};
	$self->{connId} = $AutodlIrssi::g->{activeConnections}->add($self, "Address: $hostname:$port");

	my $sockaddr_in = _createSockaddrIn($hostname, $port);
	connect($self->{socket}, $sockaddr_in) or $!{EINPROGRESS} or die "Could not connect to $hostname:$port: $!\n";
}

# Same as _startConnect except for unix domain sockets
sub _domain_startConnect {
	my ($self, $socketPath) = @_;

	die "_domain_startConnect() already called\n" if defined $self->{connId};
	$self->{connId} = $AutodlIrssi::g->{activeConnections}->add($self, "Address: $socketPath");

	connect($self->{socket}, sockaddr_un($socketPath)) or $!{EINPROGRESS} or die "Could not connect to $socketPath: $!\n";
}

# Calls the user callback with the supplied arguments. If the user callback throws, we shut down.
# A true value is returned on success.
sub _callUser {
	my ($self, $callback, @args) = @_;

	eval {
		$callback->(@args);
	};
	if ($@) {
		chomp $@;
		message 0, "Socket: callback ex: $@";
		$self->_forceShutdown($@);
		return 0;
	}

	return 1;
}

# Calls user callback then shuts down
sub _callUserShutdown {
	my ($self, $callback, @args) = @_;

	eval {
		$self->_callUser($callback, @args);
		$self->_forceShutdown();
	};
	if ($@) {
		chomp $@;
		message 0, "_callUserShutdown: ex: $@";
	}
}

sub _forceShutdown {
	my ($self, $errorMessage) = @_;
	$self->_cleanUp($errorMessage);
}

# Should be called by the super class when we're connected.
sub _nowConnected {
	my $self = shift;
	$self->{isConnected} = 1;
}

sub _getQueue {
	my ($self, $isRead) = @_;
	return $isRead ? $self->{readq} : $self->{writeq};
}

sub _installHandler {
	my ($self, $isRead, $func) = @_;

	my $queue = $self->_getQueue($isRead);

	push @{$queue->{list}}, {
		func => $func,
	};
	unless (defined $queue->{tag}) {
		$queue->{tag} = irssi_input_add(fileno($self->{socket}), $queue->{type}, sub {
			$self->_queueReady($isRead);
		}, undef);
	}

	$queue = undef;
}

sub _getSocketError {
	my $self = shift;
	return "SOCKET_CLOSED" unless defined $self->{socket};
	my $packed = getsockopt($self->{socket}, SOL_SOCKET, SO_ERROR) or die "Could not get socket, error: $!\n";
	return unpack("I", $packed);
}

sub _queueReady {
	my ($self, $isRead) = @_;

	my $sockError = $self->_getSocketError();
	eval {
		die "Socket error: $sockError\n" if $sockError;

		my $queue = $self->_getQueue($isRead);

		my $info = pop @{$queue->{list}};
		if (@{$queue->{list}} == 0) {
			$self->_removeQueueTag($queue);
		}
		die "_queueReady($isRead) called when list is empty\n" unless defined $info;

		$info->{func}->();
	};
	if ($@) {
		chomp $@;
		$self->_forceShutdown($@);
	}
}

sub _removeQueueTag {
	my ($self, $queue) = @_;

	return unless defined $queue->{tag};
	irssi_input_remove($queue->{tag});
	$queue->{tag} = undef;
}

1;
