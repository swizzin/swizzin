#!/bin/bash
#
# [Quick Box :: Install Resilio Sync (BTSync) package]
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
MASTER=$(cat /srv/rutorrent/home/db/master.txt)
BTSYNCIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/

function _installBTSync1() {
  #sudo sh -c 'echo "deb http://linux-packages.getsync.com/btsync/deb btsync non-free" > /etc/apt/sources.list.d/btsync.list'
  #wget -qO - http://linux-packages.getsync.com/btsync/key.asc | sudo apt-key add - >/dev/null 2>&1
  sudo sh -c 'echo "deb http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" > /etc/apt/sources.list.d/btsync.list'
  wget -qO - https://linux-packages.resilio.com/resilio-sync/key.asc | sudo apt-key add - >/dev/null 2>&1
}
function _installBTSync2() {
  sudo apt-get update >/dev/null 2>&1
}
function _installBTSync3() {
  #sudo apt-get -y -q install btsync >/dev/null 2>&1
  cd && mkdir -p /home/"${MASTER}"/.config/resilio-sync/storage/
  sudo apt-get install resilio-sync >/dev/null 2>&1
}
function _installBTSync4() {
  cd && mkdir /home/"${MASTER}"/sync_folder
  sudo chown ${MASTER}:rslsync /home/${MASTER}/sync_folder
  sudo chmod 2775 /home/${MASTER}/sync_folder
  sudo chown ${MASTER}:rslsync -R /home/${MASTER}/.config/resilio-sync
  sudo usermod -a -G rslsync ${MASTER} >/dev/null 2>&1
}
function _installBTSync5() {
  cp -r ${local_setup}templates/btsync/config.json.template /etc/resilio-sync/config.json
  cp -r ${local_setup}templates/btsync/user_config.json.template /etc/resilio-sync/user_config.json
  sudo sed -i "s/BTSGUIP/$BTSYNCIP/g" /etc/resilio-sync/config.json
  sudo sed -i "s/BTSGUIP/$BTSYNCIP/g" /etc/resilio-sync/user_config.json
  cp /var/run/resilio-sync/sync.pid /home/${MASTER}/.config/resilio-sync/sync.pid
}
function _installBTSync6() {
  touch /install/.btsync.lock
  systemctl enable resilio-sync >/dev/null 2>&1
  systemctl start resilio-sync >/dev/null 2>&1
  systemctl restart resilio-sync >/dev/null 2>&1
}
function _installBTSync7() {
  echo "BTSync Install Complete!" >>"${OUTTO}" 2>&1;
  sleep 5
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}
function _installBTSync8() {
  exit
}

echo "Installing btsync keys and sources ... " >>"${OUTTO}" 2>&1;_installBTSync1
echo "Updating system ... " >>"${OUTTO}" 2>&1;_installBTSync2
echo "Installing btsync ... " >>"${OUTTO}" 2>&1;_installBTSync3
echo "Setting up btsync permissions ... " >>"${OUTTO}" 2>&1;_installBTSync4
echo "Setting up btsync configurations ... " >>"${OUTTO}" 2>&1;_installBTSync5
echo "Starting btsync ... " >>"${OUTTO}" 2>&1;_installBTSync6
_installBTSync7
_installBTSync8
