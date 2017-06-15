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
# Class for parsing XML files into DOM documents.
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::XmlParser;
use AutodlIrssi::TextUtils;
use XML::LibXML;

sub new {
	my $class = shift;
	bless {}, $class;
}

# Opens an XML file and returns the DOM document. $self->{filename} will be initialized to the
# filename. An exception is thrown if we couldn't parse the file.
sub openFile {
	my ($self, $filename) = @_;

	$self->{filename} = $filename;

	my $doc = eval { XML::LibXML->new()->parse_file($filename) };
	die "Error parsing $filename: $@\n" if $@;

	return $doc;
}

# Creates an XML document from XML data passed in as a string. An exception is thrown if we
# couldn't parse the string.
sub openString {
	my ($self, $xmlData) = @_;

	my $doc = eval { XML::LibXML->new()->parse_string($xmlData) };
	die "Error parsing XML data: $@\n" if $@;

	return $doc;
}

# Returns all child elements of $elem that have nodeName eq $childElemName
sub getChildElementsByTagName {
	my ($self, $elem, $childElemName) = @_;

	return map {
		$_->nodeType == 1 && $_->nodeName eq $childElemName ? $_ : ()
	} $elem->childNodes;
}

# Returns all child elements of $elem
sub getChildElements {
	my ($self, $elem) = @_;

	return map {
		$_->nodeType == 1 ? $_ : ()
	} $elem->childNodes;
}

sub getTheChildElement {
	my ($self, $elem, $childElemName) = @_;
	my @ary = $self->getChildElementsByTagName($elem, $childElemName);
	die "Could not find one and only one child element named '$childElemName'\n" unless @ary == 1;
	return $ary[0];
}

sub getOptionalChildElement {
	my ($self, $elem, $childElemName) = @_;
	my @ary = $self->getChildElementsByTagName($elem, $childElemName);
	return $ary[0];
}

# Returns the value of the text node in a child element. $elem is the element which must have a
# child element called $childElemName. $defaultValue is returned if the child element isn't found.
sub readTextNode {
	my ($self, $elem, $childElemName, $defaultValue) = @_;

	my $child;
	if (defined $childElemName) {
		my @ary = $self->getChildElementsByTagName($elem, $childElemName);
		return $defaultValue if !@ary;
		$child = $ary[0]->firstChild;
	}
	else {
		$child = $elem->firstChild;
	}

	return $defaultValue if !defined $child || $child->nodeType != 3;

	# Trim the string, including newlines
	my $s = $child->nodeValue;
	$s =~ s/^\s+//m;
	$s =~ s/\s+$//m;
	return $s;
}

# Returns the boolean value (0 or 1) of a child element's text node
sub readTextNodeBoolean {
	my ($self, $elem, $childElemName, $defaultValue) = @_;

	my $strVal = $self->readTextNode($elem, $childElemName);
	return $defaultValue if !defined $strVal;
	return convertStringToBoolean($strVal);
}

# Returns the integer value of a child element's text node
sub readTextNodeInteger {
	my ($self, $elem, $childElemName, $defaultValue, $minValue, $maxValue) = @_;

	my $strVal = $self->readTextNode($elem, $childElemName);
	return $defaultValue if !defined $strVal;
	return convertStringToInteger($strVal, $defaultValue, $minValue, $maxValue);
}

# Returns the attribute of an element, or $defaultValue if the attribute doesn't exist.
sub readAttribute {
	my ($self, $elem, $attrName, $defaultValue) = @_;

	return $defaultValue unless $elem->hasAttribute($attrName);
	return $elem->getAttribute($attrName);
}

# Reads the attribute and converts it to a boolean. Uses $defaultValue if attribute doesn't exist.
sub readAttributeBoolean {
	my ($self, $elem, $attrName, $defaultValue) = @_;

	my $strVal = $self->readAttribute($elem, $attrName);
	return $defaultValue if !defined $strVal;
	return convertStringToBoolean($strVal);
}

# Reads the attribute and converts it to an integer. Uses $defaultValue if attribute doesn't exist.
sub readAttributeInteger {
	my ($self, $elem, $attrName, $defaultValue, $minValue, $maxValue) = @_;

	my $strVal = $self->readAttribute($elem, $attrName);
	return $defaultValue if !defined $strVal;
	return convertStringToInteger($strVal, $defaultValue, $minValue, $maxValue);
}

sub createDocument {
	my $self = shift;
	return new XML::LibXML::Document();
}

1;
