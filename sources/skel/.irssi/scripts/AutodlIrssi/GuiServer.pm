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
# Serves files to the PHP code. The only files that can be read are the *.tracker files and the
# autodl.cfg file. autodl.cfg can also be written to.
#
# It listens on 127.0.0.1:gui-server-port
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::JsonSocket;
use AutodlIrssi::Irssi;
use AutodlIrssi::Globals;
use AutodlIrssi::InternetUtils qw/ decodeJson /;

#
# Max number of seconds with no activity before we close the connection.
#
use constant TIMEOUT_SECS => 60;

#
# Close the connection if data is greater than this size
#
use constant MAX_JSON_SIZE_BYTES => 512*1024;

sub new {
	my ($class, $socket) = @_;
	bless {
		socket => $socket,
		tag => undef,
	};
}

sub DESTROY {
	my $self = shift;

	$self->_removeTimeoutHandler();
}

sub _removeTimeoutHandler {
	my $self = shift;

	irssi_input_remove($self->{tag}) if defined $self->{tag};
	$self->{tag} = undef;
}

sub _installTimeoutHandler {
	my $self = shift;

	return if defined $self->{tag};

	$self->{lastActive} = time;
	$self->{tag} = irssi_timeout_add(5000, sub {
		eval {
			my $currTime = time;
			if ($currTime - $self->{lastActive} >= TIMEOUT_SECS) {
				dmessage 0, "JsonSocket: Aborting, timed out!";
				$self->_abort("JsonSocket: Timed out!");
			}
		};
		if ($@) {
			chomp $@;
			message 0, "JsonSocket: timeout: ex: $@";
		}
	}, undef);
}

sub _abort {
	my ($self, $errorMessage) = @_;

	$self->_removeTimeoutHandler();
	$self->{socket}->close($errorMessage || "JsonSocket: Unknown error");
}

sub waitForData {
	my ($self, $handler) = @_;

	$self->{isReading} = 1;
	$self->{data} = "";
	$self->{handler} = $handler;
	$self->_installTimeoutHandler();

	# Call this last since it may read data before it returns
	$self->{socket}->installReadHandler(sub { $self->_onRead(@_) });
}

sub writeData {
	my ($self, $data, $handler) = @_;

	$self->{lastActive} = time;
	$self->{handler} = $handler;
	$self->{socket}->write($data, sub {
		my $errorMessage = shift;
		$self->_callHandler($errorMessage);
	});
}

sub close {
	my $self = shift;
	$self->_abort("JsonSocket: close called");
}

sub _callHandler {
	my ($self, $errorMessage, $data) = @_;

	eval {
		my $handler = $self->{handler};
		$self->{handler} = undef;
		if (defined $handler) {
			$handler->($self, $errorMessage, $data);
		}
	};
	if ($@) {
		chomp $@;
		message 0, "JsonSocket: ex: $@";
	}
}

sub _onRead {
	my ($self, $errorMessage, $data) = @_;

	eval {
		return unless $self->{isReading};
		return $self->_callHandler($errorMessage) if $errorMessage;

		my $totalLen;
		{
			use bytes;
			$self->{data} .= $data;
			$self->{lastActive} = time;
			$totalLen = length $self->{data};
		}

		my $json = eval { decodeJson($self->{data}) };
		if (defined $json) {
			$self->{isReading} = 0;
			$self->{data} = "";
			$self->_callHandler("", $json);
		}
		elsif ($totalLen > MAX_JSON_SIZE_BYTES) {
			$self->_abort("Too much data");
			return;
		}
		elsif ($data eq "") {
			$self->_callHandler("Connection closed");
		}
	};
	if ($@) {
		chomp $@;
		$self->_callHandler("JsonSocket: ex: $@");
	}
}

package AutodlIrssi::GuiServer;
use AutodlIrssi::Globals;
use AutodlIrssi::InternetUtils qw/ encodeJson /;
use AutodlIrssi::ServerSocket;
use AutodlIrssi::Dirs;
use AutodlIrssi::FileUtils;
use AutodlIrssi::Irssi;
use AutodlIrssi::TextUtils;
use File::Glob qw/ :glob /;
use File::Basename;
use File::Spec;

# The address we listen for connections. Default is 127.0.0.1
use constant LISTEN_ADDRESS => '127.0.0.1';

sub new {
	my ($class, $autodlCmd) = @_;
	my $self = bless {
		port => 0,
		serverSocket => new AutodlIrssi::ServerSocket(),
		autodlCmd => $autodlCmd,
	}, $class;

	$self->{serverSocket}->setHandler(sub { $self->_onNewConnection(@_); });

	return $self;
}

