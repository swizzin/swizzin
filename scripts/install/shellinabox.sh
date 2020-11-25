#!/bin/bash
#
# Swizzin :: Shellinabox installer
# Author: liara
#
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3
#################################################################################

apt_install shellinabox

echo_progress_start "Configuring shellinabox"
systemctl stop shellinabox >> $log 2>&1
rm -rf /etc/init.d/shellinabox

cat > /etc/systemd/system/shellinabox.service << SIAB
[Unit]
Description=Shell in a Box service
After=sshd.service

[Service]
User=root
Type=forking
EnvironmentFile=/etc/default/shellinabox
ExecStart=/usr/bin/shellinaboxd -q --background=/var/run/shellinaboxd.pid -c /var/lib/shellinabox -p 4200 -u shellinabox -g shellinabox \$SHELLINABOX_ARGS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-abort

[Install]
WantedBy=multi-user.target
SIAB

systemctl daemon-reload -q
systemctl enable -q shellinabox 2>&1 | tee -a $log
systemctl start shellinabox >> $log 2>&1
echo_progress_done "Configured and restarted"

if [[ -f /install/.nginx.lock ]]; then
	echo_progress_start "Configuring nginx"
	bash /usr/local/bin/swizzin/nginx/shellinabox.sh
	echo_progress_done
fi

echo_success "Shellinabox installed"
touch /install/.shellinabox.lock
