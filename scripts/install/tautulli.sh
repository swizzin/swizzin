#!/bin/bash
#
# Tautulli installer
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
MASTER=$(cut -d: -f1 < /root/.master.info)


apt-get -y -q install python python-setuptools tzdata >>"${OUTTO}" 2>&1
cd /opt
LATEST=$(curl -s https://api.github.com/repos/tautulli/tautulli/releases/latest | grep "\"name\":" | cut -d : -f 2 | tr -d \", | cut -d " " -f 3)
echo "Downloading latest Tautulli version ${LATEST}" >>"${OUTTO}" 2>&1;
mkdir -p /opt/tautulli
curl -s https://api.github.com/repos/tautulli/tautulli/releases/latest | grep "tarball" | cut -d : -f 2,3 | tr -d \", | wget -q -i- -O- | tar xz -C /opt/tautulli --strip-components 1

echo "Adding user and setting up Tautulli" >>"${OUTTO}" 2>&1;
adduser --system --no-create-home tautulli >>"${OUTTO}" 2>&1

echo "Adjusting permissions" >>"${OUTTO}" 2>&1;
chown tautulli:nogroup -R /opt/tautulli




echo "Enabling Tautulli Systemd configuration"
cat > /etc/systemd/system/tautulli.service <<PPY
[Unit]
Description=Tautulli - Stats for Plex Media Server usage
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/tautulli/Tautulli.py --quiet --daemon --nolaunch --config /opt/tautulli/config.ini --datadir /opt/tautulli
GuessMainPID=no
Type=forking
User=tautulli
Group=nogroup

[Install]
WantedBy=multi-user.target
PPY

systemctl enable tautulli > /dev/null 2>&1
systemctl start tautulli

if [[ -f /install/.nginx.lock ]]; then
  while [ ! -f /opt/tautulli/config.ini ]
  do
    sleep 2
  done
  bash /usr/local/bin/swizzin/nginx/tautulli.sh
  service nginx reload
fi
touch /install/.tautulli.lock

echo "Tautulli Install Complete!" >>"${OUTTO}" 2>&1;
sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
