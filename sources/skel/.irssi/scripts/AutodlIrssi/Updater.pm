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
# Updates the main program and tracker files
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Updater;
use AutodlIrssi::Globals;
use AutodlIrssi::TextUtils;
use AutodlIrssi::FileUtils;
use AutodlIrssi::HttpRequest;
use AutodlIrssi::InternetUtils qw/ decodeJson /;
use AutodlIrssi::Dirs;
use File::Spec;
use File::Copy;
use Archive::Zip qw/ :ERROR_CODES /;
use constant {
	AUTODL_UPDATE_URL => 'https://api.github.com/repos/autodl-community/autodl-irssi/releases/latest',
	TRACKERS_UPDATE_URL => 'https://api.github.com/repos/autodl-community/autodl-trackers/releases/latest',
	UPDATE_USER_AGENT => 'autodl-irssi',
};

sub new {
	my $class = shift;
	bless {
		handler => undef,
		request => undef,
		githubToken => $AutodlIrssi::g->{options}{githubToken},
	}, $class;
}

# Throws an exception if check() hasn't been called.
sub _verifyCheckHasBeenCalled {
	my $self = shift;
	die "update check hasn't been called!\n" unless $self->{autodl} || $self->{trackers};
}

# Returns true if we're checking for updates, or downloading something else
sub _isChecking {
	my $self = shift;

	# Vim Perl parser doesn't like !! so use 'not !' for now...
	return not !$self->{request};
}

# Notifies the handler, catching any exceptions. $self->{handler} will be undef'd.
sub _notifyHandler {
	my ($self, $errorMessage) = @_;

	eval {
		my $handler = $self->{handler};

		# Clean up before calling the handler
		$self->{handler} = undef;
		$self->{request} = undef;

		if (defined $handler) {
			$handler->($errorMessage);
		}
	};
	if ($@) {
		chomp $@;
		message 0, "Updater::_notifyHandler: ex: $@";
	}
}

# Called when an error occurs. The handler is called with the error message.
sub _error {
	my ($self, $errorMessage) = @_;
	$errorMessage ||= "Unknown error";
	$self->_notifyHandler($errorMessage);
}

# Cancel any downloads, and call the handler with an error message.
sub cancel {
	my ($self, $errorMessage) = @_;

	$errorMessage ||= "Cancelled!";
	return unless $self->_isChecking();

	if ($self->{request}) {
		$self->{request}->cancel();
	}

	$self->_error($errorMessage);
}

sub _createHttpRequest {
	my $self = shift;

	$self->{request} = new AutodlIrssi::HttpRequest();
	$self->{request}->setUserAgent(UPDATE_USER_AGENT);
	$self->{request}->setFollowNewLocation();
}

sub _parseAutodlUpdate {
	my ($self, $autodlData) = @_;

	my $autodlTagName = my $autodlVersion = $autodlData->{tag_name};
	$autodlVersion =~ s/community-v//;
	my $autodlDownloadUrl = "https://github.com/autodl-community/autodl-irssi/releases/download/$autodlTagName/autodl-irssi-community-v$autodlVersion.zip";
	my $autodlChangeLog = $autodlData->{body};

	$self->{autodl} = {
		version		=> $autodlVersion,
		whatsNew	=> $autodlChangeLog,
		url			=> $autodlDownloadUrl,
	};

	$self->{autodl}{whatsNew} =~ s/\r//mg;
}

sub _parseTrackersUpdate {
	my ($self, $trackersData) = @_;

	my $trackersTagName = my $trackersVersion = $trackersData->{tag_name};
	$trackersVersion =~ s/community-v//;
	my $trackersDownloadUrl = "https://github.com/autodl-community/autodl-trackers/releases/download/$trackersTagName/autodl-trackers-v$trackersVersion.zip";
	my $trackersChangeLog = $trackersData->{body};

	$self->{trackers} = {
		version		=> $trackersVersion,
		whatsNew	=> $trackersChangeLog,
		url			=> $trackersDownloadUrl,
	};

	$self->{trackers}{whatsNew} =~ s/\r//mg;
}

