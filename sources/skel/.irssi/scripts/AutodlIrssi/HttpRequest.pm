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
# Sends HTTP GET/POST requests
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Cookies;

sub new {
	my $class = shift;
	bless {
		cookies => {},
	}, $class;
}

sub add {
	my ($self, $name, $value) = @_;
	$self->{cookies}{$name} = $value;
}

sub toString {
	my $self = shift;

	my $rv = "";
	while (my ($name, $value) = each %{$self->{cookies}}) {
		$rv .= "; " if length $rv > 0;
		$rv .= "$name=$self->{cookies}{$name}";
	}
	return $rv;
}

package AutodlIrssi::HttpRequest;
use AutodlIrssi::Globals qw/ currentTime /;
use AutodlIrssi::TextUtils;
use AutodlIrssi::Socket;
use AutodlIrssi::SslSocket;
use AutodlIrssi::Irssi;
use Socket qw/ :crlf /;

sub new {
	my $class = shift;
	my $self = bless {
		socket => undef,
		userAgent => $AutodlIrssi::g->{options}{userAgent},
		follow3xxLocation => 0,
		numRedirects => 0,
	}, $class;
	$self->{connId} = $AutodlIrssi::g->{activeConnections}->add($self, "HTTP request");
	return $self;
}

sub DESTROY {
	my $self = shift;

	if (defined $self->{connId}) {
		$AutodlIrssi::g->{activeConnections}->remove($self->{connId});
	}
}

sub _message {
	my $self = shift;
	&AutodlIrssi::Globals::message;
}

sub _dmessage {
	my $self = shift;
	&AutodlIrssi::Globals::dmessage;
}

sub _callUser {
	my ($self, $errorMessage) = @_;

	$self->{socket} = undef;

	eval {
		if (defined $self->{callback}) {
			# To prevent memory leaks due to circular references, remove the callback now
			my $callback = $self->{callback};
			delete $self->{callback};
			$callback->($errorMessage);
		}
	};
	if ($@) {
		chomp $@;
		$self->_message(0, "HttpRequest::_callUser: $@");
	}
}

sub _requestFailed {
	my ($self, $errorMessage) = @_;
	$self->_callUser($errorMessage);
}

sub setFollowNewLocation {
	my $self = shift;
	$self->{follow3xxLocation} = 1;
}

# Send a HTTP request
#	$method		=> GET or POST
#	$methodData	=> "" for GET and POST data for POST
#	$url		=> Destination URL
#	$httpHeaders=> Hash reference of all HTTP headers
#	$callback	=> Called when HTTP request is complete
sub sendRequest {
	my ($self, $method, $methodData, $url, $httpHeaders, $callback) = @_;

	$self->{method} = uc $method;
	$self->{methodData} = $methodData;
	$self->{callback} = $callback;
	$self->{httpHeaders} = $httpHeaders;
	$self->{retryCount} = 0;
	$self->{requestStartTime} = currentTime();
	if (!$self->_splitUrl($url)) {
		return $self->_requestFailed("Invalid url: '$url'");
	}
	$self->_sendRequestInternal();
}

sub _splitUrl {
	my ($self, $url) = @_;

	$self->{url} = $url;

	return 0 unless $url =~ m!^(\w+)://([^/]+)(/.*)!;
	$self->{protocol} = $1;
	$self->{hostname} = $2;
	$self->{path} = $3;
	$self->{port} = $self->{protocol} eq "https" ? 443 : 80;

	if ($self->{hostname} =~ /([^:]+):(.+)/) {
		$self->{hostname} = $1;
		$self->{port} = $2;
	}
	return 1;
}

sub _getRetryTimeout {
	return 2000;
}

sub _retry {
	my ($self, $errorMessage) = @_;

	eval {
		my $elapsedTimeInSecs = currentTime() - $self->{requestStartTime};
		if ($elapsedTimeInSecs > $AutodlIrssi::g->{options}{maxDownloadRetryTimeSeconds}) {
			$self->_requestFailed("Timed out! Error: $errorMessage");
			return;
		}
		$self->{retryCount}++;
		$self->{retryErrorMessage} = $errorMessage;

		irssi_timeout_add_once($self->_getRetryTimeout(), sub {
			$self->_sendRequestInternal();
		}, undef);
	};
	if ($@) {
		chomp $@;
		$self->_requestFailed("_retry ex: $@");
	}
}

