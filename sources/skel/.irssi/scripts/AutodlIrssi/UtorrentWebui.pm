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
# uTorrent Webui
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::UtorrentWebui;
use AutodlIrssi::Globals;
use AutodlIrssi::TextUtils;
use AutodlIrssi::InternetUtils;
use AutodlIrssi::HttpRequest;
use Socket qw/ :crlf /;

sub new {
	my ($class, $webuiSettings) = @_;

	my $self = bless {
		webuiSettings => $webuiSettings,
		commands => [],
	}, $class;
	$self->{connId} = $AutodlIrssi::g->{activeConnections}->add($self, "uTorrent webui");
	return $self;
}

sub DESTROY {
	my $self = shift;

	if (defined $self->{connId}) {
		$AutodlIrssi::g->{activeConnections}->remove($self->{connId});
	}
}

sub seemsValid {
	my $self = shift;
	return $self->{webuiSettings} && $self->{webuiSettings}{user} &&
			$self->{webuiSettings}{password} && $self->{webuiSettings}{hostname} &&
			0 < $self->{webuiSettings}{port} && $self->{webuiSettings}{port} <= 65535;
}

# Tries to find the token div: <div id="token">ABUNCHOFCHARSHERE</div>, returning the token or null
sub findToken {
	my ($self, $s) = @_;
	return unless $s =~ /<div[^>]*\s+id=['"]?token['"]?[^>]*>([^<]*)<\/div>/m;
	return $1;
}

sub isSendingCommands {
	return shift->{callback};
}

sub checkNotSendingCommands {
	my $self = shift;
	if ($self->isSendingCommands()) {
		die "UtorrentWebui: Can't add commands when we're sending commands.\n";
	}
}

sub addCommand {
	my ($self, $command) = @_;

	$self->checkNotSendingCommands();
	push @{$self->{commands}}, $command;
}

sub addListCommand {
	my ($self, $cacheId) = @_;

	my $command = {
		queries => [ "list=1" ],
	};
	push @{$command->{queries}}, "cid=$cacheId" if $cacheId;

	$self->addCommand($command);
}

sub addGetSettingsCommand {
	my $self = shift;
	$self->addCommand({
		queries => [ "action=getsettings" ],
	});
}

sub addSendTorrentCommand {
	my ($self, $torrentFileData, $torrentFilename) = @_;

	my $boundaryString = "---------------------------32853208516921";
	my $boundary = "--$boundaryString";
	my $postData;
	{
		use bytes;	# Disable UTF-8 conversion since we may be sending binary data!
		$postData = "$boundary$CRLF" .
					"Content-Disposition: form-data; name=\"torrent_file\"; filename=\"$torrentFilename\"$CRLF" .
					"Content-Type: application/x-bittorrent$CRLF" .
					"$CRLF" .
					"$torrentFileData$CRLF" .
					"$boundary--$CRLF";
	}

	$self->addCommand({
		queries => [ "action=add-file" ],
		postData => $postData,
		httpHeaders => { 'Content-Type' => "multipart/form-data; boundary=$boundaryString" },
	});
}

sub addSetPropsCommand {
	my ($self, $hash, $propName, $value) = @_;

	$self->addCommand({
		queries => [ "action=setprops", "hash=$hash", "s=" . toUrlEncode($propName), "v=" . toUrlEncode($value) ],
	});
}

sub addSetMaxUploadSpeedCommand {
	my ($self, $hash, $value) = @_;
	return $self->addSetPropsCommand($hash, "ulrate", $value);
}

sub addSetMaxDownloadSpeedCommand {
	my ($self, $hash, $value) = @_;
	return $self->addSetPropsCommand($hash, "dlrate", $value);
}

sub addSetLabelCommand {
	my ($self, $hash, $value) = @_;
	return $self->addSetPropsCommand($hash, "label", $value);
}

sub addStartCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=start", "hash=$hash" ],
	});
}

sub addStopCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=stop", "hash=$hash" ],
	});
}

sub addPauseCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=pause", "hash=$hash" ],
	});
}

sub addUnpauseCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=unpause", "hash=$hash" ],
	});
}

sub addForceStartCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=forcestart", "hash=$hash" ],
	});
}

sub addRecheckCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=recheck", "hash=$hash" ],
	});
}

sub addRemoveCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=remove", "hash=$hash" ],
	});
}

sub addRemoveDataCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=removedata", "hash=$hash" ],
	});
}

sub addQueueBottomCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=queuebottom", "hash=$hash" ],
	});
}

sub addQueueTopCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=queuetop", "hash=$hash" ],
	});
}

sub addQueueUpCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=queueup", "hash=$hash" ],
	});
}

sub addQueueDownCommand {
	my ($self, $hash) = @_;
	$self->addCommand({
		queries => [ "action=queuedown", "hash=$hash" ],
	});
}

# @param $callback	Function called when completed. Called as $callback->($errorMessage, $commandResults)
sub sendCommands {
	my ($self, $callback) = @_;

	$self->checkNotSendingCommands();

	$self->{callback} = $callback || sub {};
	eval {
		$self->{commandIndex} = -1;
		$self->{commandResults} = [];
		$self->nextCommand();
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.sendCommands: ex: " . formatException($@));
	}
}

sub nextCommand {
	my $self = shift;

	eval {
		$self->{gettingToken} = 0;
		$self->{commandIndex}++;
		if ($self->{commandIndex} >= @{$self->{commands}}) {
			return $self->sendCommandsCompleted("");
		}

		$self->sendNextCommand();
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.nextCommand: ex: " . formatException($@));
	}
}

