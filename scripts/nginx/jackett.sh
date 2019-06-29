#!/bin/bash
# Nginx configuration for Jackett
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cat /root/.master.info | cut -d: -f1)
isactive=$(systemctl is-active jackett@$MASTER)
if [[ $isactive == "active" ]]; then
  systemctl stop jackett@$MASTER
fi
systemctl stop jackett@$MASTER
if [[ ! -f /etc/nginx/apps/jackett.conf ]]; then
  cat > /etc/nginx/apps/jackett.conf <<RAD
location /jackett {
  return 301 /jackett/;
}

location /jackett/ {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass http://127.0.0.1:9117/jackett/;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto https;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi

#sed -i "s/\"AllowExternal.*/\"AllowExternal\": false,/g" /home/${MASTER}/.config/Jackett/ServerConfig.json
sed -i "s/\"BasePathOverride.*/\"BasePathOverride\": \"\/jackett\",/g" /home/${MASTER}/.config/Jackett/ServerConfig.json

if [[ $isactive == "active" ]]; then
  systemctl start jackett@$MASTER
fi