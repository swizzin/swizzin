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
# Call an XML-RPC function
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::XmlRpcSimpleCall;
use AutodlIrssi::XmlRpc;
use base qw/ AutodlIrssi::XmlRpc /;

sub method {
	my ($self, $methodName) = @_;

	$self->_addElems('<methodCall><methodName>');
	$self->_addUserData($methodName);
	$self->_addElems('</methodName><params>');
	$self->_addElems('<param><value><string></string></value></param>');

	return $self;
}

sub methodEnd {
	my $self = shift;

	$self->_addElems('</params></methodCall>');

	return $self;
}

# Add a string argument.
sub string {
	my ($self, $string) = @_;

	$self->_addElems('<param><value><string>');
	$self->_addUserData($string);
	$self->_addElems('</string></value></param>');

	return $self;
}

1;
