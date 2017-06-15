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
# Create XML-RPC requests
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::XmlRpc;
use AutodlIrssi::Globals;
use AutodlIrssi::XmlRpcResponseParser;
use Encode qw/ encode_utf8 /;

sub new {
	my ($class, $writer) = @_;
	bless {
		writer => $writer,
		req => '<?xml version="1.0"?>',
	}, $class;
}

sub _addElems {
	my ($self, $string) = @_;
	use bytes;
	$self->{req} .= encode_utf8($string);
}

sub _addUserData {
	my ($self, $userData) = @_;
	$userData =~ s/[&]/&amp;/mg;
	$userData =~ s/[<]/&lt;/mg;
	$userData =~ s/[>]/&gt;/mg;
	use bytes;
	$self->{req} .= encode_utf8($userData);
}

sub _callUser {
	my ($self, $errorMessage, $data) = @_;

	eval {
		my $callback = $self->{callback};
		delete $self->{callback};
		$callback->($errorMessage, $data) if $callback;
	};
	if ($@) {
		chomp $@;
		message 0, "XmlRpc::_callUser: ex: $@";
	}
}

sub send {
	my ($self, $callback) = @_;

	die "XmlRpc::send: callback already set!\n" if $self->{callback};

	eval {
		$self->{callback} = $callback;
		$self->{writer}->send($self->{req}, sub { $self->_onDataReceived(@_) });
	};
	if ($@) {
		chomp $@;
		$self->_callUser("Scgi::send: ex: $@");
	}
}

sub _getXmlPart {
	my ($self, $data) = @_;

	my $i = index $data, "\x0D\x0A\x0D\x0A";
	return if $i < 0;
	return substr $data, $i + 4;
}

sub _parseResponse {
	my ($self, $data) = @_;

	die "Empty XML-RPC response\n" if length $data == 0;

	my $xmlData = $self->_getXmlPart($data);
	die "Invalid XML-RPC response\n" unless defined $xmlData;

	my $parser = new AutodlIrssi::XmlRpcResponseParser();
	return $parser->parse($xmlData);
}

sub _onDataReceived {
	my ($self, $errorMessage, $data) = @_;

	eval {
		if ($errorMessage) {
			$self->_callUser("Failed to send XML-RPC data: $errorMessage");
			return;
		}

		my $response = $self->_parseResponse($data);
		if (defined $response->{errorCode}) {
			$self->_callUser("XML-RPC call failed ($response->{errorCode}): $response->{errorString}");
			return;
		}

		$self->_callUser("", $response->{value});
	};
	if ($@) {
		chomp $@;
		$self->_callUser("XmlRpc::_onDataReceived: $@");
	}
}

1;
