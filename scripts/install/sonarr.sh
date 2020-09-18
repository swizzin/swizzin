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

function _installSonarr1() {
  mono_repo_setup
}

function _installSonarr2() {
  apt_install apt-transport-https screen
  if [[ $distribution == "Ubuntu" ]]; then
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 >> ${log} 2>&1
  elif [[ $distribution == "Debian" ]]; then
    #buster friendly
    apt-key --keyring /etc/apt/trusted.gpg.d/nzbdrone.gpg adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 >> ${log} 2>&1
    #older style -- buster friendly should work on stretch
    #gpg --keyserver http://keyserver.ubuntu.com --recv 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 >/dev/null 2>&1
    #gpg --export 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /etc/apt/trusted.gpg.d/nzbdrone.gpg
  fi
  echo "deb https://apt.sonarr.tv/ master main" | tee /etc/apt/sources.list.d/sonarr.list >> ${log} 2>&1
  apt_update
}

function _installSonarr3() {
  if [[ $distribution == Debian ]]; then
    apt_install mono-devel
  fi
}

function _installSonarr4() {
  apt_install nzbdrone
  touch /install/.sonarr.lock
}

function _installSonarr5() {
  chown -R "${username}":"${username}" /opt/NzbDrone
}

function _installSonarr6() {
  echo_progress_start "Installing systemd service"
  cat > /etc/systemd/system/sonarr@.service <<SONARR
[Unit]
Description=nzbdrone
After=syslog.target network.target

[Service]
Type=forking
KillMode=process
User=%i
ExecStart=/usr/bin/screen -f -a -d -m -S nzbdrone mono /opt/NzbDrone/NzbDrone.exe
ExecStop=-/bin/kill -HUP
WorkingDirectory=/home/%i/

[Install]
WantedBy=multi-user.target
SONARR
  systemctl enable --now sonarr@${username} >> ${log} 2>&1
  sleep 10
  echo_progress_done "Sonarr started"


  if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    sleep 10
    bash /usr/local/bin/swizzin/nginx/sonarr.sh
    systemctl reload nginx
    echo_progress_done
  fi
}

#shellcheck source=sources/functions/mono
. /etc/swizzin/sources/functions/mono
username=$(cut -d: -f1 < /root/.master.info)
distribution=$(lsb_release -is)
version=$(lsb_release -cs)

_installSonarr1
echo_progress_start "Adding source repositories for Sonarr-Nzbdrone ... " >>"${log}" 2>&1;_installSonarr2; echo_progress_done
echo_progress_start "Updating your system with new sources ... " >>"${log}" 2>&1;_installSonarr3; echo_progress_done
echo_progress_start "Installing Sonarr-Nzbdrone ... " >>"${log}" 2>&1;_installSonarr4; echo_progress_done
echo_progress_start "Setting permissions to ${username} ... " >>"${log}" 2>&1;_installSonarr5; echo_progress_done
echo_progress_start "Setting up Sonarr as a service and enabling ... " >>"${log}" 2>&1;_installSonarr6; echo_progress_done

