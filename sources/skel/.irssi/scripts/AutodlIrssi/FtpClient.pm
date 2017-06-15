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
# FTP client
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::FtpClient;
use AutodlIrssi::Globals;
use AutodlIrssi::LineBuffer;
use AutodlIrssi::Socket;
use AutodlIrssi::SslSocket;
use AutodlIrssi::Irssi qw/ irssi_timeout_add_once /;
use Socket qw/ :crlf /;

sub new {
	my $class = shift;
	my $self = bless {
		commands => [],
		isSecure => 0,	#TODO: Support this
		socket => undef,
		sendingInfo => undef,
	}, $class;
	$self->{connId} = $AutodlIrssi::g->{activeConnections}->add($self, "FTP download");
	return $self;
}

sub DESTROY {
	my $self = shift;

	if (defined $self->{connId}) {
		$AutodlIrssi::g->{activeConnections}->remove($self->{connId});
	}
}

sub isSendingCommands {
	return !!shift->{sendingInfo};
}

sub isConnected {
	return !!shift->{socket};
}

sub cleanUp {
	my $self = shift;

	if (defined $self->{socket}) {
		$self->{socket}->removeAllHandlers("");
		$self->{socket} = undef;
	}
}

sub fatal {
	my ($self, $errorMessage) = @_;
	$self->cleanUp();
	$self->sendCommandsCompleted($errorMessage);
}

# Initializes everything needed for connecting to the FTP, and connects to the FTP.
# $connectHandler->($errorMessage) is called when we're connected (or failed to connect).
sub start {
	my ($self, $hostname, $port, $connectHandler) = @_;

	$self->cleanUp();
	$self->{multiLineCode} = 0;
	$self->{lineBuffer} = new AutodlIrssi::LineBuffer(sub { $self->_onCommandDataAvail(@_) });
	$self->{closing} = 0;

	if ($self->{isSecure}) {
		$self->{socket} = new AutodlIrssi::SslSocket();
	}
	else {
		$self->{socket} = new AutodlIrssi::Socket();
	}
	$self->{socket}->connect($hostname, $port, sub { $self->_onConnected($connectHandler, @_) });
}

# Called when we're connected, or failed to connect
sub _onConnected {
	my ($self, $connectHandler, $errorMessage) = @_;

	eval {
		$connectHandler->($errorMessage);
	};
	if ($@) {
		$self->fatal("FtpClient._onConnected: ex: " . formatException($@));
		return;
	}
	return if $errorMessage;

	$self->{socket}->installReadHandler(sub { $self->_ftpReadHandler(@_) });
}

# Called when there's data to read from the FTP connection. $data is "" if the connection closed.
sub _ftpReadHandler {
	my ($self, $errorMessage, $data) = @_;

	if ($errorMessage) {
		$self->fatal($errorMessage);
	}
	elsif (length $data) {
		$self->_onDataAvailable($data);
	}
	else {
		$self->_onConnectionClosed();
	}
}

# Called when FTP connection was closed by the server
sub _onConnectionClosed {
	my $self = shift;

	my $errorMessage = $self->{closing} ? "" : "Connection closed unexpectedly. Check user, password, IP, port settings.";
	$self->{lineBuffer}->flushData();
	if ($errorMessage) {
		$self->fatal($errorMessage);
	}
}

# Called when server sent us some data. length $data > 0.
sub _onDataAvailable {
	my ($self, $data) = @_;

	eval {
		$self->{lineBuffer}->addData($data);
	};
	if ($@) {
		$self->fatal("FtpClient._onDataAvailable: ex: " . formatException($@));
	}
}

