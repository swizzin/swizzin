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
# Functions for getting certain directories
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Dirs;
use AutodlIrssi::Globals qw/ message /;
use Irssi;
use File::Spec;
use base qw/ Exporter /;
our @EXPORT = qw/ getHomeDir getIrssiScriptDir getAutodlFilesDir getTrackerFilesDir
				getAutodlSettingsDir getAutodlCfgFile getAutodl2CfgFile getEtcAutodlCfgFile
				getDownloadHistoryFile getAutodlStateFile getAbsPath /;
our @EXPORT_OK = qw//;

my $_homeDir = "";

# Returns user's home directory
sub getHomeDir {
	return $_homeDir if $_homeDir;
	my $_homeDir = $ENV{HOME} || (getpwuid($<))[7];
	die "Could not find user's home dir!\n" unless $_homeDir;
	return $_homeDir;
}

# Returns directory of Irssi scripts
sub getIrssiScriptDir {
	return File::Spec->catfile(Irssi::get_irssi_dir(), "scripts");
}

# Returns base directory of all our files (except the startup autodl-irssi.pl file)
sub getAutodlFilesDir {
	return File::Spec->catfile(getIrssiScriptDir(), "AutodlIrssi");
}

# Returns directory of all *.tracker files
sub getTrackerFilesDir {
	return File::Spec->catfile(getAutodlFilesDir(), "trackers");
}

# Returns directory of our settings dir
sub getAutodlSettingsDir {
	return File::Spec->catfile(getHomeDir(), ".autodl");
}

# Returns pathname of our autodl.cfg file
sub getAutodlCfgFile {
	return File::Spec->catfile(getAutodlSettingsDir(), "autodl.cfg");
}

# Returns pathname of our autodl2.cfg file
sub getAutodl2CfgFile {
	return File::Spec->catfile(getAutodlSettingsDir(), "autodl2.cfg");
}

# Returns pathname of our /etc/autodl.cfg file
sub getEtcAutodlCfgFile {
	return '/etc/autodl.cfg';
}

# Returns pathname of our DownloadHistory.txt file
sub getDownloadHistoryFile {
	return File::Spec->catfile(getAutodlSettingsDir(), "DownloadHistory.txt");
}

# Returns pathname of our AutodlState.xml file
sub getAutodlStateFile {
	return File::Spec->catfile(getAutodlSettingsDir(), "AutodlState.xml");
}

sub getAbsPath {
	my $path = shift;
	return $path if $path eq "";
	return getHomeDir() if $path eq '~';
	return getHomeDir() . substr($path, 1) if substr($path, 0, 2) eq '~/';
	return getHomeDir() . '/' . $path if substr($path, 0, 1) ne '/';
	return $path;
}

1;