sub cleanUp {
	my $self = shift;

	$self->{serverSocket}->cleanUp();
}

# If port is 0 or invalid, the server is disabled
sub setListenPort {
	my ($self, $port) = @_;

	eval {
		$port = 0 if $port < 0 || $port > 0xFFFF;
		return if $self->{port} == $port;

		my $address = LISTEN_ADDRESS;
		$self->{serverSocket}->setAddress($address, $port);
		$self->{port} = $port;

		if ($self->{port} != 0) {
			message 3, "GUI server listening on $address:$port";
		}
		else {
			message 3, "GUI server is disabled";
		}
		if ($AutodlIrssi::g->{options}{guiServerPassword} eq "") {
			message 0, "gui-server-password is blank or missing. All requests will be blocked!";
		}
	};
	if ($@) {
		chomp $@;
		my $errorMessage = $@;
		$self->{port} = 0;
		eval {
			$self->{serverSocket}->setAddress("", 0);
		};
		message 3, "GUI server disabled. Got error: $errorMessage";
	}
}

sub _onNewConnection {
	my ($self, $socket, $address, $port) = @_;

	my $jsonSocket = new AutodlIrssi::JsonSocket($socket);
	$jsonSocket->waitForData(sub { $self->_onJsonReceived(@_); });
}

my %handlers = (
	"getfiles"		=> \&_onCommandGetFiles,
	"getfile"		=> \&_onCommandGetFile,
	"writeconfig"	=> \&_onCommandWriteConfig,
	"getlines"		=> \&_onCommandGetLines,
	"command"		=> \&_onCommandCommand,
);

sub _verifyString {
	my ($self, $errorMessage, $val) = @_;

	die "$errorMessage\n" if !defined $val || ref $val;
	return $val;
}

sub _onJsonReceived {
	my ($self, $jsonSocket, $errorMessage, $json) = @_;

	if ($errorMessage) {
		message 4, "GuiServer: Error getting JSON data: $errorMessage";
		$jsonSocket->close();
		return;
	}

	eval {
		my $reply;
		eval {
			my $password = $self->_verifyString("Missing password", $json->{password});
			my $realPassword = $AutodlIrssi::g->{options}{guiServerPassword};
			die "Invalid password\n" if $realPassword eq "" || $password ne $realPassword;

			my $command = $self->_verifyString("Missing command", $json->{command});
			my $func = $handlers{$command};
			die "Invalid command '$command'. You need to update autodl-irssi.\n" unless $func;

			$reply = $func->($self, $json);
		};
		if ($@) {
			chomp $@;
			$reply = encodeJson({ error => "Error: $@" });
		}

		$jsonSocket->writeData($reply, sub {
			my ($jsonSocket, $errorMessage) = @_;

			$jsonSocket->close();
			message 0, "GuiServer: could not send data: $errorMessage" if $errorMessage;
		});
	};
	if ($@) {
		$jsonSocket->close();
	}
}

sub _isValidFilename {
	my ($self, $name) = @_;

	return scalar($name =~ /^[\w .\-]+$/);
}

# Returns a list of all files the client can read (all *.tracker files and autodl.cfg)
sub _onCommandGetFiles {
	my ($self, $json) = @_;

	my $data = {
		error => "",
	};

	my $trackerDir = getTrackerFilesDir();
	my @files = map { -s $_ ? $_ : () } bsd_glob("$trackerDir/*.tracker", GLOB_ERR | GLOB_NOSORT);
	push @files, getAutodlCfgFile();

	$data->{files} = [map { basename($_) } @files];

	return encodeJson($data);
}

# Returns a file. Must be autodl.cfg or one of the *.tracker files.
sub _onCommandGetFile {
	my ($self, $json) = @_;

	my $filename = $self->_verifyString("Missing filename", $json->{name});
	die "Bad filename\n" unless $self->_isValidFilename($filename);

	my $path;
	if ($filename =~ /\.tracker$/) {
		$path = File::Spec->catfile(getTrackerFilesDir(), $filename);
		die "File does not exist: $path\n" unless -f $path;
	}
	elsif ($filename eq 'autodl.cfg') {
		$path = getAutodlCfgFile();
	}
	else {
		die "Invalid filename\n";
	}

	my $data = {
		error => "",
	};

	my @stat = stat $path;
	if (@stat) {
		$data->{mtime} = $stat[9];
		$data->{data} = getFileData($path);
	}
	else {
		$data->{mtime} = 1000000000;
		$data->{data} = "";
	}

	return encodeJson($data);
}