# Called when a new line is received from the server
sub _onCommandDataAvail {
	my ($self, $data) = @_;

	if (!$self->{multiLineCode}) {
		my @ary = $data =~ /^(\d{3})/;
		if (!@ary || (substr($data, 3, 1) ne " " && substr($data, 3, 1) ne "-")) {
			if ($data =~ /^SSH/) {
				$self->fatal("FTP: You need to use an SSH tunnel. Google it! ;)");
			}
			else {
				$self->fatal("FTP: Unknown reply: '$data'");
			}
			return;
		}

		$self->{code} = $ary[0];
		$self->{codeMessage} = $data;
		if (substr($data, 3, 1) eq "-") {
			$self->{multiLineCode} = 1;
			$self->{codeMessage} .= "\n";
			return;
		}
	}
	else
	{
		$self->{codeMessage} .= $data;
		if (substr($data, 0, 4) ne "$self->{code} ") {
			$self->{codeMessage} .= "\n";
			return;
		}
		$self->{multiLineCode} = 0;
	}

	message(5, "FTP: $self->{codeMessage}");
	$self->onCodeAvailable($self->{code}, $self->{codeMessage});
}

sub onCodeAvailable {
	my ($self, $code, $codeMessage) = @_;

	return unless defined $self->{sendingInfo};

	eval {
		$self->{sendingInfo}{command}{handler}->($self, $self->{sendingInfo}{command}, $code, $codeMessage);
	};
	if ($@) {
		return $self->fatal("FtpClient.onCodeAvailable: ex: " . formatException($@));
	}
}

sub sendLowLevelCommand {
	my ($self, $line) = @_;

	if ($line =~ /^PASS /i) {
		message(5, "FTP: PASS ****");
	}
	else {
		message(5, "FTP: $line");
	}

	$self->{socket}->write("$line$CRLF", sub {
		my $errorMessage = shift;
		if ($errorMessage) {
			$self->fatal("Could not send FTP command '$line'. Error: $errorMessage");
		}
	});
}

sub addCommand {
	my ($self, $command) = @_;

	if ($self->isSendingCommands()) {
		die "FtpClient.addCommand: can't add a command when sending commands\n";
	}

	push @{$self->{commands}}, $command;
}

use constant {
	STCONN_START		=> 10,
	STCONN_LL_CONN_WAIT => 11,
	STCONN_CONNECT_WAIT	=> 12,
	STCONN_SENT_USER	=> 13,
	STCONN_SENT_PASS	=> 14,
	STCONN_END			=> 15,

	# Number of seconds we'll retry connecting to the FTP server. This should be long enough for
	# the server to start in case we've just sent a WOL command to wake it up.
	FTP_CONNECT_TIMEOUT_SECS => 2*60,

	# Wait this many seconds before reconnecting
	FTP_RECONNECT_TIMEOUT_WAIT_SECS => 10,
};

# Add a "connect to FTP" command. All other commands require this command.
# @param ftpSettings	Has user, password, hostname, port properties
sub addConnect {
	my ($self, $ftpSettings) = @_;

	$self->addCommand({
		name => "connect",
		state => STCONN_START,
		ftpSettings => $ftpSettings,
		handler => \&connectHandler,
	});
}