# Check for autodl updates. $handler->($errorMessage) will be notified.
sub checkAutodlUpdate {
	my ($self, $handler) = @_;

	die "Already checking for updates\n" if $self->_isChecking();

	$self->{handler} = $handler || sub {};
	$self->_createHttpRequest();

	$self->{updateUrl} = AUTODL_UPDATE_URL;
	if ($self->{githubToken}) {
		$self->{updateUrl} .= "?access_token=$self->{githubToken}";
	}

	$self->{request}->sendRequest("GET", "", $self->{updateUrl} , {}, sub {
		$self->_onRequestReceived(@_);
	});
}

# Check for trackers updates. $handler->($errorMessage) will be notified.
sub checkTrackersUpdate {
	my ($self, $handler) = @_;

	die "Already checking for updates\n" if $self->_isChecking();

	$self->{handler} = $handler || sub {};
	$self->_createHttpRequest();

	$self->{updateUrl} = TRACKERS_UPDATE_URL;
	if ($self->{githubToken}) {
		$self->{updateUrl} .= "?access_token=$self->{githubToken}";
	}

	$self->{request}->sendRequest("GET", "", $self->{updateUrl} , {}, sub {
		$self->_onRequestReceived(@_);
	});
}

sub _onRequestReceived {
	my ($self, $errorMessage) = @_;

	eval {
		return $self->_error("Error getting update info: $errorMessage") if $errorMessage;

		my $statusCode = $self->{request}->getResponseStatusCode();
		if ($statusCode != 200) {
			return $self->_error("Error getting update info: " . $self->{request}->getResponseStatusText());
		}

		my $jsonData = decodeJson($self->{request}->getResponseData());

		if ($self->{request}{url} =~ /autodl-irssi/) {
			$self->_parseAutodlUpdate($jsonData);
		}
		elsif ($self->{request}{url} =~ /autodl-trackers/) {
			$self->_parseTrackersUpdate($jsonData);
		}

		$self->_notifyHandler("");
	};
	if ($@) {
		chomp $@;
		if ($self->{request}{url} =~ /autodl-irssi/) {
			$self->_error("Could not parse autodl update data: $@");
		}
		elsif ($self->{request}{url} =~ /autodl-trackers/) {
			$self->_error("Could not parse trackers update data: $@");
		}
	}
}

# Download the trackers file and extract it to $destDir. check() must've been called successfully.
sub updateTrackers {
	my ($self, $destDir, $handler) = @_;

	$self->_verifyCheckHasBeenCalled();
	die "Already checking for trackers updates\n" if $self->_isChecking();

	$self->{handler} = $handler || sub {};
	$self->_createHttpRequest();
	$self->{request}->sendRequest("GET", "", $self->{trackers}{url}, {}, sub {
		$self->_onDownloadedTrackersFile(@_, $destDir);
	});
}

sub _onDownloadedTrackersFile {
	my ($self, $errorMessage, $destDir) = @_;

	eval {
		return $self->_error("Error getting trackers file: $errorMessage") if $errorMessage;

		my $statusCode = $self->{request}->getResponseStatusCode();
		if ($statusCode != 200) {
			return $self->_error("Error getting trackers file: " . $self->{request}->getResponseStatusText());
		}

		$self->_extractZipFile($self->{request}->getResponseData(), $destDir);

		$self->_notifyHandler("");
	};
	if ($@) {
		chomp $@;
		$self->_error("Error downloading trackers file: $@");
	}
}

# Download the autodl file and extract it to $destDir. check() must've been called successfully.
sub updateAutodl {
	my ($self, $destDir, $handler) = @_;

	$self->_verifyCheckHasBeenCalled();
	die "Already checking for autodl updates\n" if $self->_isChecking();

	$self->{handler} = $handler || sub {};
	$self->_createHttpRequest();
	$self->{request}->sendRequest("GET", "", $self->{autodl}{url}, {}, sub {
		$self->_onDownloadedAutodlFile(@_, $destDir);
	});
}