# Starts sending the HTTP request
sub _sendRequestInternal {
	my $self = shift;

	eval {
		$self->{data} = "";

		if ($self->{retryCount}) {
			$self->_message(4, "Retrying request ($self->{retryCount}) $self->{url}, error was: $self->{retryErrorMessage}");
		}

		if ($self->{protocol} eq "https") {
			$self->{socket} = new AutodlIrssi::SslSocket();
		}
		else {
			$self->{socket} = new AutodlIrssi::Socket();
		}

		$self->_dmessage(5, "Trying to connect: url: $self->{url}");
		$self->{socket}->connect($self->{hostname}, $self->{port}, sub { $self->_onConnect(@_) });
	};
	if ($@) {
		chomp $@;
		$self->_requestFailed("_sendRequestInternal ex: $@");
	}
}

# Called when we're connected or an error occurred during connect. It will send the HTTP request.
sub _onConnect {
	my ($self, $errorMessage) = @_;

	eval {
		if ($errorMessage) {
			$self->_dmessage(5, "Failed to connect: url: $self->{url}");
			$self->_retry("Could not connect. url: $self->{url}");
			return;
		}

		$self->_dmessage(5, "Now connected: url: $self->{url}");

		my $msg;
		{
			use bytes;	# Disable UTF-8 conversion since we may be sending binary data!
			$msg =
				"$self->{method} $self->{path} HTTP/1.1$CRLF" .
				"Host: $self->{hostname}$CRLF" .
				"User-Agent: $self->{userAgent}$CRLF" .
				"Accept: */*$CRLF" .
				"Connection: close$CRLF";
			while (my ($k, $v) = each %{$self->{httpHeaders}}) {
				$msg .= "$k: $v$CRLF";
			}
			if ($self->{methodData} ne "") {
				$msg .= "Content-Length: " . length($self->{methodData}) . $CRLF;
			}
			$msg .= $CRLF;

			if ($self->{methodData} ne "") {
				$msg .= $self->{methodData};
				$msg .= $CRLF;
			}
		}

		$self->_dmessage(5, "Sending HTTP headers:\n" . substr($msg, 0, 700));
		$self->{socket}->write($msg, sub { $self->_onSendComplete(@_) });
	};
	if ($@) {
		chomp $@;
		$self->_requestFailed("_onConnect ex: $@");
	}
}

# Called when we've sent the HTTP request. It will wait for data from the server.
sub _onSendComplete {
	my ($self, $errorMessage) = @_;

	eval {
		if ($errorMessage) {
			$self->_dmessage(5, "Failed to send HTTP request: url: $self->{url}");
			$self->_retry("Could not send. url: $self->{url}");
			return;
		}

		$self->{socket}->installReadHandler(sub { $self->_onReadAvailable(@_) });
	};
	if ($@) {
		chomp $@;
		$self->_requestFailed("_onSendComplete ex: $@");
	}
}

# Called when there's data to read from the server.
sub _onReadAvailable {
	my ($self, $errorMessage, $data) = @_;

	eval {
		die "Could not read: $errorMessage\n" if $errorMessage;
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
		$self->_requestFailed("_onReadAvailable ex: $@");
	}
}

# Called when all data has been received from the server
sub _onAllDataReceived {
	my $self = shift;

	$self->{socket} = undef;

	eval {
		if (!$self->_parseResponse()) {
			$self->_retry("Could not parse HTTP response header");
			return;
		}

		my $contentLength = $self->_getResponseHeader("content-length");
		if (defined $contentLength && $contentLength > length $self->{response}{content}) {
			$self->_retry("Missing bytes; expected $contentLength but got " . length $self->{response}{content});
			return;
		}

		my $transferEncoding = $self->_getResponseHeader("transfer-encoding");
		if (defined $transferEncoding) {
			if (lc $transferEncoding ne "chunked") {
				$self->_requestFailed("Invalid Transfer-Encoding: '$transferEncoding'");
				return;
			}
			if (!$self->_fixChunkedData()) {
				$self->_retry("Could not decode chunked HTTP data (did not receive all bytes?)");
				return;
			}
		}

		my $contentEncoding = $self->_getResponseHeader("content-encoding");
		if (defined $contentEncoding) {
			$self->_requestFailed("Invalid content encoding received: '$contentEncoding'");
			return;
		}

		if (substr($self->{response}{statusCode}, 0, 1) eq "3" && $self->{follow3xxLocation}) {
			return $self->_followNewLocation();
		}

		$self->_callUser("");
	};
	if ($@) {
		chomp $@;
		$self->_requestFailed("_onAllDataReceived ex: $@");
	}
}

