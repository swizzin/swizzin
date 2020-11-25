#!/bin/bash
# Nginx Configuration for Sonarr
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active sonarr@"$MASTER")

if [[ $isactive == "active" ]]; then
	systemctl stop sonarr@"$MASTER"
fi

if [[ ! -f /etc/nginx/apps/sonarr.conf ]]; then
	cat > /etc/nginx/apps/sonarr.conf << SONARR
location /sonarr {
  proxy_pass        http://127.0.0.1:8989/sonarr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SONARR
fi
if [[ ! -d /home/${MASTER}/.config/NzbDrone/ ]]; then mkdir -p /home/"${MASTER}"/.config/NzbDrone/; fi
cat > /home/"${MASTER}"/.config/NzbDrone/config.xml << SONN
<Config>
  <Port>8989</Port>
  <UrlBase>sonarr</UrlBase>
  <BindAddress>127.0.0.1</BindAddress>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <Branch>master</Branch>
  <LaunchBrowser>False</LaunchBrowser>
</Config>
SONN
chown -R "${MASTER}": /home/"${MASTER}"/.config/NzbDrone/
if [[ $isactive == "active" ]]; then
	systemctl start sonarr@"$MASTER"
fi
