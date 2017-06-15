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
# SSL socket
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::SslSocket;
use base qw/ AutodlIrssi::SocketBase /;
use AutodlIrssi::Globals;
use Net::SSLeay qw//;

# Initialize OpenSSL
Net::SSLeay::load_error_strings();
Net::SSLeay::SSLeay_add_ssl_algorithms();
Net::SSLeay::randomize();

use constant SSL_MODE_ENABLE_PARTIAL_WRITE => 0x1;
$AutodlIrssi::g->{ssl_ctx} = Net::SSLeay::CTX_new() or die("Could not create SSL_CTX: $!\n");
Net::SSLeay::CTX_set_options($AutodlIrssi::g->{ssl_ctx}, Net::SSLeay::OP_ALL());
Net::SSLeay::CTX_set_mode($AutodlIrssi::g->{ssl_ctx},
		Net::SSLeay::CTX_get_mode($AutodlIrssi::g->{ssl_ctx}) | SSL_MODE_ENABLE_PARTIAL_WRITE);

sub DESTROY {
	my $self = shift;

	Net::SSLeay::free($self->{ssl}) if defined $self->{ssl};
	$self->SUPER::DESTROY();
}

sub _getSslError {
	my ($self, $res) = @_;
	return Net::SSLeay::get_error($self->{ssl}, $res);
}

# Install the handler as a read or write handler depending on the SSL error code. Will throw if
# the error is not WANT_READ or WANT_WRITE.
sub _sslInstallHandler {
	my ($self, $func, $res, $info) = @_;

	my $err = $self->_getSslError($res);
	if ($err == Net::SSLeay::ERROR_WANT_READ()) {
		$func->($self, 1, $info);
	}
	elsif ($err == Net::SSLeay::ERROR_WANT_WRITE()) {
		$func->($self, 0, $info);
	}
	else {
		die "SSL: Unknown error code: $err\n";
	}
}

# Connect to $hostname:$port
sub connect {
	my ($self, $hostname, $port, $callback) = @_;

	eval {
		$self->_createSocket();

		$self->{ssl} = Net::SSLeay::new($AutodlIrssi::g->{ssl_ctx}) or die "Could not create SSL\n";
		Net::SSLeay::set_fd($self->{ssl}, fileno($self->{socket}));
		Net::SSLeay::set_connect_state($self->{ssl});
		Net::SSLeay::set_tlsext_host_name($self->{ssl}, $hostname);

		$self->_startConnect($hostname, $port);
		$self->_installHandshakeHandler(0, $callback);
	};
	if ($@) {
		chomp $@;
		$self->_callUserShutdown($callback, $@);
	}
}

sub _installHandshakeHandler {
	my ($self, $isRead, $callback) = @_;

	$self->_installHandler($isRead, sub {
		my $error = shift;
		eval {
			die "$error\n" if $error;

			my $res = Net::SSLeay::do_handshake($self->{ssl});
			if ($res > 0) {
				$self->_nowConnected();
				$self->_callUser($callback, "");
				return;
			}

			$self->_sslInstallHandler(\&_installHandshakeHandler, $res, $callback);
		};
		if ($@) {
			chomp $@;
			$self->_callUserShutdown($callback, $@);
		}
	});
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

	my $res = Net::SSLeay::write($self->{ssl}, $data);
	if ($res > 0) {
		if ($res >= length $data) {
			$self->_callUser($writeInfo->{callback}, "");
			return;
		}

		$writeInfo->{data} = substr $data, $res;
		$self->_installWriteHandler(0, $writeInfo);
		return;
	}

	$self->_sslInstallHandler(\&_installWriteHandler, $res, $writeInfo);
}

sub _installWriteHandler {
	my ($self, $isRead, $writeInfo) = @_;

	$self->_installHandler($isRead, sub {
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
		my $len = Net::SSLeay::pending($self->{ssl}) || 2048;
		my $got = Net::SSLeay::read($self->{ssl}, $len);
		if (defined $got) {
			return unless $self->_callUser($readHandler, "", $got);
			return if length $got == 0;	# Stop if remote peer closed the connection
		}
		else {
			$self->_sslInstallHandler(\&_installReadHandler, -1, $readHandler);
			return;
		}
	}
}

sub _installReadHandler {
	my ($self, $isRead, $readHandler) = @_;

	$self->_installHandler($isRead, sub {
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