sub connectHandler {
	my ($self, $command, $code, $codeMessage) = @_;

	my $retryConnect = sub {
		my $errorMessage = shift;

		if (time() - $command->{startTime} > FTP_CONNECT_TIMEOUT_SECS) {
			$self->fatal($errorMessage);
			return 0;
		}

		message 4, "Could not connect to FTP. Waiting before reconnecting...";
		$command->{state} = STCONN_START;
		irssi_timeout_add_once(FTP_RECONNECT_TIMEOUT_WAIT_SECS * 1000, sub {
			connectHandler($self, $command, $code, $codeMessage);
		}, undef);
		return 1;
	};

	my $code0 = substr $code, 0, 1;
	while (1) {
		if ($command->{state} == STCONN_START) {
			$command->{startTime} = time() unless $command->{startTime};

			$command->{state} = STCONN_LL_CONN_WAIT;
			my $rv = $self->start($command->{ftpSettings}{hostname}, $command->{ftpSettings}{port}, sub {
				my $errorMessage = shift;
				if ($errorMessage) {
					return $retryConnect->("Could not connect to FTP $command->{ftpSettings}{hostname}:$command->{ftpSettings}{port}. Error: $errorMessage");
				}
				$command->{state} = STCONN_CONNECT_WAIT;
			});
			return;
		}
		elsif ($command->{state} == STCONN_LL_CONN_WAIT) {
			return $self->fatal("STCONN_LL_CONN_WAIT: BUG: We should not be here! code: $code, codemsg: $codeMessage");
		}
		elsif ($command->{state} == STCONN_CONNECT_WAIT) {
			if ($code0 != 2) {
				return $self->fatal("Could not connect to server $command->{ftpSettings}{hostname}:$command->{ftpSettings}{port}. Reason: $codeMessage");
			}
			$self->sendLowLevelCommand("USER $command->{ftpSettings}{user}");
			$command->{state} = STCONN_SENT_USER;
			return;
		}
		elsif ($command->{state} == STCONN_SENT_USER) {
			if ($code0 == 2) {
				$command->{state} = STCONN_END;
				next;
			}
			if ($code != 331) {
				return $self->fatal("Could not log in. Reason: $codeMessage");
			}
			$self->sendLowLevelCommand("PASS $command->{ftpSettings}{password}");
			$command->{state} = STCONN_SENT_PASS;
			return;
		}
		elsif ($command->{state} == STCONN_SENT_PASS) {
			if ($code0 != 2) {
				return $self->fatal("Could not log in. Reason: $codeMessage");
			}
			$command->{state} = STCONN_END;
			next;
		}
		elsif ($command->{state} == STCONN_END) {
			return $self->sendNextCommand();
		}
		else {
			return $self->fatal("Unknown state $command->{state} ($command->{name})");
		}
	}
}

use constant {
	STCD_START		=> 20,
	STCD_CD_SENT	=> 21,
	STCD_END		=> 22,
};

sub addChangeDirectory {
	my ($self, $ftpDir) = @_;

	$ftpDir =~ s#\\#/#g;
	$self->addCommand({
		name => "change directory",
		ftpDir => $ftpDir,
		state => STCD_START,
		handler => \&changeDirHandler,
	});
}

sub changeDirHandler {
	my ($self, $command, $code, $codeMessage) = @_;

	my $code0 = substr $code, 0, 1;
	while (1) {
		if ($command->{state} == STCD_START) {
			$self->sendLowLevelCommand("CWD $command->{ftpDir}");
			$command->{state} = STCD_CD_SENT;
			return;
		}
		elsif ($command->{state} == STCD_CD_SENT) {
			if ($code0 != 2) {
				return $self->sendNextCommand("Could not change directory to '$command->{ftpDir}'. Reason: $codeMessage");
			}
			$command->{state} = STCD_END;
			next;
		}
		elsif ($command->{state} == STCD_END) {
			return $self->sendNextCommand();
		}
		else {
			return $self->fatal("Unknown state $command->{state} ($command->{name})");
		}
	}
}

use constant {
	STSF_START					=> 30,
	STSF_SENT_TYPE				=> 31,
	STSF_SENT_PASV				=> 32,
	STSF_CONNECT_TO_DATA_PORT	=> 33,
	STSF_LL_CONN_DATA_WAIT		=> 34,
	STSF_LL_CONN_DATA_WAIT2		=> 35,
	STSF_CONNECTED_DATA_PORT	=> 36,
	STSF_SENDING_DATA			=> 37,
	STSF_DATA_SENT				=> 38,
	STSF_DATA_SENT_WAIT			=> 39,
	STSF_END					=> 49,
};

sub addSendFile {
	my ($self, $filename, $readDataFunc, $ctx) = @_;

	$self->addCommand({
		name => "send file",
		filename => $filename,
		readDataFunc => $readDataFunc,
		ctx => $ctx,
		state => STSF_START,
		handler => \&sendFileHandler,
	});
}

sub sendFile_writeData {
	my ($self, $command) = @_;

	my $data = $command->{readDataFunc}->($command->{ctx});
	if (length($data) == 0) {
		$command->{state} = STSF_DATA_SENT;
		$self->sendFileHandler($command, "", "");
		return;
	}

	$command->{dataConn}->write($data, sub {
		my $errorMessage = shift;
		if ($errorMessage) {
			$self->sendFileHandler($command, "", $errorMessage);
			return;
		}
		$self->sendFile_writeData($command);
	});
}

