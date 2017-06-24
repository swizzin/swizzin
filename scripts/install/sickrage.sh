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
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
local_setup=/etc/QuickBox/setup/

function _installSickRage1() {
  sudo git clone https://github.com/SickRage/SickRage.git  /home/"${MASTER}"/.sickrage >/dev/null 2>&1
}
function _installSickRage2() {
  touch /install/.sickrage.lock
  chown "${MASTER}":"${MASTER}" -R /home/"${MASTER}"/.sickrage


}
function _installSickRage3() {
  cat > /etc/systemd/system/sickrage@.service <<SRS
[Unit]
Description=SickRage
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=%I
Group=%I
ExecStart=/usr/bin/python /home/%I/.sickrage/SickBeard.py -q --daemon --nolaunch --datadir=/home/%I/.sickrage
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
SRS
  systemctl enable sickrage@${MASTER} > /dev/null 2>&1
  systemctl start sickrage@${MASTER} > /dev/null 2>&1
  systemctl stop sickrage@${MASTER} > /dev/null 2>&1

  sed -i "s/web_root.*/web_root = \"sickrage\"/g" /home/"${MASTER}"/.sickrage/config.ini
  sed -i "s/web_host.*/web_host = localhost/g" /home/"${MASTER}"/.sickrage/config.ini
  cat > /etc/nginx/apps/sickrage.conf <<EOF
  location / {
      proxy_pass        http://127.0.0.1:8081/sickrage;
      proxy_set_header  X-Real-IP  \$remote_addr;
      proxy_set_header        Host            \$host;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;
      proxy_redirect off;
      auth_basic "What's the password?";
      auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
  }
EOF
  service nginx reload
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
