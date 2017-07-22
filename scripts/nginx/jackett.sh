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
if [[ ! -f /etc/nginx/apps/jackett.conf ]]; then
  cat > /etc/nginx/apps/jackett.conf <<RAD
location /jackett {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:9117/jackett;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
sed -i "s/\"AllowExternal.*/\"AllowExternal\": false,/g" /home/${MASTER}/.config/Jackett/ServerConfig.json
sed -i "s/\"BasePathOverride.*/\"BasePathOverride\": \"\/jackett\",/g" /home/${MASTER}/.config/Jackett/ServerConfig.json
# Disable native auto-update, since we have a command for that.
sed -i "s/\"UpdateDisabled.*/\"UpdateDisabled\": true,/g" /home/${MASTER}/.config/Jackett/ServerConfig.json