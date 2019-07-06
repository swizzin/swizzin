#!/bin/bash
#
# [Quick Box :: Install Radarr package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/QB
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   PastaGringo | KarmaPoliceT2
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#################################################################################
function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }
#################################################################################

function _installRadarrIntro() {
  echo "Radarr will now be installed." >>"${OUTTO}" 2>&1;
  echo "This process may take up to 2 minutes." >>"${OUTTO}" 2>&1;
  echo "Please wait until install is completed." >>"${OUTTO}" 2>&1;
  # output to box
  echo "Radarr will now be installed."
  echo "This process may take up to 2 minutes."
  echo "Please wait until install is completed."
  echo
  sleep 5
}

function _installRadarrDependencies() {
  # output to box
  echo "Installing dependencies ... "
  mono_repo_setup
}

function _installRadarrCode() {
  # output to box
  apt-get -y -q update > /dev/null 2>&1
  apt-get install -y libmono-cil-dev curl mediainfo >/dev/null 2>&1
  echo "Installing Radar ... "
  if [[ ! -d /opt ]]; then mkdir /opt; fi
  cd /opt
  wget $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 ) > /dev/null 2>&1
  tar -xvzf Radarr.*.linux.tar.gz >/dev/null 2>&1
  rm -rf /opt/Radarr.*.linux.tar.gz
  touch /install/.radarr.lock
}

function _installRadarrConfigure() {
  # output to box
  echo "Configuring Radar ... "
cat > /etc/systemd/system/radarr.service <<EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=${username}
Group=${username}
Type=simple
ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


  mkdir -p /home/${username}/.config
  chown -R ${username}:${username} /home/${username}/.config
  chmod 775 /home/${username}/.config
  chown -R ${username}:${username} /opt/Radarr/
  systemctl daemon-reload
  systemctl enable radarr.service > /dev/null 2>&1
  systemctl start radarr.service

  if [[ -f /install/.nginx.lock ]]; then
    sleep 10
    bash /usr/local/bin/swizzin/nginx/radarr.sh
    service nginx reload
  fi
}

function _installRadarrFinish() {
  # output to dashboard
  echo "Radarr Install Complete!" >>"${OUTTO}" 2>&1;
  echo "You can access it at  : http://$ip/radarr" >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
  # output to box
  echo "Radarr Install Complete!"
  echo "You can access it at  : http://$ip/radarr"
  echo
  echo "Close this dialog box to refresh your browser"
}

function _installRadarrExit() {
	exit 0
}

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
username=$(cat /root/.master.info | cut -d: -f1)
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
. /etc/swizzin/sources/functions/mono
ip=$(curl -s http://whatismyip.akamai.com)

_installRadarrIntro
echo "Installing dependencies ... " >>"${OUTTO}" 2>&1;_installRadarrDependencies
echo "Installing Radar ... " >>"${OUTTO}" 2>&1;_installRadarrCode
echo "Configuring Radar ... " >>"${OUTTO}" 2>&1;_installRadarrConfigure
_installRadarrFinish
_installRadarrExit
