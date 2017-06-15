#!/bin/bash
#
# [Quick Box :: Uninstaller for SickRage package]
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
MASTER=$(cat /etc/apache2/master.txt)
OUTTO="/root/quick-box.log"

function _removeSickRage() {
  if [[ -f /etc/init.d/sickrage ]]; then
    sudo service sickrage stop
    sudo update-rc.d -f sickrage remove
    sudo rm /etc/default/sickrage > /dev/null 2>&1
    sudo rm /etc/init.d/sickrage > /dev/null 2>&1
  fi
    systemctl disable sickrage@${MASTER}
    systemctl stop sickrage@${MASTER}


  sudo rm -r /var/run/sickrage > /dev/null 2>&1
  sudo rm /etc/apache2/sites-enabled/sickrage.conf > /dev/null 2>&1
  sudo rm /etc/systemd/sickrage@.service > /dev/null 2>&1
  sudo rm /install/.sickrage.lock
  service apache2 reload

  cd /home/"$MASTER"
  sudo rm -r .sickrage

  echo -n "Verifying SickRage removal from /home/$MASTER directory"
  echo ""
  ls -al
  echo ""
  echo ""
  echo "SickRage Uninstall Complete. You may reinstall at any time by running [installpackage-sickrage]."

}

_removeSickRage
