#!/bin/bash
#
# [Quick Box :: Install Sonarr-NzbDrone package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################
function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }
#################################################################################

function _installSonarrintro() {
  echo "Sonarr will now be installed." >>"${OUTTO}" 2>&1;
  echo "This process may take up to 2 minutes." >>"${OUTTO}" 2>&1;
  echo "Please wait until install is completed." >>"${OUTTO}" 2>&1;
  # output to box
  echo "Sonarr will now be installed."
  echo "This process may take up to 2 minutes."
  echo "Please wait until install is completed."
  echo
  sleep 5
}

function _installSonarr1() {
  if [[ ! -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
    echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
    echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
    echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  fi
}

function _installSonarr2() {
  sudo apt-get install apt-transport-https -y >/dev/null 2>&1
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC >/dev/null 2>&1
  echo "deb https://apt.sonarr.tv/ master main" | sudo tee -a /etc/apt/sources.list.d/sonarr.list >/dev/null 2>&1
}

function _installSonarr3() {
  sudo apt-get -y update >/dev/null 2>&1
  if [[ $distribution == Debian ]]; then
    sudo apt-get install -y mono-devel >/dev/null 2>&1
  fi
}

function _installSonarr4() {
  sudo apt-get install -y nzbdrone >/dev/null 2>&1
  touch /install/.sonarr.lock
}

function _installSonarr5() {
  sudo chown -R "${username}":"${username}" /opt/NzbDrone
}

function _installSonarr6() {
  cp ${local_setup}templates/sysd/sonarr.template /etc/systemd/system/sonarr@.service
  systemctl enable sonarr@${username} >/dev/null 2>&1
  systemctl start sonarr@${username}
  sleep 10

  rm -rf /home/${username}/.config/NzbDrone/config.xml
  cp ${local_setup}configs/Sonarr/config.xml /home/${username}/.config/NzbDrone/config.xml
  chown ${username}:${username} /home/${username}/.config/NzbDrone/config.xml

  systemctl stop sonarr@{$username}.service
  sleep 10

  if [[ -f /home/${username}/.config/NzbDrone/config.xml ]]; then
    #sed -i "s/<UrlBase>.*/<UrlBase>sonarr<\/UrlBase>/g" /home/${username}/.config/NzbDrone/config.xml
    #sed -i "s/<BindAddress>.*/<BindAddress>127.0.0.1<\/BindAddress>/g" /home/${username}/.config/NzbDrone/config.xml
    service apache2 reload
  else
    # output to dashboard
    echo "ERROR INSTALLING - COULD NOT FIND config.xml in /home/${username}/.config/NzbDrone/config.xml" >> "${OUTTO}" 2>&1
    # output to box
    echo "ERROR INSTALLING - COULD NOT FIND config.xml in /home/${username}/.config/NzbDrone/config.xml"
    exit 1
  fi

  systemctl stop sonarr@${username}

  cat > /etc/apache2/sites-enabled/sonarr.conf <<EOF
<Location /sonarr>
ProxyPass http://localhost:8989/sonarr
ProxyPassReverse http://localhost:8989/sonarr
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${username}
</Location>
EOF
  chown www-data: /etc/apache2/sites-enabled/sonarr.conf
  service apache2 reload
  systemctl start sonarr@${username}
}


function _installSonarr9() {
  echo "Sonarr Install Complete!" >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}

function _installSonarr10() {
  exit
}


OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/
local_packages=/etc/QuickBox/packages/
username=$(cat /srv/rutorrent/home/db/master.txt)
distribution=$(lsb_release -is)

_installSonarrintro
echo "Installing latest mono source repository ... " >>"${OUTTO}" 2>&1;_installSonarr1
echo "Adding source repositories for Sonarr-Nzbdrone ... " >>"${OUTTO}" 2>&1;_installSonarr2
echo "Updating your system with new sources ... " >>"${OUTTO}" 2>&1;_installSonarr3
echo "Installing Sonarr-Nzbdrone ... " >>"${OUTTO}" 2>&1;_installSonarr4
echo "Setting permissions to ${username} ... " >>"${OUTTO}" 2>&1;_installSonarr5
echo "Setting up Sonarr as a service and enabling ... " >>"${OUTTO}" 2>&1;_installSonarr6
_installSonarr9
_installSonarr10
