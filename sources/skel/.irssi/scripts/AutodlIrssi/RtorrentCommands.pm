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
# Creates a string of rtorrent commands
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::RtorrentCommands;

sub new {
	my $class = shift;
	bless {
		cmds => "",
	}, $class;
}

sub func {
	my ($self, $funcName, @args) = @_;

	$self->{cmds} .= ';' if $self->{cmds} ne "";
	$self->{cmds} .= "$funcName=";

	my $args = "";
	for my $arg (@args) {
		$arg =~ s/\\/\\\\/g;
		$arg =~ s/"/\\"/g;
		$args .= ',' if $args ne "";
		$args .= qq/"$arg"/;
	}
	$self->{cmds} .= $args;

	return $self;
}

sub get {
	return shift->{cmds};
}

1;
