#!/bin/bash
#
# [Quick Box :: Uninstaller for Deluge package]
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
username=$(cat /etc/apache2/master.txt)
OUTTO="/root/quick-box.log"
local_setup=/etc/QuickBox/setup/

function _removeDeluge() {
  killall deluged
  killall deluge-web
  ##cp "${local_setup}"templates/startup.template /home/"${username}"/.startup
    sleep 5
  systemctl disable deluged@* > /dev/null 2>&1
  systemctl stop deluged@* > /dev/null 2>&1
  rm /etc/systemd/system/deluged@.service > /dev/null 2>&1
  rm /etc/systemd/system/deluge-web@.service > /dev/null 2>&1
  sudo rm /install/.deluge.lock

  cd /home/"$username"
  sudo rm -r .config/deluge

}

_removeDeluge
