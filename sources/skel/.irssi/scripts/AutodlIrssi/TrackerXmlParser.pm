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
# Parses all *.tracker files
#

use 5.008;
use strict;
use warnings;

package AutodlIrssi::TrackerXmlParser;
use AutodlIrssi::Globals qw/ message /;
use AutodlIrssi::XmlParser;
use AutodlIrssi::TextUtils;
use base qw/ AutodlIrssi::XmlParser /;

# Parses a *.tracker file and returns a $trackerInfo
sub parse {
	my ($self, $filename) = @_;

	my $doc = $self->openFile($filename);

	my $trackerinfoElem = $self->getTheChildElement($doc, "trackerinfo");
	my $trackerInfo = {
		file		=> $filename,
		type		=> $self->readAttribute($trackerinfoElem, "type", ""),
		shortName	=> $self->readAttribute($trackerinfoElem, "shortName", ""),
		longName	=> $self->readAttribute($trackerinfoElem, "longName", ""),
		siteName	=> $self->readAttribute($trackerinfoElem, "siteName", ""),
		deobfuscate	=> $self->readAttribute($trackerinfoElem, "deobfuscate", ""),
		follow302	=> $self->readAttributeBoolean($trackerinfoElem, "follow302links", 0),
	};
	$self->{trackerInfo} = $trackerInfo;
	die "Invalid trackerinfo.type\n" if $trackerInfo->{type} eq "";
	die "Invalid trackerinfo.shortName\n" if $trackerInfo->{shortName} eq "";
	die "Invalid trackerinfo.longName\n" if $trackerInfo->{longName} eq "";

	$trackerInfo->{settings} = $self->parseSettings($trackerinfoElem);
	$trackerInfo->{servers} = $self->parseServers($trackerinfoElem);
	$trackerInfo->{parseInfo} = $self->parseParseInfo($trackerinfoElem);

	return $trackerInfo;
}

# Parse the settings element
sub parseSettings {
	my ($self, $trackerinfoElem) = @_;

	my $settingsElem = $self->getTheChildElement($trackerinfoElem, "settings");
	my @childElems = $self->getChildElements($settingsElem);
	die "No settings found\n" if @childElems == 0;

	my %settings;

	my $addIt = sub {
		my ($setting, $tagName) = @_;
		$self->initializeSetting($setting, $tagName);

		# Save only named settings, eg. don't save descriptions.
		if (defined $setting->{name} && $setting->{name} ne "") {
			$settings{$setting->{name}} = $setting;
		}
	};

	$addIt->({
		name => "enabled",
		type => "bool",
		defaultValue => "true",
		isDownloadVar => 0,
	});
	$addIt->({
		name => "upload-delay-secs",
		type => "integer",
		defaultValue => "0",
		isDownloadVar => 0,
	});
	$addIt->({
		name => "force-ssl",
		type => "bool",
		defaultValue => "false",
		isDownloadVar => 0,
	});

	for my $elem (@childElems) {
		my $setting = {
			name			=> $self->readAttribute($elem, "name"),
			type			=> $self->readAttribute($elem, "type"),
			defaultValue	=> $self->readAttribute($elem, "defaultValue", ""),
			isDownloadVar	=> $self->readAttributeBoolean($elem, "isDownloadVar", 1),
		};
		$addIt->($setting, $elem->nodeName);
	}

	return \%settings;
}