sub sendFileHandler {
	my ($self, $command, $code, $codeMessage) = @_;

	my $code0 = substr $code, 0, 1;
	while (1) {
		if ($command->{state} == STSF_START) {
			$self->sendLowLevelCommand("TYPE I");
			$command->{state} = STSF_SENT_TYPE;
			return;
		}
		elsif ($command->{state} == STSF_SENT_TYPE) {
			if ($code0 != 2) {
				return $self->sendNextCommand("Could not set binary mode. Reason: $codeMessage");
			}
			$self->sendLowLevelCommand("PASV");
			$command->{state} = STSF_SENT_PASV;
			return;
		}
		elsif ($command->{state} == STSF_SENT_PASV) {
			my @ary = $codeMessage =~ /(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)/;
			if ($code != 227 || !@ary) {
				return $self->sendNextCommand("Passive mode failed. Reason: $codeMessage");
			}
			$command->{pasvPort} = ($ary[4] << 8) + $ary[5];
			$command->{pasvIp} = "$ary[0].$ary[1].$ary[2].$ary[3]";
			$self->sendLowLevelCommand("STOR $command->{filename}");
			$command->{state} = STSF_CONNECT_TO_DATA_PORT;
			next;
		}
		elsif ($command->{state} == STSF_CONNECT_TO_DATA_PORT) {
			$command->{dataConn} = new AutodlIrssi::Socket();
			$command->{dataConn}->connect($command->{pasvIp}, $command->{pasvPort}, sub {
				my $errorMessage = shift;
				if ($errorMessage) {
					return $self->sendNextCommand("Could not connect to ftp data port $command->{pasvIp}:$command->{pasvPort}. Error: $errorMessage");
				}
				$command->{state} = STSF_CONNECTED_DATA_PORT;
				if (defined $command->{earlyReply}) {
					$self->sendFileHandler($command, $command->{earlyReply}{code}, $command->{earlyReply}{codeMessage});
					delete $command->{earlyReply};
				}
			});
			$command->{state} = STSF_LL_CONN_DATA_WAIT;
			return;
		}
		elsif ($command->{state} == STSF_LL_CONN_DATA_WAIT) {
			# Here if we received a reply before our connect handler was called. Doesn't happen alot.
			$command->{earlyReply} = {
				code => $code,
				codeMessage => $codeMessage,
			};
			$command->{state} = STSF_LL_CONN_DATA_WAIT2;
			return;
		}
		elsif ($command->{state} == STSF_LL_CONN_DATA_WAIT2) {
			return $self->fatal("Got an unexpected message from the FTP server: $codeMessage");
		}
		elsif ($command->{state} == STSF_CONNECTED_DATA_PORT) {
			if ($code0 != 1) {
				return $self->sendNextCommand("Passive mode STOR failed. Reason: $codeMessage");
			}

			$command->{state} = STSF_SENDING_DATA;
			$self->sendFile_writeData($command);
			return;
		}
		elsif ($command->{state} == STSF_SENDING_DATA) {
			return unless defined $command->{dataConn};
			$command->{dataConn}->close("Got unexpected reply: $codeMessage");
			$command->{dataConn} = undef;
			return;
		}
		elsif ($command->{state} == STSF_DATA_SENT) {
			my $errorMessage = $codeMessage;

			$command->{dataConn}->close($errorMessage);
			$command->{dataConn} = undef;

			if ($errorMessage) {
				return $self->sendNextCommand("Error sending data: $errorMessage");
			}

			$command->{state} = STSF_DATA_SENT_WAIT;
			return;
		}
		elsif ($command->{state} == STSF_DATA_SENT_WAIT) {
			if ($code0 != 2) {
				return $self->sendNextCommand("Could not send the file. Reason: $codeMessage");
			}
			$command->{state} = STSF_END;
			next;
		}
		elsif ($command->{state} == STSF_END) {
			return $self->sendNextCommand();
		}
		else {
			return $self->fatal("Unknown state $command->{state} ($command->{name})");
		}
	}
}

