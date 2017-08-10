#!/bin/bash
#
# Swizzin :: Shellinabox installer
# Author: liara
#
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3
#################################################################################
apt-get -y install shellinabox

service shellinabox stop
rm -rf /etc/init.d/shellinabox

cat > /etc/systemd/system/shellinbox.service <<SIAB
[Unit]
Description=Shell in a Box service
Required=sshd.service
After=sshd.service

[Service]
User=root
Type=forking
EnvironmentFile=/etc/default/shellinabox
ExecStart=/usr/bin/shellinaboxd -q --background=/var/run/shellinaboxd.pid -c /var/lib/shellinabox -p 4200 -u shellinabox -g shellinabox $SHELLINABOX_ARGS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-abort

[Install]
WantedBy=multi-user.target
SIAB

if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/shellinabox.sh
fi

systemctl daemon-reload
systemctl enable shellinabox
systemctl start shellinabox

touch /install/.shellinabox.lock