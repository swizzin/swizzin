#!/bin/bash
#
# [Quick Box :: Remove Resilio Sync (BTSync) package]
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
MASTER=$(cat /etc/apache2/master.txt)
OUTTO="/root/quick-box.log"

function _removeBTSync() {
  sudo service resilio-sync stop
  sudo apt-get -y remove --purge resilio-sync* >>"${OUTTO}" 2>&1
  rm -rf /home/${MASTER}/sync_folder
  rm /install/.btsync.lock
  sudo service apache2 reload
}

_removeBTSync