use constant {
	STRN_START			=> 50,
	STRN_RNFR_SENT		=> 51,
	STRN_RNTO_SENT		=> 52,
	STRN_END			=> 59,
};

sub addRename {
	my ($self, $oldName, $newName) = @_;

	$self->addCommand({
		name => "rename",
		oldName => $oldName,
		newName => $newName,
		state => STRN_START,
		handler => \&renameHandler,
	});
}

sub renameHandler {
	my ($self, $command, $code, $codeMessage) = @_;

	my $code0 = substr $code, 0, 1;
	while (1) {
		if ($command->{state} == STRN_START) {
			$self->sendLowLevelCommand("RNFR $command->{oldName}");
			$command->{state} = STRN_RNFR_SENT;
			return;
		}
		elsif ($command->{state} == STRN_RNFR_SENT) {
			if ($code0 != 3) {
				return $self->sendNextCommand("Could not rename '$command->{oldName}' -> '$command->{newName}'. Reason: $codeMessage");
			}
			$self->sendLowLevelCommand("RNTO $command->{newName}");
			$command->{state} = STRN_RNTO_SENT;
			return;
		}
		elsif ($command->{state} == STRN_RNTO_SENT) {
			if ($code0 != 2) {
				return $self->sendNextCommand("Could not rename '$command->{oldName}' -> '$command->{newName}'. Reason: $codeMessage");
			}
			$command->{state} = STRN_END;
			next;
		}
		elsif ($command->{state} == STRN_END) {
			return $self->sendNextCommand();
		}
		else {
			return $self->fatal("Unknown state $command->{state} ($command->{name})");
		}
	}
}

sub addQuit {
	my $self = shift;

	$self->addCommand({
		name => "quit",
		state => 0,
		handler => \&quitHandler,
	});
}

sub quitHandler {
	my ($self, $command, $code, $codeMessage) = @_;

	if ($command->{state} == 0) {
		$self->{closing} = 1;
		$self->sendLowLevelCommand("QUIT");
		$command->{state}++;
	}
	elsif ($command->{state} == 1) {
		return $self->sendNextCommand();
	}
	else {
		return $self->fatal("Unknown state $command->{state} ($command->{name})");
	}
}

sub sendCommands {
	my ($self, $callback) = @_;

	if ($self->isSendingCommands()) {
		die "FtpClient.sendCommands: Already sending commands!\n";
	}

	eval {
		$self->{sendingInfo} = {
			callback => $callback,
			commandIndex => -1,
		};
		$self->sendNextCommand();
	};
	if ($@) {
		return $self->fatal("FtpClient.sendCommands: ex: " . formatException($@));
	}
}

sub sendNextCommand {
	my ($self, $errorMessage) = @_;

	return $self->sendCommandsCompleted($errorMessage) if $errorMessage;

	eval {
		$self->{sendingInfo}{commandIndex}++;
		if ($self->{sendingInfo}{commandIndex} >= @{$self->{commands}}) {
			return $self->sendCommandsCompleted("");
		}

		my $command = $self->{commands}[$self->{sendingInfo}{commandIndex}];
		$self->{sendingInfo}{command} = $command;
		if ($command->{name} ne "connect" && !$self->isConnected()) {
			return $self->sendCommandsCompleted("FTP command '$command->{name}' requires a connection.");
		}
		$command->{handler}->($self, $self->{sendingInfo}{command}, "XXX", "<DON'T READ THIS>");
	};
	if ($@) {
		return $self->fatal("FtpClient.sendNextCommand: ex: " . formatException($@));
	}
}

sub sendCommandsCompleted {
	my ($self, $errorMessage) = @_;

	return unless defined $self->{sendingInfo};

	$self->{commands} = [];
	my $callback = $self->{sendingInfo}{callback};
	$self->{sendingInfo} = undef;
	$self->{lineBuffer} = undef;	# Prevent a memory leak since the callback holds a ref to us

	$self->cleanUp();

	eval {
		$callback->($errorMessage);
	};
	if ($@) {
		message(0, "FtpClient.sendCommandsCompleted: ex: " . formatException($@));
	}
}

1;
