#!/bin/bash
# Nginx Configuration for Radarr
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active radarr)

if [[ $isactive == "active" ]]; then
  systemctl stop radarr
fi
if [[ ! -f /etc/nginx/apps/radarr.conf ]]; then
  cat > /etc/nginx/apps/radarr.conf <<RAD
location /radarr {
  proxy_pass        http://127.0.0.1:7878/radarr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
if [[ ! -d /home/${MASTER}/.config/Radarr/ ]]; then mkdir -p /home/${MASTER}/.config/Radarr/; fi
cat > /home/${MASTER}/.config/Radarr/config.xml <<RAD
<Config>
  <Port>7878</Port>
  <UrlBase>radarr</UrlBase>
  <BindAddress>127.0.0.1</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <LaunchBrowser>False</LaunchBrowser>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <AnalyticsEnabled>False</AnalyticsEnabled>
</Config>
RAD
chown -R ${MASTER}: /home/${MASTER}/.config/Radarr
if [[ $isactive == "active" ]]; then
  systemctl start radarr
fi