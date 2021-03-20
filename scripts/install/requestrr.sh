#!/bin/bash
# Requestrr installation
# Author: Brett
# Copyright (C) 2021 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#shellcheck source="sources/functions/os"
. /etc/swizzin/sources/functions/os

user=$(cut -d: -f1 < /root/.master.info)

echo_progress_start "Downloading source files"
case "$(_os_arch)" in
    "amd64") wget -qO "/tmp/requestrr.zip" "$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-x64(.*)zip')" >> ${log} 2>&1 ;;
    "armhf") wget -qO "/tmp/requestrr.zip" "$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-arm(.*)zip')" >> ${log} 2>&1 ;;
    "arm64") wget -qO "/tmp/requestrr.zip" "$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-arm64(.*)zip')" >> ${log} 2>&1 ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac

echo_progress_done "Source downloaded"

echo_progress_start "Extracting archive"
mkdir -p /opt/requestrr
unzip -j /tmp/requestrr.zip -d /opt/requestrr >> "$log" 2>&1
echo_progress_done "Archive extracted"

touch /install/.requestrr.lock

echo_progress_start "Installing Systemd service"
cat > /etc/systemd/system/requestrr.service << EOF
[Unit]
Description=Requestrr Daemon
After=syslog.target network.target

[Service]
User=requestrr
Type=simple
WorkingDirectory=/opt/requestrr/
ExecStart=/opt/requestrr/Requestrr.WebApi
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

chown -R requestrr:${user} /opt/requestrr
systemctl -q daemon-reload
systemctl enable --now -q requestrr
sleep 1
echo_progress_done "Requestrr service installed and enabled"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx configuration"
    #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
    sleep 10
    bash /usr/local/bin/swizzin/nginx/requestrr.sh
    systemctl -q reload nginx
    echo_progress_done "Nginx configured"
else
    echo_info "requestrr will be available on port 7878. Secure your installation manually through the web interface."
fi
