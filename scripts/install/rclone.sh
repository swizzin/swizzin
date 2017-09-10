#!/bin/bash
#
# [Quick Box :: Install rclone]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   DedSec
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
MASTER=$(cat /root/.master.info | cut -d: -f1)
arch=$(arch)

echo "Downloading rclone ... " >>"${OUTTO}" 2>&1;

if [[ $arch == x86_64 ]]; then
  current=https://downloads.rclone.org/rclone-current-linux-amd64.zip
  cd /tmp
  wget -O rclone.zip $current
  unzip -d rclone -j rclone.zip
  cd rclone
  cp rclone /usr/sbin/
  chown root:root /usr/sbin/rclone
  chmod 755 /usr/sbin/rclone
  ln -s /usr/sbin/rclone /usr/bin/rclone
  sudo mkdir -p /usr/local/share/man/man1
  sudo cp rclone.1 /usr/local/share/man/man1/
  sudo mandb
  cd /tmp
  rm -rf rclone*
fi
if [[ $arch == i386 ]]; then
  #current=$(curl -s -N http://rclone.org/downloads/ | grep -m1 linux-386 | cut -d\" -f2)
  current=https://downloads.rclone.org/rclone-current-linux-386.zip
  cd /tmp
  wget $current
  unzip -d rclone -j rclone.zip
  cd rclone
  cp rclone /usr/sbin/
  chown root:root /usr/sbin/rclone
  chmod 755 /usr/sbin/rclone
  ln -s /usr/sbin/rclone /usr/bin/rclone
  sudo mkdir -p /usr/local/share/man/man1
  sudo cp rclone.1 /usr/local/share/man/man1/
  sudo mandb
  cd /tmp
  rm -rf rclone*
fi

echo "Installing rclone ... " >>"${OUTTO}" 2>&1;

cat >/etc/systemd/system/rclone@.service<<EOF
[Unit]
Description=rclonemount
After=network.target

[Service]
Type=simple
User=%I
Group=%I
ExecStart=/usr/sbin/rclone mount /home/%I/cloud --allow-non-empty --allow-other --dir-cache-time 10m --max-read-ahead 9G --checkers 32 --contimeout 15s --quiet
ExecStop=/bin/fusermount -u /home/%I/cloud
Restart=on-failure
RestartSec=30
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target

EOF

touch /install/.rclone.lock
echo "rclone installation complete!" >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
