#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
user=$(_get_master_username)
port=$(awk -F "=" '/http_port/ {print $2}' /home/${user}/.config/mylar/config.ini | tr -d ' ')
sed -i 's|http_host = 0.0.0.0|http_host = 127.0.0.1|g' /home/${user}/.config/mylar/config.ini

cat > /etc/nginx/apps/panel.conf << EON
location / {
  proxy_set_header Host \$host;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header Origin "";
  proxy_pass http://127.0.0.1:${port};
  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "Upgrade";
}
EON
