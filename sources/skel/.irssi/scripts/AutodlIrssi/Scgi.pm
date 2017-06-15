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
# Send data to a SCGI server
# http://www.python.ca/scgi/protocol.txt
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Scgi;
use AutodlIrssi::Globals;
use AutodlIrssi::Socket;
use AutodlIrssi::DomainSocket;
use AutodlIrssi::InternetUtils;

# addr => ip:port or /path/to/socket
# scgiHeader => Extra SCGI header values
sub new {
	my ($class, $addr, $scgiHeader) = @_;
	bless {
		addr => $addr,
		scgiHeader => $scgiHeader || {},
	}, $class;
}

sub _message {
	my ($self, $level, $message) = @_;
	message $level, "SCGI: $message";
}

sub _dmessage {
	my ($self, $level, $message) = @_;
	dmessage $level, "SCGI: $message";
}

sub _callUser {
	my ($self, $errorMessage, $data) = @_;

	eval {
		my $callback = $self->{callback};
		delete $self->{callback};
		delete $self->{socket};
		delete $self->{data};
		$callback->($errorMessage, $data) if $callback;
	};
	if ($@) {
		chomp $@;
		message 0, "Scgi::_callUser: ex: $@";
	}
}

sub _getScgiData {
	my ($self, $userData) = @_;

	use bytes;

	my $header = "";

	# CONTENT_LENGTH must be first
	$header .= "CONTENT_LENGTH\000" . (length $userData) . "\000";
	$header .= "SCGI\0001\000";	# Required

	while (my ($key, $val) = each %{$self->{scgiHeader}}) {
		$header .= "$key\000$val\000";
	}

	return (length $header) . ":$header,$userData";
}

# Send data to the SCGI server
# data => The data to send
# callback(errorMessage, data) => Called when server has sent its response
sub send {
	my ($self, $data, $callback) = @_;

	die "Scgi::send: callback already set!\n" if $self->{callback};

	eval {
		$self->{callback} = $callback;
		$self->{data} = "";

		$self->_dmessage(5, "Connecting to $self->{addr}");
		if (isInternetAddress($self->{addr})) {
			my ($ip, $port) = $self->{addr} =~ /^(.+):(\d+)$/;
			$self->{socket} = new AutodlIrssi::Socket();
			$self->{socket}->connect($ip, $port, sub { $self->_onConnect(@_, $data) });
		}
		else {
			$self->{socket} = new AutodlIrssi::DomainSocket();
			$self->{socket}->connect($self->{addr}, sub { $self->_onConnect(@_, $data) });
		}
	};
	if ($@) {
		chomp $@;
		$self->_callUser("Scgi::send: ex: $@");
	}
}

sub _onConnect {
	my ($self, $errorMessage, $data) = @_;

	eval {
		if ($errorMessage) {
			$self->_dmessage(5, "Failed to connect!");
			return $self->_callUser("Could not connect: $errorMessage");
		}

		$self->_dmessage(5, "Connected. Now sending data.");
		$self->{socket}->write($self->_getScgiData($data), sub { $self->_onSendComplete(@_) });
	};
	if ($@) {
		chomp $@;
		$self->_callUser("Scgi::_onConnect: ex: $@");
	}
}

sub _onSendComplete {
	my ($self, $errorMessage) = @_;

	eval {
		if ($errorMessage) {
			$self->_dmessage(5, "Failed to send SCGI request");
			return $self->_callUser("Failed to send request: $errorMessage");
		}

		$self->{socket}->installReadHandler(sub { $self->_onReadAvailable(@_) });
	};
	if ($@) {
		chomp $@;
		$self->_callUser("Scgi::_onSendComplete: ex: $@");
	}
}

sub _onReadAvailable {
	my ($self, $errorMessage, $data) = @_;

	eval {
		if ($errorMessage) {
			$self->_dmessage(5, "Error reading data: $errorMessage");
			return $self->_callUser("Error reading data: $errorMessage");
		}

		if (length $data != 0) {
			use bytes;
			$self->{data} .= $data;
		}
		else {
			$self->_onAllDataReceived();
		}
	};
	if ($@) {
		chomp $@;
		$self->_callUser("Scgi::_onReadAvailable: ex: $@");
	}
}

sub _onAllDataReceived {
	my $self = shift;

	$self->{socket} = undef;

	eval {
		$self->_callUser("", $self->{data});
	};
	if ($@) {
		chomp $@;
		$self->_callUser("Scgi::_onAllDataReceived: ex: $@");
	}
}

1;
