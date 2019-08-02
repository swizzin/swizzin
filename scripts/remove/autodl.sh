#!/bin/bash
#
# [Quick Box :: Remove AutoDL-IRSSI package]
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

function _removepackage-autodl() {
  username=$(whoami);
  users=($(cut -d: -f1 < /etc/htpasswd))
  rutorrent="/srv/rutorrent/";
  PLUGIN="autodl-irssi"
    for i in $PLUGIN; do
      rm -rf "${rutorrent}/plugins/$i"
    done
      systemctl stop irssi@*
      systemctl disable irssi@*
      rm /etc/systemd/system/irssi@.service
    for u in "${users[@]}"; do
      rm -rf /home/${u}/.autodl
      rm -rf /home/${u}/.irssi
    done
    rm /install/.autodl.lock

}

_removepackage-autodl