# Initialize some values in $setting to default values depending on its type
sub initializeSetting {
	my ($self, $setting, $tagName) = @_;

	my $setProp = sub {
		my ($name, $value) = @_;
		$setting->{$name} = $value if !defined $setting->{$name};
	};

	if (!defined $tagName) {
		# Nothing
	}
	elsif ($tagName eq "gazelle_description" || $tagName eq "description" || $tagName eq "cookie_description") {
		$setProp->("type", "description");
	}
	elsif ($tagName eq "gazelle_authkey" || $tagName eq "authkey") {
		$setProp->("type", "textbox");
		$setProp->("name", "authkey");
	}
	elsif ($tagName eq "gazelle_torrent_pass") {
		$setProp->("type", "textbox");
		$setProp->("name", "torrent_pass");
	}
	elsif ($tagName eq "passkey") {
		$setProp->("type", "textbox");
		$setProp->("name", "passkey");
	}
	elsif ($tagName eq "cookie") {
		$setProp->("type", "textbox");
		$setProp->("name", "cookie");
	}
	elsif ($tagName eq "integer") {
		$setProp->("type", "integer");
	}
	elsif ($tagName eq "delta") {
		$setProp->("type", "integer");
		$setProp->("name", "delta");
	}
	elsif ($tagName eq "textbox") {
		$setProp->("type", "textbox");
	}

	if (!defined $setting->{type}) {
		die "Missing setting.type\n";
	}
	elsif ($setting->{type} eq "bool" || $setting->{type} eq "textbox" ||
		$setting->{type} eq "integer" || $setting->{type} eq "delta") {
		die "Invalid setting.name\n" if $setting->{name} eq "";
	}
	elsif ($setting->{type} eq "description") {
		# Nothing
	}
	else {
		die "Unknown tracker setting: $setting->{type}\n";
	}
}

# Parse servers element
sub parseServers {
	my ($self, $trackerinfoElem) = @_;

	my $serversElem = $self->getTheChildElement($trackerinfoElem, "servers");
	my @childElems = $self->getChildElementsByTagName($serversElem, "server");

	my @servers;
	for my $elem (@childElems) {
		my $network = $self->readAttribute($elem, "network", "");
		my $serverNames = $self->readAttribute($elem, "serverNames", "");
		my $channelNames = $self->readAttribute($elem, "channelNames");
		my $announcerNames = $self->readAttribute($elem, "announcerNames");

		die "Invalid server.channelNames\n" if $channelNames eq "";
		die "Invalid server.announcerNames\n" if $announcerNames eq "";

		my @serverNames = map {
			trim canonicalizeServerName($_);
		} split /,/, $serverNames;
		if ($network) {
			push @serverNames, canonicalizeNetworkName($network);
		}

		for my $serverName (@serverNames) {
			next if $serverName eq "";

			my $server = {
				name			=> $serverName,
				channelNames	=> $channelNames,
				announcerNames	=> $announcerNames,
			};
			push @servers, $server;
		}
	}

	die "No servers found\n" if @servers == 0;
	return \@servers;
}

# Parse parseinfo element
sub parseParseInfo {
	my ($self, $trackerinfoElem) = @_;

	my $parseInfoElem = $self->getTheChildElement($trackerinfoElem, "parseinfo");

	my $parseInfo = {};
	$parseInfo->{linepatterns} = $self->parseLinePatterns($parseInfoElem);
	$parseInfo->{multilinepatterns} = $self->parseMultiLinePatterns($parseInfoElem);
	$parseInfo->{linematched} = $self->parseLineMatched($parseInfoElem);
	$parseInfo->{ignore} = $self->parseIgnore($parseInfoElem);
	if (!defined $parseInfo->{linepatterns} && !defined $parseInfo->{multilinepatterns}) {
		die "Invalid parseinfo, missing line patterns\n";
	}

	return $parseInfo;
}

# Parse linepatterns element
sub parseLinePatterns {
	my ($self, $parseInfoElem) = @_;

	my $linepatterns = eval { $self->getTheChildElement($parseInfoElem, "linepatterns") };
	return if $@;
	my @childElems = $self->getChildElementsByTagName($linepatterns, "extract");
	die "No linepatterns children found\n" if @childElems == 0;
	my @ary = map { $self->parseExtractElem($_) } @childElems;
	return \@ary;
}

# Parse multilinepatterns element
sub parseMultiLinePatterns {
	my ($self, $parseInfoElem) = @_;

	my $multilinepatterns = eval { $self->getTheChildElement($parseInfoElem, "multilinepatterns") };
	return if $@;
	my @childElems = $self->getChildElementsByTagName($multilinepatterns, "extract");
	die "No multilinepatterns children found\n" if @childElems == 0;
	my @ary = map { $self->parseExtractElem($_) } @childElems;
	return \@ary;
}

# Parse a <regex> element. Returns undef if missing value attribute.
sub parseRegex {
	my ($self, $regexElem) = @_;

	my $regexInfo = {
		regex		=> $self->readAttribute($regexElem, "value"),
		expected	=> $self->readAttributeBoolean($regexElem, "expected", 1),
	};
	return if !defined $regexInfo->{regex};
	my $s = $regexInfo->{regex};
	$regexInfo->{regex} = qr/$s/;
	return $regexInfo;
}