sub _parseResponse {
	my $self = shift;

	my $endOfHeader = index $self->{data}, "$CRLF$CRLF";
	return 0 if $endOfHeader == -1;

	$self->{response} = {};
	$self->{response}{content} = substr $self->{data}, $endOfHeader + 4;

	$self->_dmessage(5, "HTTP response headers:\n" . substr($self->{data}, 0, $endOfHeader + 2));
	$self->_dmessage(5, "HTTP data:\n" . substr($self->{data}, $endOfHeader + 4, 700));

	my @headerStrings = substr($self->{data}, 0, $endOfHeader + 2) =~ /([^\x0D\x0A]+)\x0D\x0A/gm;
	return 0 unless @headerStrings;

	$self->{response}{status} = shift @headerStrings;
	return 0 unless $self->{response}{status} =~ /\S+\s+(\d+)/;
	$self->{response}{statusCode} = $1;

	$self->{response}{headers} = {};
	for my $headerLine (@headerStrings) {
		return 0 unless $headerLine =~ /([^:]+):\s*(.*)/;
		my $key = lc trim $1;
		my $value = trim $2;

		push @{$self->{response}{headers}{$key}}, $value;
	}

	return 1;
}

# Returns header value or undef if it doesn't exist
sub _getResponseHeader {
	my ($self, $name, $index) = @_;

	$index = 0 unless $index;
	my $ary = $self->{response}{headers}{lc $name};
	return unless $ary;
	return $ary->[$index];
}

# Fixes $self->{data} if we got Transfer-Encoding: chunked
sub _fixChunkedData {
	my $self = shift;

	my $chunkedData = $self->{response}{content};
	$self->{response}{content} = "";

	my $offset = 0;
	while (1) {
		my $eolIndex = index($chunkedData, $CRLF, $offset);
		return 0 if $eolIndex == -1;

		my $chunkSizeStr = trim substr($chunkedData, $offset, $eolIndex - $offset);
		$offset = $eolIndex + 2;
		my $chunkSize = hex($chunkSizeStr);
		return 0 if $chunkSize < 0 || sprintf("%x", $chunkSize) ne lc $chunkSizeStr;
		return 0 if $eolIndex + 2 + $chunkSize + 2 > length $chunkedData;

		$self->{response}{content} .= substr($chunkedData, $offset, $chunkSize);
		$offset += $chunkSize;

		return 0 if substr($chunkedData, $offset, 2) ne $CRLF;
		$offset += 2;

		last if $chunkSize == 0;
	}
	return 0 if $offset != length $chunkedData;
	return 1;
}

sub _followNewLocation {
	my $self = shift;

	$self->{numRedirects}++;
	if ($self->{numRedirects} >= 10) {
		return $self->_requestFailed("Too many HTTP redirects, aborting.");
	}

	my $url = $self->_getResponseHeader("location");
	unless (defined $url) {
		return $self->_requestFailed("HTTP $self->{response}{statusCode} without a Location header.");
	}

	my $cookies = $self->getCookiesFromResponseHeader()->toString();
	if (length $cookies > 0) {
		$self->{httpHeaders}{COOKIE} = $cookies;
	}
	else {
		delete $self->{httpHeaders}{COOKIE};
	}

	if (!$self->_splitUrl($url)) {
		return $self->_requestFailed("Invalid url: '$url'");
	}
	$self->_sendRequestInternal();
}

sub getCookiesFromResponseHeader {
	my $self = shift;

	my $cookies = new AutodlIrssi::Cookies();

	for (my $i = 0; ; $i++) {
		my $cookie = $self->_getResponseHeader("Set-Cookie", $i);
		last unless defined $cookie;
		next unless $cookie =~ /^\s*([^\s=]+)\s*=\s*([^\s;]+)/;

		$cookies->add($1, $2);
	}

	return $cookies;
}

# Get the response data
sub getResponseData {
	my $self = shift;
	return $self->{response}{content};
}

sub getResponseStatusCode {
	my $self = shift;
	return $self->{response}{statusCode};
}

sub getResponseStatusText {
	my $self = shift;
	return $self->{response}{status};
}

# Retry the download
sub retryRequest {
	my ($self, $reason, $callback) = @_;

	$reason ||= "retryRequest() called";
	$self->{callback} = $callback;
	$self->_retry($reason);
}

sub setUserAgent {
	my ($self, $userAgent) = @_;
	$self->{userAgent} = $userAgent;
}

# Cancel any request WITHOUT notifying the callback function
sub cancel {
	my $self = shift;

	$self->{callback} = undef;
	if (defined $self->{socket}) {
		$self->{socket}->close();
		$self->{socket} = undef;
	}
}

1;
