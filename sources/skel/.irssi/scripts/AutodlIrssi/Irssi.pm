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
# This module exists since Irssi doesn't allow us calling some of their functions without being
# in the script's package.
#
# Since the package name is a function of the loaded script filename, this file will need to be
# updated whenever the filename changes. Change the last part of Irssi::Script::autodl_irssi.
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::Irssi;
use base qw/ Exporter/ ;
our @EXPORT = qw/ irssi_signal_add irssi_signal_remove irssi_print irssi_input_add irssi_input_remove
					irssi_timeout_add irssi_timeout_add_once irssi_timeout_remove irssi_pidwait_add
					irssi_servers irssi_reconnects irssi_channels irssi_command irssi_command_bind
					irssi_windows /;
our @EXPORT_OK = qw//;

sub irssi_signal_add {
	goto &Irssi::Script::autodl_irssi::irssi_signal_add;
}

sub irssi_signal_remove {
	goto &Irssi::Script::autodl_irssi::irssi_signal_remove;
}

sub irssi_print {
	goto &Irssi::Script::autodl_irssi::irssi_print;
}

sub irssi_input_add {
	goto &Irssi::Script::autodl_irssi::irssi_input_add;
}

sub irssi_input_remove {
	goto &Irssi::Script::autodl_irssi::irssi_input_remove;
}

sub irssi_timeout_add {
	goto &Irssi::Script::autodl_irssi::irssi_timeout_add;
}

sub irssi_timeout_add_once {
	goto &Irssi::Script::autodl_irssi::irssi_timeout_add_once;
}

sub irssi_timeout_remove {
	goto &Irssi::Script::autodl_irssi::irssi_timeout_remove;
}

sub irssi_pidwait_add {
	goto &Irssi::Script::autodl_irssi::irssi_pidwait_add;
}

sub irssi_servers {
	goto &Irssi::Script::autodl_irssi::irssi_servers;
}

sub irssi_reconnects {
	goto &Irssi::Script::autodl_irssi::irssi_reconnects;
}

sub irssi_windows {
	goto &Irssi::Script::autodl_irssi::irssi_windows;
}

sub irssi_channels {
	goto &Irssi::Script::autodl_irssi::irssi_channels;
}

sub irssi_command {
	goto &Irssi::Script::autodl_irssi::irssi_command;
}

sub irssi_command_bind {
	goto &Irssi::Script::autodl_irssi::irssi_command_bind;
}

# This is the package Irssi creates for us
package Irssi::Script::autodl_irssi;
use Irssi;

#
# Irssi has some bug where we sometimes get this warning:
#		Can't locate package Irssi::Nick for @Irssi::Irc::Nick::ISA at
# Therefore, all of these functions have the 'no warnings' pragma set.
#

sub irssi_signal_add {
	no warnings;
	return &Irssi::signal_add(@_);
}

sub irssi_signal_remove {
	no warnings;
	return &Irssi::signal_remove(@_);
}

sub irssi_print {
	no warnings;
	return &Irssi::print(@_);
}

sub irssi_input_add {
	no warnings;
	return &Irssi::input_add(@_);
}

sub irssi_input_remove {
	no warnings;
	return &Irssi::input_remove(@_);
}

sub irssi_timeout_add {
	no warnings;
	return &Irssi::timeout_add(@_);
}

sub irssi_timeout_add_once {
	no warnings;
	return &Irssi::timeout_add_once(@_);
}

sub irssi_timeout_remove {
	no warnings;
	return &Irssi::timeout_remove(@_);
}

sub irssi_pidwait_add {
	no warnings;
	return &Irssi::pidwait_add(@_);
}

sub irssi_servers {
	no warnings;
	return &Irssi::servers(@_);
}

sub irssi_reconnects {
	no warnings;
	return &Irssi::reconnects(@_);
}

sub irssi_windows {
	no warnings;
	return &Irssi::windows(@_);
}

sub irssi_channels {
	no warnings;
	return &Irssi::channels(@_);
}

sub irssi_command {
	no warnings;
	return &Irssi::command(@_);
}

sub irssi_command_bind {
	no warnings;
	return &Irssi::command_bind(@_);
}

1;
