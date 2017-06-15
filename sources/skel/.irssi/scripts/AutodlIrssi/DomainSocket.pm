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
# Unix domain socket
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::DomainSocket;
use AutodlIrssi::Socket;
use base qw/ AutodlIrssi::Socket /;
use AutodlIrssi::Globals;

sub connect {
	my ($self, $socketPath, $callback) = @_;

	eval {
		$self->_createSocket();
		$self->_startConnect($socketPath);
		$self->_installHandler(0, sub {
			my $error = shift;
			if ($error) {
				$self->_callUserShutdown($callback, $error);
			}
			else {
				$self->_nowConnected();
				$self->_callUser($callback, "");
			}
		});
	};
	if ($@) {
		chomp $@;
		$self->_callUserShutdown($callback, $@);
	}
}

sub _createSocket {
	shift->_domain_createSocket();
}

sub _startConnect {
	shift->_domain_startConnect(@_);
}

1;
