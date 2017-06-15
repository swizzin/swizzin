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
# Normal (non-SSL) socket
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Socket;
use base qw/ AutodlIrssi::SocketBase /;
use AutodlIrssi::Globals;

# Connect to $hostname:$port
sub connect {
	my ($self, $hostname, $port, $callback) = @_;

	eval {
		$self->_createSocket();
		$self->_startConnect($hostname, $port);
		$self->_installHandler(0, sub {
			my $error = shift;
			if ($error) {
				$self->_callUserShutdown($callback, $error);
			}
			else {
				$self->_nowConnected();
				$self->_callUser($callback, "");
			}
		});
	};
	if ($@) {
		chomp $@;
		$self->_callUserShutdown($callback, $@);
	}
}

# Write all data. $callback->($errorMessage) will be called later.
sub write {
	my ($self, $data, $callback) = @_;

	eval {
		die "Not connected\n" unless $self->{isConnected};

		my $writeInfo = {
			data => $data,
			callback => $callback,
		};
		$self->_doWrite($writeInfo);
	};
	if ($@) {
		chomp $@;
		$self->_callUserShutdown($callback, $@);
	}
}

sub _doWrite {
	my ($self, $writeInfo) = @_;

	use bytes;

	my $data = $writeInfo->{data};
	if (length $data == 0) {
		$self->_callUser($writeInfo->{callback}, "");
		return;
	}

	my $res = send $self->{socket}, $data, 0;
	if (defined $res) {
		if ($res >= length $data) {
			$self->_callUser($writeInfo->{callback}, "");
			return;
		}

		$writeInfo->{data} = substr $data, $res;
		$self->_installWriteHandler($writeInfo);
		return;
	}

	$self->_callUserShutdown($writeInfo->{callback}, "Socket write error: $!");
}

sub _installWriteHandler {
	my ($self, $writeInfo) = @_;

	$self->_installHandler(0, sub {
		my $error = shift;
		eval {
			die "$error\n" if $error;
			$self->_doWrite($writeInfo);
		};
		if ($@) {
			chomp $@;
			$self->_callUserShutdown($writeInfo->{callback}, $@);
		}
	});
}

# Install a read handler which will get called whenever there's data to read. The empty string
# will be passed to it when the remote peer closed the connection.
sub installReadHandler {
	my ($self, $readHandler) = @_;

	eval {
		die "Not connected\n" unless $self->{isConnected};

		$self->{hasReadHandler} = 1;
		$self->_doRead($readHandler);
	};
	if ($@) {
		chomp $@;
		$self->_callUserShutdown($readHandler, $@);
	}
}

sub _doRead {
	my ($self, $readHandler) = @_;

	while ($self->{hasReadHandler}) {
		my $len = 2048;
		my $got = "";
		my $res = recv $self->{socket}, $got, $len, 0;
		if (defined $res) {
			return unless $self->_callUser($readHandler, "", $got);
			return if length $got == 0;	# Stop if remote peer closed the connection
			next;
		}
		elsif ($!{EAGAIN}) {
			$self->_installReadHandler($readHandler);
			return;
		}
		else {
			$self->_callUserShutdown($readHandler, "Socket read error: $!");
			return;
		}
	}
}

sub _installReadHandler {
	my ($self, $readHandler) = @_;

	$self->_installHandler(1, sub {
		my $error = shift;
		eval {
			die "$error\n" if $error;
			$self->_doRead($readHandler);
		};
		if ($@) {
			chomp $@;
			$self->_callUserShutdown($readHandler, $@);
		}
	});
}

1;
