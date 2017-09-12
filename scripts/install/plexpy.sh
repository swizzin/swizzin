#!/bin/bash
#
# Plexpy installer
#
# Author             :   QuickBox.IO | liara
# Ported to swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
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
MASTER=$(cat /root/.master.info | cut -d: -f1)


cd /opt
echo "Cloning PlexPy repository" >>"${OUTTO}" 2>&1;
git clone https://github.com/drzoidberg33/plexpy.git > /dev/null 2>&1

echo "Adding user and setting up PlexPy" >>"${OUTTO}" 2>&1;
adduser --system --no-create-home plexpy >>"${OUTTO}" 2>&1

echo "Adjusting permissions" >>"${OUTTO}" 2>&1;
chown plexpy:nogroup -R /opt/plexpy




echo "Enabling PlexPy Systemd configuration"
cat > /etc/systemd/system/plexpy.service <<PPY
[Unit]
Description=PlexPy - Stats for Plex Media Server usage

[Service]
ExecStart=/opt/plexpy/PlexPy.py --quiet --daemon --nolaunch --config /opt/plexpy/config.ini --datadir /opt/plexpy
GuessMainPID=no
Type=forking
User=plexpy
Group=nogroup

[Install]
WantedBy=multi-user.target
PPY

systemctl enable plexpy > /dev/null 2>&1
systemctl start plexpy

if [[ -f /install/.nginx.lock ]]; then
  while [ ! -f /opt/plexpy/config.ini ]
  do
    sleep 2
  done
  bash /usr/local/bin/swizzin/nginx/plexpy.sh
  service nginx reload
fi
touch /install/.plexpy.lock

echo "PlexPy Install Complete!" >>"${OUTTO}" 2>&1;
sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