# Parse a <extract> element
sub parseExtractElem {
	my ($self, $extractElem) = @_;

	my $regexElem = $self->getTheChildElement($extractElem, "regex");
	my $varsElem = $self->getTheChildElement($extractElem, "vars");

	my @vars;
	for my $varElem ($self->getChildElementsByTagName($varsElem, "var")) {
		my $name = $self->readAttribute($varElem, "name");
		die "Invalid var.name\n" if $name eq "";
		push @vars, $name;
	}

	my $extract = {
		optional	=> $self->readAttributeBoolean($extractElem, "optional", 0),
		regexInfo	=> $self->parseRegex($regexElem),
		vars		=> \@vars,
		srcvar		=> $self->readAttribute($extractElem, "srcvar"),
	};
	die "Invalid extract.regex\n" unless $extract->{regexInfo};
	die "Invalid extract.vars\n" unless $extract->{vars};
	return $extract;
}

sub parseLineMatched {
	my ($self, $parseInfoElem) = @_;
	my $linematched = $self->getTheChildElement($parseInfoElem, "linematched");
	return $self->parseLineMatchedInternal($linematched);
}

sub parseLineMatchedInternal {
	my ($self, $rootElem) = @_;

	my @rv;

	for my $elem ($self->getChildElements($rootElem)) {
		my $obj = {};

		if ($elem->nodeName eq "var" || $elem->nodeName eq "http") {
			$obj->{type} = $elem->nodeName;
			$obj->{name} = $self->readAttribute($elem, "name");
			die "Invalid " . $elem->nodeName . ".name\n" if $obj->{name} eq "";

			$obj->{vars} = [];
			for my $childElem ($self->getChildElements($elem)) {
				if ($childElem->nodeName eq "var") {
					my $name = $self->readAttribute($childElem, "name", "");
					die "Invalid var.name\n" if $name eq "";
					push @{$obj->{vars}}, { type => "var", name => $name };
				}
				elsif ($childElem->nodeName eq "varenc") {
					my $name = $self->readAttribute($childElem, "name", "");
					die "Invalid varenc.name\n" if $name eq "";
					push @{$obj->{vars}}, { type => "varenc", name => $name };
				}
				elsif ($childElem->nodeName eq "string") {
					my $value = $self->readAttribute($childElem, "value");
					die "Invalid string.value\n" if !defined $value;
					push @{$obj->{vars}}, { type => "string", value => $value };
				}
				elsif ($childElem->nodeName eq "delta") {
					my $idName = $self->readAttribute($childElem, "idName", "");
					die "Invalid delta.idName\n" if $idName eq "";
					my $deltaName = $self->readAttribute($childElem, "deltaName", "");
					die "Invalid delta.deltaName\n" if $deltaName eq "";
					push @{$obj->{vars}}, { type => "delta", name1 => $idName, name2 => $deltaName };
				}
				else {
					die "Invalid tag " . $childElem->nodeName . "\n";
				}
			}
		}
		elsif ($elem->nodeName eq "extract") {
			$obj->{type} = "extract";
			$obj->{extract} = $self->parseExtractElem($elem);
		}
		elsif ($elem->nodeName eq "extractone") {
			$obj->{type} = "extractone";
			$obj->{ary} = [];
			for my $childElem ($self->getChildElementsByTagName($elem, "extract")) {
				push @{$obj->{ary}}, $self->parseExtractElem($childElem);
			}
		}
		elsif ($elem->nodeName eq "extracttags") {
			$obj->{type} = "extracttags";

			$obj->{srcvar} = $self->readAttribute($elem, "srcvar");
			$obj->{split} = $self->readAttribute($elem, "split");
			die "Invalid extracttags.srcvar\n" unless defined $obj->{srcvar};
			die "Invalid extracttags.split\n" unless defined $obj->{split};

			$obj->{ary} = [];
			for my $childElem ($self->getChildElementsByTagName($elem, "setvarif")) {
				push @{$obj->{ary}}, $self->parseSetVarIf($childElem);
			}

			$obj->{regexIgnore} = [];
			for my $childElem ($self->getChildElementsByTagName($elem, "regex")) {
				my $regexInfo = $self->parseRegex($childElem);
				die "Invalid extracttags ignore regex\n" unless defined $regexInfo;
				push @{$obj->{regexIgnore}}, $regexInfo;
			}
		}
		elsif ($elem->nodeName eq "varreplace") {
			$obj->{type} = "varreplace";
			$obj->{varreplace} = $self->parseVarreplace($elem);
		}
		elsif ($elem->nodeName eq "setregex") {
			$obj->{type} = "setregex";
			$obj->{setregex} = $self->parseSetregex($elem);
		}
		elsif ($elem->nodeName eq "if") {
			$obj->{type} = "if";
			$obj->{if} = $self->parseIf($elem);
		}
		else {
			die "Invalid tag " . $elem->nodeName . "\n";
		}

		push @rv, $obj;
	}

	return \@rv;
}

