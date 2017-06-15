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
# Execute a program
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Exec;
use AutodlIrssi::Globals;
use AutodlIrssi::Irssi;

# Execute a program. Will throw if it can't execute the program.
#	program		=> The program to execute
#	args		=> The arguments (a string). It supports the following escape sequences:
#						\\	=> \
#						\"	=> "
#					Everything inside double quotes is considered one argument.
sub run {
	my ($program, $args) = @_;

	$args = "" unless defined $args;

	my @userArgs = map {
		s/^"//;
		s/"$//;
		s/\\([\\"])/$1/g;
		$_;
	} $args =~ /"(?:[^"\\]|\\.)*"|(?:[^"\\\s]|\\.)+|".*/g;

	unshift @userArgs, $program;

	die "Could not find file '$program'\n" unless -f $program;
	die "'$program' is not executable\n" unless -x _;

	my $pid = fork;
	if (!defined $pid) {
		die "Could not fork '$program'\n";
	}
	elsif ($pid == 0) {
		exec { $program } @userArgs or die "Couldn't execute '$program'\n";
	}
	else {
		irssi_pidwait_add($pid);
		message 5, "Forked. pid: $pid, exec: '$program'";
	}
}

1;
