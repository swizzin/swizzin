#!/bin/bash
#
# [Quick Box :: Remove emby-server package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

function _removeEmby() {
  dpkg -r emby-server >/dev/null 2>&1
  sudo apt-get purge -y emby-server >/dev/null 2>&1
  rm -rf /etc/apt/sources.list.d/emby-server.list
  rm -rf /etc/apache2/sites-enabled/emby.conf
  rm -rf /install/.emby.lock
  pkill -f emby-server
}

_removeEmby