sub parseSetVarIf {
	my ($self, $setvarifElem) = @_;

	my $setvarif = {
		varName		=> $self->readAttribute($setvarifElem, "varName"),
		value		=> $self->readAttribute($setvarifElem, "value"),
		regex		=> $self->readAttribute($setvarifElem, "regex"),
		newValue	=> $self->readAttribute($setvarifElem, "newValue"),
	};

	die "Invalid setvarif.varName\n" unless defined $setvarif->{varName};
	die "Invalid setvarif.value/regex\n" unless defined $setvarif->{value} || defined $setvarif->{regex};

	if (defined $setvarif->{regex}) {
		my $s = $setvarif->{regex};
		$setvarif->{regex} = qr/$s/i;
	}

	return $setvarif;
}

sub parseVarreplace {
	my ($self, $varreplaceElem) = @_;

	my $varreplace = {
		name	=> $self->readAttribute($varreplaceElem, "name"),
		srcvar	=> $self->readAttribute($varreplaceElem, "srcvar"),
		regex	=> $self->readAttribute($varreplaceElem, "regex"),
		replace	=> $self->readAttribute($varreplaceElem, "replace"),
	};

	die "Invalid varreplace.name\n" unless defined $varreplace->{name};
	die "Invalid varreplace.srcvar\n" unless defined $varreplace->{srcvar};
	die "Invalid varreplace.regex\n" unless defined $varreplace->{regex};
	die "Invalid varreplace.replace\n" unless defined $varreplace->{replace};

	my $s = $varreplace->{regex};
	$varreplace->{regex} = qr/$s/;

	return $varreplace;
}

sub parseSetregex {
	my ($self, $setregexElem) = @_;

	my $setregex = {
		srcvar	=> $self->readAttribute($setregexElem, "srcvar"),
		regex	=> $self->readAttribute($setregexElem, "regex"),
		varName	=> $self->readAttribute($setregexElem, "varName"),
		newValue=> $self->readAttribute($setregexElem, "newValue"),
	};

	die "Invalid setregex.srcvar\n" unless defined $setregex->{srcvar};
	die "Invalid setregex.regex\n" unless defined $setregex->{regex};
	die "Invalid setregex.varName\n" unless defined $setregex->{varName};
	die "Invalid setregex.newValue\n" unless defined $setregex->{newValue};

	my $s = $setregex->{regex};
	$setregex->{regex} = qr/$s/i;

	return $setregex;
}

sub parseIf {
	my ($self, $ifElem) = @_;

	my $if = {
		srcvar	=> $self->readAttribute($ifElem, "srcvar"),
		regex	=> $self->readAttribute($ifElem, "regex"),
	};

	die "Invalid if.srcvar\n" unless defined $if->{srcvar};
	die "Invalid if.regex\n" unless defined $if->{regex};

	$if->{children} = $self->parseLineMatchedInternal($ifElem);
	my $s = $if->{regex};
	$if->{regex} = qr/$s/i;

	return $if;
}

sub parseIgnore {
	my ($self, $parseInfoElem) = @_;

	my $ignoreElem = $self->getTheChildElement($parseInfoElem, "ignore");

	my @rv;
	for my $childElem ($self->getChildElementsByTagName($ignoreElem, "regex")) {
		my $regexInfo = $self->parseRegex($childElem);
		die "Invalid ignore regex\n" unless defined $regexInfo;
		push @rv, $regexInfo;
	}

	return \@rv;
}

1;
