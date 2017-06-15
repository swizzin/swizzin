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
# Parses an XML-RPC response
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::XmlRpcResponseParser;
use AutodlIrssi::XmlParser;
use base qw/ AutodlIrssi::XmlParser /;

sub _parseValue {
	my ($self, $valueElem) = @_;

	my @children = $self->getChildElements($valueElem);
	die "<value> element does not have exactly one child\n" if @children != 1;

	my $child = $children[0];
	my $elemName = $child->nodeName;
	my $value;
	if ($elemName eq 'int' || $elemName eq 'i4' || $elemName eq 'i8') {
		$value = $self->readTextNodeInteger($child, undef, undef);
		return $value if defined $value;
	}
	elsif ($elemName eq 'boolean') {
		$value = $self->readTextNodeInteger($child, undef, undef);
		return $value if defined $value && ($value == 0 || $value == 1);
	}
	elsif ($elemName eq 'string') {
		$value = $self->readTextNode($child, undef, "");
		return $value if defined $value;
	}
	elsif ($elemName eq 'double') {
		$value = $self->readTextNode($child, undef, undef);
		return $value if defined $value;
	}
	elsif ($elemName eq 'array') {
		my $dataElem = $self->getTheChildElement($child, "data");
		my $ary = [];
		for my $valueElem ($self->getChildElementsByTagName($dataElem, "value")) {
			push @$ary, $self->_parseValue($valueElem);
		}
		return $ary;
	}
	elsif ($elemName eq 'struct') {
		my $obj = {};
		for my $memberElem ($self->getChildElementsByTagName($child, "member")) {
			my $name = $self->readTextNode($memberElem, "name");
			my $valueElem = $self->getOptionalChildElement($memberElem, "value");
			die "Missing struct <value> elem\n" unless defined $valueElem;
			die "Missing struct <name> elem\n" unless defined $name;
			$obj->{$name} = $self->_parseValue($valueElem);
		}
		return $obj;
	}
	else {
		# These are not supported: dateTime.iso8601, base64
		die "Unsupported XML-RPC type $elemName\n";
	}

	die "Invalid <$elemName> value\n";
}

sub parse {
	my ($self, $xmlData) = @_;

	my $doc = eval { $self->openString($xmlData) };
	die "Invalid XML-RPC response (not XML)\n" if $@;

	my $root = $self->getTheChildElement($doc, "methodResponse");
	if (my $elem = $self->getOptionalChildElement($root, "params")) {
		$elem = $self->getTheChildElement($elem, "param");
		$elem = $self->getTheChildElement($elem, "value");
		return {
			errorCode => undef,
			errorString => undef,
			value => $self->_parseValue($elem),
		};
	}
	elsif ($elem = $self->getOptionalChildElement($root, "fault")) {
		$elem = $self->getTheChildElement($elem, "value");
		my $fault = $self->_parseValue($elem);
		if (!ref $fault || !defined $fault->{faultCode} || !defined $fault->{faultString}) {
			die "Invalid <fault> result\n";
		}
		return {
			errorCode => 0+sprintf("%d", 0+$fault->{faultCode}),	# Make sure it's an int
			errorString => "$fault->{faultString}",	# Make sure it's a string
			value => undef,
		};
	}
	else {
		die "Invalid XML-RPC response (not params or fault)\n";
	}
}

1;
