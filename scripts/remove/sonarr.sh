#!/bin/bash
#
# [Quick Box :: Remove Sonarr-NzbDrone package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
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
username=$(cut -d: -f1 < /root/.master.info)
local_setup=/etc/QuickBox/setup/

function _removeSonarr() {
  systemctl stop sonarr@${username}
  systemctl disable sonarr@${username}
  apt_remove nzbdrone
  rm -f /etc/apt/sources.list.d/sonarr.list
  rm -f /etc/nginx/apps/sonarr.conf
  if [[ -f /etc/init.d/sonarr ]]; then
    sudo update-rc.d -f sonarr remove >/dev/null 2>&1
    sudo rm /etc/default/sonarr
    sudo rm /etc/init.d/sonarr
  fi
    sudo rm /install/.sonarr.lock
    systemctl reload nginx
}

_removeSonarr
