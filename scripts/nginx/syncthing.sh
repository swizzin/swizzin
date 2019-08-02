#!/bin/bash
# Nginx Configuration for Syncthing
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)
if [[ ! -f /etc/nginx/apps/syncthing.conf ]]; then
cat > /etc/nginx/apps/syncthing.conf <<SYNC
location /syncthing/ {
  proxy_pass              http://127.0.0.1:8384/;
  proxy_set_header        Host \$proxy_host;
  proxy_set_header        X-Real-IP \$remote_addr;
  proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header        X-Forwarded-Proto \$scheme;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SYNC
fi
