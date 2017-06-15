#!/bin/bash
#
# [Quick Box :: Install SickRage package]
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
OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/

function _installSickRage1() {
  sudo git clone https://github.com/SickRage/SickRage.git  /home/"${MASTER}"/.sickrage >/dev/null 2>&1
}
function _installSickRage2() {
  touch /install/.sickrage.lock
  chown "${MASTER}":"${MASTER}" -R /home/"${MASTER}"/.sickrage


}
function _installSickRage3() {
  cp ${local_setup}templates/sysd/sickrage.template /etc/systemd/system/sickrage@.service
  systemctl enable sickrage@${MASTER} > /dev/null 2>&1
  systemctl start sickrage@${MASTER} > /dev/null 2>&1
  systemctl stop sickrage@${MASTER} > /dev/null 2>&1

  sed -i "s/web_root.*/web_root = \"sickrage\"/g" /home/"${MASTER}"/.sickrage/config.ini
  sed -i "s/web_host.*/web_host = localhost/g" /home/"${MASTER}"/.sickrage/config.ini
  cat > /etc/apache2/sites-enabled/sickrage.conf <<EOF
<Location /sickrage>
  ProxyPass http://localhost:8081/sickrage
  ProxyPassReverse http://localhost:8081/sickrage
  AuthType Digest
  AuthName "rutorrent"
  AuthUserFile '/etc/htpasswd'
  Require user ${MASTER}
</Location>
EOF
  chown www-data: /etc/apache2/sites-enabled/sickrage.conf
  service apache2 reload
  systemctl start sickrage@${MASTER} > /dev/null 2>&1

}


function _installSickRage4() {
  echo "SickRage Install Complete!" >>"${OUTTO}" 2>&1;
  sleep 5
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}
function _installSickRage5() {
  exit
}

echo "Installing sickrage ... " >>"${OUTTO}" 2>&1;_installSickRage1
echo "Setting up sickrage permissions ... " >>"${OUTTO}" 2>&1;_installSickRage2
echo "Setting up sickrage configurations and enabling ... " >>"${OUTTO}" 2>&1;_installSickRage3
_installSickRage4
_installSickRage5
