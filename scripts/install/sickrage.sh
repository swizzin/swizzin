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

function _rar() {
  if [[ -z $(which rar) ]]; then
    cd /tmp
    wget -q http://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
    tar -xzf rarlinux-x64-5.5.0.tar.gz >/dev/null 2>&1
    cp rar/*rar /bin >/dev/null 2>&1
    rm -rf rarlinux*.tar.gz >/dev/null 2>&1
    rm -rf /tmp/rar >/dev/null 2>&1
  fi
}

function _installSickRage1() {
  apt-get -y -q update >> $log 2>&1
  apt-get -y -q install git-core openssl libssl-dev python2.7 >> $log 2>&1

  if [[ $distribution == "Debian" ]]; then
    _rar
  else
    apt-get -y install rar unrar >>$log 2>&1 || echo "INFO: Could not find rar/unrar in the repositories. It is likely you do not have the multiverse repo enabled. Installing directly."; _rar
  fi
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

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sickrage.sh
  service nginx reload
fi
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
