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
# Keeps track of all active connections
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::ActiveConnections;
use AutodlIrssi::Globals;

# Max number of seconds a connection is allowed to be alive before we mark it as a memory leak
use constant MAX_CONNECTION_TIME_SECS => 15*60;

sub new {
	my $class = shift;
	bless {
		connections => {},
		nextId => 0,
	}, $class;
}

sub cleanUp {
	my $self = shift;
}

# Adds the connection, returning a unique id that should be passed to remove(). This method should
# be called in the constructor.
sub add {
	my ($self, $obj, $name) = @_;

	return unless $AutodlIrssi::g->{options}{memoryLeakCheck};

	my $id = $self->{nextId}++;
	my $info;
	$self->{connections}{$id} = $info = {
		time => time(),
		class => ref $obj,
		name => $name,
	};

	dmessage 5, "Added connection: id: $id, class: $info->{class}, name: '$info->{name}'";

	return $id;
}

# Removes the connection. The $id is the same id returned by add(). Should be called in the dtor.
sub remove {
	my ($self, $id) = @_;

	return unless $AutodlIrssi::g->{options}{memoryLeakCheck};

	if (!exists $self->{connections}{$id}) {
		message 0, "ActiveConnections: Could not find id $id";
		return;
	}

	delete $self->{connections}{$id};
	dmessage 5, "Removed connection: id: $id";
}

sub reportMemoryLeaks {
	my $self = shift;

	my $currTime = time();
	while (my ($id, $info) = each %{$self->{connections}}) {	
		if ($currTime - $info->{time} > MAX_CONNECTION_TIME_SECS) {
			message 0, "Memory leak: id: $id, class: $info->{class}, name: '$info->{name}'";
			delete $self->{connections}{$id};
		}
	}
}

1;
