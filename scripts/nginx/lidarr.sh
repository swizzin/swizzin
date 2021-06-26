#!/bin/bash
# Lidarr configuration for nginx
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active lidarr)

if [[ $isactive == "active" ]]; then
    systemctl stop lidarr
fi

cat > /etc/nginx/apps/lidarr.conf << LIDN
location /lidarr {
  proxy_pass        http://127.0.0.1:8686/lidarr;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$http_connection;
    proxy_set_header Host \$proxy_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_redirect off;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
LIDN

if [[ ! -d /home/${user}/.config/Lidarr/ ]]; then mkdir -p /home/${user}/.config/Lidarr/; fi

cat > /home/${user}/.config/Lidarr/config.xml << LID
<Config>
  <Port>8686</Port>
  <UrlBase>lidarr</UrlBase>
  <BindAddress>127.0.0.1</BindAddress>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <LaunchBrowser>False</LaunchBrowser>
</Config>
LID

chown -R ${user}: /home/${user}/.config

if [[ $isactive == "active" ]]; then
    systemctl start lidarr
fi
