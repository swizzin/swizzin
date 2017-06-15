#!/bin/bash
#
# [Quick Box :: Remove quassel package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | liara
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

distribution=$(lsb_release -is)
release=$(lsb_release -cs)

if [[ $distribution == Ubuntu ]]; then
	apt-get purge quassel-core* >/dev/null 2>&1
  rm /etc/apt/sources.list.d/mamarley-ubuntu-quassel-${release}.list
  apt-get -q -y update >/dev/null 2>&1
  rm /install/.quassel.lock
else
 dpkg -r quassel-core* >/dev/null 2>&1
 apt-get autoremove -y -q >/dev/null 2>&1
 rm /install/.quassel.lock
fi
