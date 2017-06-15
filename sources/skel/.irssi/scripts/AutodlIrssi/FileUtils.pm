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
# File/dir utilities
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::FileUtils;
use File::Spec;
use File::Temp qw/ tempfile /;
use base qw/ Exporter /;
our @EXPORT = qw/ createDirectories saveRawDataToFile createTempFile appendUnixPath getFileData /;
our @EXPORT_OK = qw//;

# Creates a directory. Returns true on success.
sub createDirectories {
	my $dir = shift;
	return 1 if -d $dir;

	my $currDir = "";
	for my $dirName (split /\//, $dir) {
		$currDir = File::Spec->catdir($currDir, $dirName);
		next if -d $currDir;
		return 0 unless mkdir $currDir || -d $currDir;
	}

	return 1;
}

# Saves raw data to a file
sub saveRawDataToFile {
	my ($filename, $data) = @_;

	my $fh;
	open $fh, ">:raw", $filename or die "Could not create file $filename: $!\n";
	print { $fh } $data or die "Could not write to file $filename\n";
	close $fh;
}

# Creates and opens a temporary file
sub createTempFile {
	my $out = {};
	($out->{fh}, $out->{filename}) = tempfile(undef, UNLINK => 0);
	return $out;
}

# Appends $unixPath to $basePath and returns the new path
sub appendUnixPath {
	my ($basePath, $unixPath) = @_;

	for my $dirName (split /\//, $unixPath) {
		next if $dirName =~ /^\s*$/;
		$basePath = File::Spec->catfile($basePath, $dirName);
	}

	return $basePath;
}

sub getFileData {
	my $filename = shift;

	open my $fh, '<', $filename or die "Could not open file $filename: $!\n";
	binmode $fh;
	local $/;
	return scalar <$fh>;
}

1;
