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
# This is where we start. Called by Irssi.
# This file will load Startup.pm.
#

use 5.008;
use strict;
use warnings;
use Symbol;

BEGIN {
	# Delete all of our modules from the %INC hash so they can be reloaded.
	sub deleteOurModules {
		my @deleteThese;
		while (my ($moduleName, $modulePathName) = each %INC) {
			next unless defined $moduleName && defined $modulePathName;
			next unless $modulePathName =~ m!/AutodlIrssi/!;
			push @deleteThese, $moduleName;
		}
		delete $INC{$_} for @deleteThese;
	}

	# Deletes the package and any subpackages. Eg. deleteOldPackages('main::') would delete ALL
	# packages that are loaded!
	sub deleteOldPackages {
		my $ns = shift;
		my $hashRef;
		{
			no strict 'refs';
			$hashRef = \%$ns
		}
		for my $key (keys %$hashRef) {
			next unless $key =~ /::$/;
			next if $key eq "main::";
			deleteOldPackages($ns . $key);
		}
		$ns =~ /^(.*)::$/;
		Symbol::delete_package($1);
	}

	# To support reloading all of the script, including the code loaded using 'use', we must first
	# delete all traces of our code that's already in memory.
	sub deleteOurPackagesAndModules {
		deleteOldPackages("AutodlIrssi::");
		deleteOurModules();
	}

	deleteOurPackagesAndModules();
}

# Now load Startup
use AutodlIrssi::Startup;

# Called by Irssi when this module is unloaded (eg. when reloading the script or when exiting irssi)
sub UNLOAD {
	eval {
		AutodlIrssi::disable()
	};

	# Remove all global data
	$AutodlIrssi::g = undef;

	deleteOurPackagesAndModules();
}

AutodlIrssi::enable();
