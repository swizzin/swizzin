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
# Listens for connections and notifies a callback
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::ServerSocket;
use base qw/ AutodlIrssi::SocketBase /;
use AutodlIrssi::Socket;
use AutodlIrssi::Globals;
use Socket;

sub cleanUp {
	my $self = shift;

	$self->setHandler();
	$self->setAddress('', 0);
}

# handler gets called for each new connection
sub setHandler {
	my ($self, $handler) = @_;
	$self->{handler} = $handler;
}

sub setAddress {
	my ($self, $address, $port) = @_;

	$self->{changingPort} = 1;
	$self->close("Changing port");
	$self->{changingPort} = 0;

	return if $port == 0;

	$self->_createSocket();
	setsockopt($self->{socket}, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or die "SO_REUSEADDR failed: $!\n";
	my $sockaddr_in = AutodlIrssi::SocketBase::_createSockaddrIn($address, $port);
	bind($self->{socket}, $sockaddr_in) or die "Could not bind to port $port: $!\n";
	listen($self->{socket}, SOMAXCONN) or die "Could not listen(): $!\n";

	$self->_installListenHandler();
}

sub _installListenHandler {
	my $self = shift;

	$self->_installHandler(1, sub {
		$self->_onNewConnection(@_);
	});
}

sub _onNewConnection {
	my ($self, $error) = @_;

	eval {
		return if $self->{changingPort};

		if ($error) {
			message 0, "Server socket: Error: $error";
			$self->_installListenHandler();
		}
		else {
			my $addr = accept(my $newSock, $self->{socket});
			$self->_installListenHandler();
			die "accept() failed: $!\n" unless $addr;

			my ($port, $address) = sockaddr_in($addr);
			$address = inet_ntoa($address);

			my $socket = new AutodlIrssi::Socket();
			$socket->setSocket($newSock);
			$newSock = undef;

			if ($self->{handler}) {
				$self->{handler}->($socket, $address, $port);
			}
		}
	};
	if ($@) {
		chomp $@;
		message 0, "Server socket: Error: $@";
	}
}

1;
