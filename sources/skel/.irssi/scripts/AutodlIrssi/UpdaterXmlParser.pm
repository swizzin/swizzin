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
# Parses the update.xml file
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::UpdaterXmlParser;
use AutodlIrssi::XmlParser;
use base qw/ AutodlIrssi::XmlParser /;

sub parse {
	my ($self, $xmlData) = @_;

	my $doc = $self->openString($xmlData);
	my $updateElem = $self->getTheChildElement($doc, "update");
	my $irssiElem = $self->getTheChildElement($updateElem, "irssi");

	my $autodlElem = $self->getTheChildElement($irssiElem, "autodl");
	$self->_parseAutodlElement($autodlElem);

	my $trackersElem = $self->getTheChildElement($irssiElem, "trackers");
	$self->_parseTrackersElement($trackersElem);
}

sub _parseAutodlElement {
	my ($self, $autodlElem) = @_;

	$self->{autodl} = {
		version		=> $self->readTextNode($autodlElem, "version"),
		whatsNew	=> $self->readTextNode($autodlElem, "whats-new"),
		url			=> $self->readTextNode($autodlElem, "url"),
		modules		=> [],
	};
	if (!defined $self->{autodl}{version} || !defined $self->{autodl}{whatsNew} ||
		!defined $self->{autodl}{url} || $self->{autodl}{version} !~ /^\d\.\d\d$/) {
		die "Invalid XML file\n";
	}
	$self->{autodl}{whatsNew} =~ s/^\s+//mg;

	my $modulesElem = $self->getTheChildElement($autodlElem, "modules");
	for my $moduleElem ($self->getChildElementsByTagName($modulesElem, 'module')) {
		my $moduleName = $self->readAttribute($moduleElem, "name");
		die "Invalid module name\n" unless $moduleName =~ /^[\w:]+$/;
		push @{$self->{autodl}{modules}}, {
			name => $moduleName,
		};
	}
}

sub _parseTrackersElement {
	my ($self, $trackersElem) = @_;

	$self->{trackers} = {
		version	=> $self->readTextNode($trackersElem, "version"),
		whatsNew	=> $self->readTextNode($trackersElem, "whats-new"),
		url		=> $self->readTextNode($trackersElem, "url"),
	};
	if (!defined $self->{trackers}{version} || !defined $self->{trackers}{whatsNew}
		|| !defined $self->{trackers}{url} || $self->{trackers}{version} !~ /^\d+$/) {
		die "Invalid XML file\n";
	}
	$self->{trackers}{whatsNew} =~ s/^\s+//mg;
}

1;
