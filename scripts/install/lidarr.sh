#!/bin/bash
# Lidarr installer for swizzin
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
#shellcheck source=sources/functions/mono
. /etc/swizzin/sources/functions/mono
mono_repo_setup
apt_install libmono-cil-dev libchromaprint-tools

echo_progress_start "Downloading Lidarr release and extracting"
cd /home/${user}/
wget -O lidarr.tar.gz -q $(curl -s https://api.github.com/repos/Lidarr/Lidarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4)
tar xf lidarr.tar.gz
rm -rf lidarr.tar.gz
chown -R ${user}: /home/${user}/Lidarr
echo_progress_done "Lidarr downloaded and extracted"

echo_progress_start "Configuring Lidarr"
if [[ ! -d /home/${user}/.config/Lidarr/ ]]; then mkdir -p /home/${user}/.config/Lidarr/; fi
cat > /home/${user}/.config/Lidarr/config.xml << LID
<Config>
  <Port>8686</Port>
  <UrlBase>lidarr</UrlBase>
  <BindAddress>*</BindAddress>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <LaunchBrowser>False</LaunchBrowser>
</Config>
LID
chown -R ${user}: /home/${user}/.config
cat > /etc/systemd/system/lidarr.service << LID
[Unit]
Description=lidarr for ${user}
After=syslog.target network.target

[Service]
Type=simple
User=${user}
Group=${user}
Environment="TMPDIR=/home/${user}/.tmp"
ExecStart=/usr/bin/mono /home/${user}/Lidarr/Lidarr.exe -nobrowser
ExecStop=-/bin/kill -HUP
WorkingDirectory=/home/${user}/
Restart=on-failure

[Install]
WantedBy=multi-user.target
LID
echo_progress_done "Lidarr configured"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    sleep 10
    bash /usr/local/bin/swizzin/nginx/lidarr.sh
    systemctl reload nginx
    echo_progress_done "Nginx configured"
else
    echo_info "Lidarr will run on port 8686"
fi

echo_progress_start "Enabling Lidarr"
systemctl enable -q --now lidarr 2>&1 | tee -a $log
echo_progress_done "Lidarr started"

echo_success "Lidarr installed"
touch /install/.lidarr.lock
