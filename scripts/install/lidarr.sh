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

function _installLidarrIntro() {
  echo "Lidarr will now be installed." >>"${OUTTO}" 2>&1;
  echo "This process may take up to 2 minutes." >>"${OUTTO}" 2>&1;
  echo "Please wait until install is completed." >>"${OUTTO}" 2>&1;
  # output to box
  echo "Lidarr will now be installed."
  echo "This process may take up to 2 minutes."
  echo "Please wait until install is completed."
  echo
  sleep 5
}

function _installLidarrDependencies() {
  if [[ ! -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
    if [[ $distribution == "Ubuntu" ]]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
    elif [[ $distribution == "Debian" ]]; then
      if [[ $version == "jessie" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
        cd /tmp
        wget -q -O libjpeg8.deb http://ftp.fr.debian.org/debian/pool/main/libj/libjpeg8/libjpeg8_8d-1+deb7u1_amd64.deb
        dpkg -i libjpeg8.deb >/dev/null 2>&1
        rm -rf libjpeg8.deb
      else
        gpg --keyserver http://keyserver.ubuntu.com --recv 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
        gpg --export 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/etc/apt/trusted.gpg.d/mono-xamarin.gpg
      fi
    fi
    echo "deb http://download.mono-project.com/repo/$(echo $distribution | awk '{print tolower($0)}') stable-$version main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  fi
  apt-get -yqq update && apt-get -yqq upgrade >/dev/null 2>&1
  apt-get install -yqq libmono-cil-dev curl mediainfo >/dev/null 2>&1
}

function _installLidarrCode() {
  if [[ ! -d /opt ]]; then mkdir /opt; fi
  cd /opt
  wget -q https://github.com/lidarr/Lidarr/releases/download/v$lidarrver/Lidarr.develop.$lidarrver.linux.tar.gz
  tar -xvzf Lidarr.develop.*.linux.tar.gz >/dev/null 2>&1
  rm -rf /opt/Lidarr.develop.*.linux.tar.gz
  touch /install/.lidarr.lock
}

function _installLidarrConfigure() {
  # output to box
  echo "Configuring Lidarr ... "
  cat >/etc/systemd/system/lidarr.service <<LIDARR
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

  mkdir -p /home/${username}/.config
  chown -R ${username}:${username} /home/${username}/.config
  chmod 775 /home/${username}/.config
  chown -R ${username}:${username} /opt/Lidarr/
  systemctl daemon-reload
  systemctl enable lidarr.service >/dev/null 2>&1
  systemctl start lidarr.service
  
  if [[ -f /install/.nginx.lock ]]; then
    sleep 10
    bash /usr/local/bin/swizzin/nginx/lidarr.sh
    service nginx reload
  fi
}

function _installLidarrFinish() {
  # output to box
  echo "Lidarr Install Complete!"
  echo "You can access it at  : http://$ip/lidarr"
  echo
  echo "Close this dialog box to refresh your browser"
}

function _installLidarrExit() {
  exit 0
}

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

ip=$(curl -s http://whatismyip.akamai.com)
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
username=$(cat /root/.master.info | cut -d: -f1)
lidarrver=$(wget -q https://github.com/lidarr/Lidarr/releases -O - | grep -E \/tag\/ | grep -v repository | awk -F "[><]" 'NR==1{print $3}')

_installLidarrIntro
echo "Installing dependencies ... " >>"${OUTTO}" 2>&1
_installLidarrDependencies
echo "Installing Lidarr ... " >>"${OUTTO}" 2>&1
_installLidarrCode
echo "Configuring Lidarr ... " >>"${OUTTO}" 2>&1
_installLidarrConfigure
echo "Starting Lidarr ... " >>"${OUTTO}" 2>&1
_installLidarrFinish
_installLidarrExit