# Saves the data to autodl.cfg
sub _onCommandWriteConfig {
	my ($self, $json) = @_;

	my $data = $self->_verifyString("Missing data", $json->{data});

	my $filename = getAutodlCfgFile();
	saveRawDataToFile($filename, $data);

	return encodeJson({ error => "" });
}

sub _onCommandGetLines {
	my ($self, $json) = @_;

	my $cid = $json->{cid};
	my $buffer = $AutodlIrssi::g->{messageBuffer}->getBuffer($cid);
	my $reply = {
		error => "",
		cid => $buffer->{cid},
		lines => $buffer->{lines},
	};
	return encodeJson($reply);
}

sub _onCommandCommand {
	my ($self, $json) = @_;

	my $data = {
		error => "",
	};

	my $type = $self->_verifyString("Unknown command type", $json->{type});
	if ($type eq 'autodl') {
		return $self->_doCommandAutodl($json);
	}
	elsif ($type eq 'irc') {
		return $self->_doCommandIrc($json);
	}
	else {
		die "Invalid command type\n";
	}
}

sub _doCommandAutodl {
	my ($self, $json) = @_;

	my $subcmd = $self->_verifyString("Unknown /autodl command", $json->{arg1});
	if ($subcmd eq 'update') {
		$self->{autodlCmd}{update}->();
	}
	elsif ($subcmd eq 'whatsnew') {
		$self->{autodlCmd}{whatsnew}->();
	}
	elsif ($subcmd eq 'version') {
		$self->{autodlCmd}{version}->();
	}
	elsif ($subcmd eq 'reload') {
		$self->{autodlCmd}{reload}->();
	}
	elsif ($subcmd eq 'reloadtrackers') {
		$self->{autodlCmd}{reloadtrackers}->();
	}
	else {
		die "Invalid /autodl command\n";
	}

	return encodeJson({ error => "" });
}

sub _doCommandIrc {
	my ($self, $json) = @_;

	my $subcmd = $self->_verifyString("Unknown irc command", $json->{arg1});
	if ($subcmd eq 'getservers') {
		return $self->_doCommandIrcGetServers($json);
	}
	elsif ($subcmd eq 'reconnect') {
		return $self->_doCommandIrcReconnect($json);
	}
	elsif ($subcmd eq 'part') {
		return $self->_doCommandIrcPart($json);
	}
	else {
		die "Invalid irc command\n";
	}
}

sub _doCommandIrcGetServers {
	my ($self, $json) = @_;

	my $servers = [];
	for my $server (irssi_servers()) {
		my $channels = [];
		my @serverChannels = eval { no warnings; return $server->channels(); };
		for my $channel (@serverChannels) {
			push @$channels, {
				name => $channel->{name},
				joined => $channel->{joined} ? 1 : 0,
			};
		}

		push @$servers, {
			tag => $server->{tag},
			network => $server->isupport('NETWORK') || "",
			name => $server->{address},
			port => $server->{port},
			state => "connected",
			nick => $server->{nick},
			channels => $channels,
		};
	}

	for my $reconnect (irssi_reconnects()) {
		push @$servers, {
			tag => "RECON-$reconnect->{tag}",
			network => "",
			name => $reconnect->{address},
			port => $reconnect->{port},
			state => "reconnect",
			nick => "",
			channels => [],
		};
	}

	return encodeJson({
		error => "",
		servers => $servers,
	});
}

sub _doCommandIrcReconnect {
	my ($self, $json) = @_;

	my $tag = $self->_verifyString("Missing server tag", $json->{arg2});

	if ($tag =~ /^RECON-(\d+)$/) {
		$tag = $1;
		for my $reconnect (irssi_reconnects()) {
			next unless $reconnect->{tag} eq $tag;

			irssi_command("reconnect $tag");
			last;
		}
	}
	else {
		for my $server (irssi_servers()) {
			next unless $server->{tag} eq $tag;

			$server->command("reconnect");
			last;
		}
	}

	return encodeJson({ error => "" });
}

sub _doCommandIrcPart {
	my ($self, $json) = @_;

	my $tag = $self->_verifyString("Missing server tag", $json->{arg2});
	my $channelName = canonicalizeChannelName($self->_verifyString("Missing channel name", $json->{arg3}));

	for my $server (irssi_servers()) {
		next unless $server->{tag} eq $tag;

		my @serverChannels = eval { no warnings; return $server->channels(); };
		for my $channel (@serverChannels) {
			next unless $channelName eq canonicalizeChannelName($channel->{name});

			$channel->destroy();
			last;
		}
		last;
	}

	return encodeJson({ error => "" });
}

1;
