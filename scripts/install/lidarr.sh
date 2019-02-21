#!/bin/bash
#
# [Quick Box :: Install Lidarr package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/QB
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   KaraokeStu | ts050
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2018 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

distribution=$(lsb_release -is)
version=$(lsb_release -cs)
username=$(cat /root/.master.info | cut -d: -f1)
lidarrver=$(wget -q https://github.com/lidarr/Lidarr/releases -O -| grep -E \/tag\/ | grep -v repository | awk -F "[><]" 'NR==1{print $3}')

function _depends() {
if ls /etc/apt/sources.list.d/mono-* >/dev/null 2>&1; then
    ls /etc/apt/sources.list.d/mono-* >/dev/null 2>&1;
fi
for list in /etc/apt/sources.list.d/mono-*; do
    if [[ -f $list ]]; then
        rm -rf /etc/apt/sources.list.d/mono-*
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
        echo "deb http://download.mono-project.com/repo/ubuntu stable-xenial main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
        break
    fi
done
	apt-get -y update && apt-get -y upgrade >/dev/null 2>&1
	apt-get install -y libmono-cil-dev curl mediainfo >/dev/null 2>&1
}

function _installLidarrCode() {
  cd /opt
  wget -q https://github.com/lidarr/Lidarr/releases/download/v$lidarrver/Lidarr.develop.$lidarrver.linux.tar.gz
  tar -xvzf Lidarr.develop.*.linux.tar.gz >/dev/null 2>&1
  rm -rf /opt/Lidarr.develop.*.linux.tar.gz
  chown ${username}.${username} -R Lidarr
  touch /install/.lidarr.lock
}

function _installLidarrConfigure() {
  # output to box
  echo "Configuring Lidarr ... "
cat > /etc/systemd/system/lidarr.service <<LIDARR
[Unit]
Description=Lidarr Daemon
After=syslog.target network.target

[Service]
User=${username}
Group=${username}
Type=simple
ExecStart=/usr/bin/mono /opt/Lidarr/Lidarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
LIDARR

  if [[ -f /install/.nginx.lock ]]; then
    sleep 10
    bash /usr/local/bin/swizzin/nginx/sonarr.sh
    service nginx reload
  fi

  mkdir -p /home/${username}/.config
  chown -R ${username}:${username} /home/${username}/.config
  chmod 775 /home/${username}/.config
  chown -R ${username}:${username} /opt/Lidarr/
  chown www-data:www-data /etc/apache2/sites-enabled/lidarr.conf
  systemctl daemon-reload
  systemctl enable lidarr.service > /dev/null 2>&1
  systemctl start lidarr.service
  sleep 10

  cp ${local_setup}configs/Lidarr/config.xml /home/${username}/.config/Lidarr/config.xml
  chown ${username}:${username} /home/${username}/.config/Lidarr/config.xml

  systemctl stop lidarr.service
  sleep 10
}

function _installLidarrStart() {
  # output to box
  echo "Starting Lidarr ... "
  systemctl start lidarr.service
}

function _installLidarrFinish() {
  # output to dashboard
  echo "Lidarr Install Complete!" >>"${OUTTO}" 2>&1;
  echo "You can access it at  : http://$ip/lidarr" >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
  # output to box
  echo "Lidarr Install Complete!"
  echo "You can access it at  : http://$ip/lidarr"
  echo
  echo "Close this dialog box to refresh your browser"
}

function _installLidarrExit() {
	exit 0
}

OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/
local_packages=/etc/QuickBox/packages/
username=$(cat /srv/rutorrent/home/db/master.txt)
distribution=$(lsb_release -is)
ip=$(curl -s http://whatismyip.akamai.com)

_installLidarrIntro
echo "Installing dependencies ... " >>"${OUTTO}" 2>&1;_installLidarrDependencies
echo "Installing Lidarr ... " >>"${OUTTO}" 2>&1;_installLidarrCode
echo "Configuring Lidarr ... " >>"${OUTTO}" 2>&1;_installLidarrConfigure
echo "Starting Lidarr ... " >>"${OUTTO}" 2>&1;_installLidarrStart
_installLidarrFinish
_installLidarrExit
