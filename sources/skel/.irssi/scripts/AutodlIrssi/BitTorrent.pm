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
# Some funcs for parsing a bittorrent file
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::BitTorrent::File;

sub new {
	my ($class, $relativePath, $fileSize) = @_;
	bless {
		relativePath => $relativePath,
		fileSize => $fileSize,
	}, $class;
}

package AutodlIrssi::BitTorrent::Files;

sub new {
	my ($class, $directoryName) = @_;
	bless {
		directoryName => $directoryName,
		files => [],
		totalSize => 0,
	}, $class;
}

sub addFile {
	my ($self, $torrentFile) = @_;

	if ($self->{directoryName}) {
		$torrentFile->{relativePath} = $self->{directoryName} . '/' . $torrentFile->{relativePath};
	}

	push @{$self->{files}}, $torrentFile;
	$self->{totalSize} += $torrentFile->{fileSize};
}

package AutodlIrssi::BitTorrent;
use AutodlIrssi::Globals;
use AutodlIrssi::TextUtils;
use base qw/ Exporter /;
our @EXPORT = qw/ getTorrentFiles /;
our @EXPORT_OK = qw//;

sub getTorrentFiles {
	my $root = shift;

	my $rv = eval {
		return _tryGetTorrentFiles($root);
	};
	if ($@) {
		message(0, "Caught an exception in getTorrentFiles(): " . formatException($@));
		return;
	}
	return $rv;
}

sub _tryGetTorrentFiles {
	my $root = shift;

	return unless $root->isDictionary();

	my $info = $root->readDictionary("info");
	return unless $info && $info->isDictionary();

	my $getInteger = sub {
		my $benc = shift;

		my $size;
		if (!$benc || !$benc->isInteger() || !defined ($size = convertStringToInteger($benc->{integer}))) {
			die "Invalid torrent file: expected an integer\n";
		}
		return $size;
	};
	my $getString = sub {
		my $benc = shift;
		if (!$benc || !$benc->isString()) {
			die "Invalid torrent file: expected a string\n";
		}
		return $benc->{string};
	};

	my $torrentFiles;
	my $files = $info->readDictionary("files");
	if ($files) {
		# multiple files torrent

		return unless $files->isList();

		$torrentFiles = new AutodlIrssi::BitTorrent::Files($getString->($info->readDictionary("name")));

		for my $dict (@{$files->{list}}) {
			return unless $dict->isDictionary();

			my $fileSize = $getInteger->($dict->readDictionary("length"));
			my $bencPath = $dict->readDictionary("path");
			return unless $bencPath && $bencPath->isList();

			my $fileName = "";
			for my $name (@{$bencPath->{list}}) {
				$fileName .= '/' if $fileName;
				$fileName .= $getString->($name);
			}
			$torrentFiles->addFile(new AutodlIrssi::BitTorrent::File($fileName, $fileSize));
		}
	}
	else {
		# single file torrent

		$torrentFiles = new AutodlIrssi::BitTorrent::Files("");
		my $fileName = $getString->($info->readDictionary("name"));
		my $fileSize = $getInteger->($info->readDictionary("length"));
		$torrentFiles->addFile(new AutodlIrssi::BitTorrent::File($fileName, $fileSize));
	}

	return $torrentFiles;
}

1;
