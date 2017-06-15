#!/bin/bash
#
# [Quick Box :: Remove plexmediaserver package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO
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

function _removePlex() {
  dpkg -r plexmediaserver >/dev/null 2>&1
  sudo apt-get -y purge plexmediaserver >/dev/null 2>&1
  rm -f /etc/systemd/system/plexmediaserver.service
  systemctl daemon-reload >/dev/null 2>&1
  rm -rf /var/lib/plexmediaserver
  rm -rf /usr/lib/plexmediaserver
  rm /etc/init/plexmediaserver.conf
  rm /etc/default/plexmediaserver
  rm /etc/apache2/conf-available/fqdn.conf
  rm /etc/apache2/conf-enabled/fqdn.conf
  rm /etc/apache2/sites-enabled/plex.conf
  rm /srv/rutorrent/home/.plex
  rm /install/.plex.lock
  sudo userdel plex >/dev/null 2>&1
  pkill -f plex
}

_removePlex
