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
# Some useful Windows functions
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::WinUtils;
use base qw/ Exporter /;
our @EXPORT = qw/ isCygwin getWindowsPath /;
our @EXPORT_OK = qw//;

#
# This is the drive which is mapped to / in Wine. Should be a symlink in ~/.wine/dosdevices from z: -> /
#
use constant WINE_ROOT_DRIVE => 'Z:';

# Returns true if the script is running under cygwin
sub isCygwin {
	return $^O eq "cygwin";
}

sub getWindowsPath {
	my $unixPath = shift;

	if (isCygwin()) {
		return _cygwin_getWindowsPath($unixPath);
	}
	else {
		return _wine_getWindowsPath($unixPath);
	}
}

# Converts a unix path into its real Windows path.
sub _cygwin_getWindowsPath {
	my $unixPath = shift;

	my $res = `/usr/bin/cygpath -w "$unixPath"`;
	chomp $res;
	return $res;
}

# Converts a unix path to the wine windows path.
sub _wine_getWindowsPath {
	my $unixPath = shift;

	die "Not an absolute path: $unixPath\n" unless substr($unixPath, 0, 1) eq '/';

	$unixPath =~ s!/!\\!g;
	return WINE_ROOT_DRIVE . $unixPath;
}

1;
