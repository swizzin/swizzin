#!/bin/bash
#
# [Quick Box :: Install rclone]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   DedSec | d2dyno
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
MASTER=$(cut -d: -f1 < /root/.master.info)

echo "Downloading and installing rclone ..." >>"${OUTTO}" 2>&1;

# One-liner to check arch/os type, as well as download latest rclone for relevant system.
curl https://rclone.org/install.sh | sudo bash

# Make sure rclone downloads and installs without error before proceeding
if [ $? -eq 0 ]; then
    echo "Adding rclone mount service..." >>"${OUTTO}" 2>&1;

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
else
    echo "Issue occured during rclone installation." >>"${OUTTO}" 2>&1;
fi
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