sub sendNextCommand {
	my $self = shift;

	eval {
		my $command = $self->{commands}[$self->{commandIndex}];
		$self->sendHttpRequest($command, sub {
			$self->onHttpRequestSent(@_);
		});
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.sendNextCommand: ex: " . formatException($@));
	}
}

sub onHttpRequestSent {
	my ($self, $errorMessage) = @_;

	if ($errorMessage) {
		return $self->sendCommandsCompleted($errorMessage);
	}

	eval {
		my $statusCode = $self->{httpRequest}->getResponseStatusCode();
		if ($statusCode == 300 || $statusCode == 400) {
			return $self->getToken();
		}
		if ($statusCode == 401) {
			return $self->sendCommandsCompleted("Got HTTP 401. Check your webui user name and password!");
		}
		if ($statusCode != 200) {
			my $statusText = $self->{httpRequest}->getResponseStatusText();
			return $self->sendCommandsCompleted("Got HTTP error: $statusText.");
		}

		push @{$self->{commandResults}}, {
			json => decodeJson($self->{httpRequest}->getResponseData()),
		};

		$self->nextCommand();
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.onHttpRequestSent: ex: " . formatException($@));
	}
}

sub getWebuiUrl {
	my $self = shift;
	my $protocol = $self->{webuiSettings}{ssl} ? "https://" : "http://";
	return "$protocol$self->{webuiSettings}{hostname}:$self->{webuiSettings}{port}/gui/";
}

sub sendHttpRequest {
	my ($self, $command, $callback) = @_;

	eval {
		if (!$self->{webuiSettings}) {
			return $self->sendCommandsCompleted("Webui settings is null");
		}

		$self->{httpRequest} = new AutodlIrssi::HttpRequest();

		my $url = $self->getWebuiUrl();
		$url .= $command->{urlDir} if $command->{urlDir};

		if ($AutodlIrssi::g->{options}{webuiToken}) {
			$url = appendUrlQuery($url, "token=$AutodlIrssi::g->{options}{webuiToken}");
		}
		if ($command->{queries}) {
			for my $query (@{$command->{queries}}) {
				$url = appendUrlQuery($url, $query);
			}
		}

		my $httpHeaders = {
			Authorization => "Basic " . base64Encode("$self->{webuiSettings}{user}:$self->{webuiSettings}{password}")
		};
		if ($AutodlIrssi::g->{options}{webuiCookies} && $AutodlIrssi::g->{options}{webuiCookies}->toString()) {
			$httpHeaders->{Cookie} = $AutodlIrssi::g->{options}{webuiCookies}->toString();
		}
		if ($command->{httpHeaders}) {
			@$httpHeaders{keys %{$command->{httpHeaders}}} = values %{$command->{httpHeaders}};
		}

		my $ourCallback = sub { $callback->(@_) };
		if ($command->{postData}) {
			$self->{httpRequest}->sendRequest("POST", $command->{postData}, $url, $httpHeaders, $ourCallback);
		}
		else {
			$self->{httpRequest}->sendRequest("GET", "", $url, $httpHeaders, $ourCallback);
		}
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.sendHttpRequest: ex: " . formatException($@));
	}
}

sub getToken {
	my $self = shift;

	eval {
		if ($self->{gettingToken}) {
			return $self->sendCommandsCompleted("Could not get webui token. Enable Webui and check webui settings for typos!");
		}

		$AutodlIrssi::g->{options}{webuiToken} = undef;
		$AutodlIrssi::g->{options}{webuiCookies} = undef;

		$self->{gettingToken} = 1;
		my $command = {
			urlDir => "token.html",
			queries => [],
		};
		$self->sendHttpRequest($command, sub {
			$self->onHttpRequestToken(@_);
		});
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.getToken: ex: " . formatException($@));
	}
}

sub onHttpRequestToken {
	my ($self, $errorMessage) = @_;

	if ($errorMessage) {
		return $self->sendCommandsCompleted($errorMessage);
	}

	eval {
		if ($self->{httpRequest}->getResponseStatusCode() != 200) {
			my $statusText = $self->{httpRequest}->getResponseStatusText();
			return $self->sendCommandsCompleted("Got HTTP error: $statusText. Can't get token.");
		}

		$AutodlIrssi::g->{options}{webuiToken} = $self->findToken($self->{httpRequest}->getResponseData());
		$AutodlIrssi::g->{options}{webuiCookies} = $self->{httpRequest}->getCookiesFromResponseHeader();
		if (!$AutodlIrssi::g->{options}{webuiToken}) {
			return $self->sendCommandsCompleted("Could not get webui token.");
		}

		message(5, "Got new \x{03BC}Torrent webui token: $AutodlIrssi::g->{options}{webuiToken}, cookies: " . $AutodlIrssi::g->{options}{webuiCookies}->toString());
		$self->sendNextCommand();
	};
	if ($@) {
		$self->sendCommandsCompleted("UtorrentWebui.onHttpRequestToken: ex: " . formatException($@));
	}
}

sub sendCommandsCompleted {
	my ($self, $errorMessage) = @_;

	my $callback = $self->{callback};
	$self->{callback} = undef;
	my $commandResults = $self->{commandResults};
	$self->{commandResults} = undef;
	$self->{commands} = [];
	$self->{httpRequest} = undef;
	$self->{gettingToken} = 0;

	eval {
		$callback->($errorMessage, $commandResults);
	};
	if ($@) {
		message(0, "UtorrentWebui.sendCommandsCompleted: ex: " . formatException($@));
	}
}

1;
