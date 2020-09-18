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
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

echo "Downloading and installing rclone and dependencies ..."

# Install fuse
apt_install install fuse
sed -i -e 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# One-liner to check arch/os type, as well as download latest rclone for relevant system.
curl https://rclone.org/install.sh | sudo bash

# Make sure rclone downloads and installs without error before proceeding
if [ $? -eq 0 ]; then
    echo "Adding rclone mount service..."

cat >/etc/systemd/system/rclone@.service<<EOF
[Unit]
Description=rclonemount
After=network.target

[Service]
Type=simple
User=%i
Group=%i
ExecStartPre=-/bin/mkdir -p /home/%i/cloud/
ExecStart=/usr/bin/rclone mount gdrive: /home/%i/cloud/ \
  --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36' \
  --config /home/%i/.config/rclone/rclone.conf \
  --use-mmap \
  --dir-cache-time 1h \
  --timeout 30s \
  --umask 002 \
  --poll-interval=1h \
  --vfs-cache-mode writes \
  --vfs-read-chunk-size 1M \
  --vfs-read-chunk-size-limit 64M \
  --tpslimit 10
ExecStop=/bin/fusermount -u /home/%i/cloud
Restart=on-failure
RestartSec=30
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target

EOF

    touch /install/.rclone.lock
    echo "rclone installation complete!"
    echo "Setup Rclone remote named: gdrive"
    echo "And run sudo systemctl start rclone@username.service"
else
    echo "Issue occured during rclone installation."
fi
