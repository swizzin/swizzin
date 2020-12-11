#!/bin/bash
# Nginx configuration for Medusa
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active medusa)
if [[ $isactive == "active" ]]; then
    systemctl stop medusa
fi

if [[ ! -f /etc/nginx/apps/medusa.conf ]]; then
    cat > /etc/nginx/apps/medusa.conf << SRC
location /medusa {
  proxy_pass http://127.0.0.1:8081/medusa;
  proxy_set_header Host \$host;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Host \$host:443;
  proxy_set_header X-Forwarded-Server \$host;
  proxy_set_header X-Forwarded-Port 443;
  proxy_set_header X-Forwarded-Proto \$scheme;

  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};

  # Websocket
  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_read_timeout 86400;
}
SRC
fi
sed -i "s/web_root.*/web_root = \"medusa\"/g" /opt/medusa/config.ini
sed -i "s/web_host.*/web_host = 127.0.0.1/g" /opt/medusa/config.ini

if [[ $isactive == "active" ]]; then
    systemctl restart medusa
fi
