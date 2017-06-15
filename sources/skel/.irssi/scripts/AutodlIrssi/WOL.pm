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
# Send a WOL (Wake on LAN) packet
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::WOL;
use Socket;
use base qw/ Exporter /;
our @EXPORT = qw/ sendWOL /;
our @EXPORT_OK = qw//;

# Default UDP port for magic packet
use constant DEFAULT_UDP_PORT => 9;

sub _macAddrToBinary {
	my $macAddr = shift;

	my @ary = $macAddr =~ /[\da-fA-F]{2}/g;
	return unless @ary == 6;
	return pack "C6", map { hex $_ } @ary;
}

sub _getMagicPacket {
	my $macAddr = shift;

	use bytes;
	my $binMacAddr = _macAddrToBinary($macAddr) or die "Invalid MAC address\n";
	return "\xFF\xFF\xFF\xFF\xFF\xFF" . ($binMacAddr x 16);
}

sub sendWOL {
	my ($macAddr, $ipAddr, $port) = @_;

	$port = DEFAULT_UDP_PORT unless $port;

	socket my $socket, PF_INET, SOCK_DGRAM, getprotobyname('udp') or die "Could not create socket: $!\n";
	my $ip = gethostbyname($ipAddr) or die "Could not get IP address: $!\n";
	my $sin = sockaddr_in($port, $ip);
	send $socket, _getMagicPacket($macAddr), 0, $sin or die "Could not send magic packet: $!\n";
}

1;
