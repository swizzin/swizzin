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
users=($(cat /etc/htpasswd | cut -d ":" -f 1))
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

function _removeDeluge() {
  killall deluged
  killall deluge-web
    sleep 5
  systemctl disable deluged@* > /dev/null 2>&1
  systemctl stop deluged@* > /dev/null 2>&1
  rm /etc/systemd/system/deluged@.service > /dev/null 2>&1
  rm /etc/systemd/system/deluge-web@.service > /dev/null 2>&1
  rm -rf /usr/lib/python2.7/dist-packages/deluge*
  dpkg -r libtorrent
  apt-get purge -y deluge > /dev/null 2>&1

  sudo rm /install/.deluge.lock
  for u in ${users}; do
    rm -rf /home/${u}/.config/deluge
  done
}

_removeDeluge
