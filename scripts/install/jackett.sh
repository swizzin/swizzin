#!/bin/bash
#
# [Quick Box :: Install Jackett package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | d2dyno
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
username=$(cat /root/.master.info | cut -d: -f1)
jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | grep -v repository | awk -F "[><]" '{print $3}')
echo >>"${OUTTO}" 2>&1;
echo "Installing Jackett ... " >>"${OUTTO}" 2>&1;

if [[ ! -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
  echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
fi

apt update -y >/dev/null 2>&1
apt install -y mono-devel >/dev/null 2>&1

cd /home/$username
wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.Mono.tar.gz
tar -xvzf Jackett.Binaries.Mono.tar.gz > /dev/null 2>&1
rm -f Jackett.Binaries.Mono.tar.gz
chown ${username}.${username} -R Jackett
touch /install/.jackett.lock

cat > /etc/systemd/system/jackett@.service <<JAK
[Unit]
Description=jackett
After=network.target

[Service]
Type=simple
User=%I
WorkingDirectory=/home/%I/
ExecStart=/usr/bin/mono /home/%I/Jackett/JackettConsole.exe --NoRestart
Restart=always
RestartSec=2
[Install]
WantedBy=multi-user.target
JAK

systemctl enable jackett@${username} >/dev/null 2>&1
systemctl start jackett@${username}
while [ ! -f /home/${username}/.config/Jackett/ServerConfig.json ]
do
  sleep 2
done
systemctl stop jackett@${username}
sleep 5

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/jackett.sh
  service nginx reload
fi
service jackett@${username} start


echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Jackett Install Complete!" >>"${OUTTO}" 2>&1;

echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