sub _onDownloadedAutodlFile {
	my ($self, $errorMessage, $destDir) = @_;

	eval {
		return $self->_error("Error getting autodl file: $errorMessage") if $errorMessage;

		my $statusCode = $self->{request}->getResponseStatusCode();
		if ($statusCode != 200) {
			return $self->_error("Error getting autodl file: " . $self->{request}->getResponseStatusText());
		}

		$self->_extractZipFile($self->{request}->getResponseData(), $destDir);

		# If autorun/autodl-irssi.pl exists, update it.
		my $srcAutodlFile = File::Spec->catfile($destDir, 'autodl-irssi.pl');
		my $dstAutodlFile = File::Spec->catfile($destDir, 'autorun', 'autodl-irssi.pl');
		if (-f $dstAutodlFile) {
			copy($srcAutodlFile, $dstAutodlFile) or die "Could not create '$dstAutodlFile': $!\n";
		}

		$self->_notifyHandler("");
	};
	if ($@) {
		chomp $@;
		$self->_error("Error downloading autodl file: $@");
	}
}

sub _extractZipFile {
	my ($self, $zipData, $destDir) = @_;

	my $tmp;
	eval {
		$tmp = createTempFile();
		binmode $tmp->{fh};
		print { $tmp->{fh} } $zipData or die "Could not write to temporary file\n";
		close $tmp->{fh};

		my $zip = new Archive::Zip();
		my $code = $zip->read($tmp->{filename});
		if ($code != AZ_OK) {
			die "Could not read zip file, code: $code, size: " . length($zipData) . "\n";
		}

		my @fileInfos = map {
			{
				destFile => appendUnixPath($destDir, $_->fileName()),
				member => $_,
			}
		} $zip->members();

		# Make sure we can write to all files
		for my $info (@fileInfos) {
			message 5, "Creating file '$info->{destFile}'";

			if ($info->{member}->isDirectory()) {
				die "Could not create directory '$info->{destFile}'\n" unless createDirectories($info->{destFile});
			}
			else {
				my ($volume, $dir, $file) = File::Spec->splitpath($info->{destFile}, 0);
				die "Could not create directory '$dir'\n" unless createDirectories($dir);
				open my $fh, '>>', $info->{destFile} or die "Could not write to file '$info->{destFile}': $!\n";
				close $fh;
			}
		}

		for my $trackerFile ($AutodlIrssi::g->{trackerManager}->getTrackerFiles(getTrackerFilesDir())) {
			message 5, "Deleting file $trackerFile";
			unlink $trackerFile;
		}

		# Now write all data to disk. This shouldn't fail... :)
		for my $info (@fileInfos) {
			if (!$info->{member}->isDirectory()) {
				message 5, "Extracting file '$info->{destFile}'";
				if ($info->{member}->extractToFileNamed($info->{destFile}) != AZ_OK) {
					die "Could not extract file '$info->{destFile}'\n";
				}
			}
		}
	};
	if ($tmp) {
		close $tmp->{fh};
		unlink $tmp->{filename};
	}
	die $@ if $@;
}

sub getAutodlWhatsNew {
	return shift->{autodl}{whatsNew};
}

# Returns true if there's an autodl update available
sub hasAutodlUpdate {
	my ($self, $version) = @_;

	$self->_verifyCheckHasBeenCalled();
	return $self->{autodl}{version} gt $version;
}

sub getTrackersWhatsNew {
	return shift->{trackers}{whatsNew};
}

# Returns true if there's a trackers update available
sub hasTrackersUpdate {
	my ($self, $version) = @_;

	$self->_verifyCheckHasBeenCalled();
	return $self->getTrackersVersion() gt $version;
}

sub getTrackersVersion {
	my $self = shift;

	$self->_verifyCheckHasBeenCalled();
	return $self->{trackers}{version};
}

# Returns true if we're sending a request
sub isSendingRequest {
	return shift->_isChecking();
}

1;
