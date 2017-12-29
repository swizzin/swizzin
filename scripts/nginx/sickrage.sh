#!/bin/bash
# Nginx configuration for SickRage
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cat /root/.master.info | cut -d: -f1)
isactive=$(systemctl is-active sickrage@$user)
if [[ $isactive == "active" ]]; then
  systemctl stop sickrage@${user}
fi

if [[ ! -f /etc/nginx/apps/sickrage.conf ]]; then
  cat > /etc/nginx/apps/sickrage.conf <<SRC
location /sickrage {
    include /etc/nginx/snippets/proxy.conf;
    proxy_pass        http://127.0.0.1:8081/sickrage;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
SRC
fi
sed -i "s/web_root.*/web_root = \/sickrage/g" /home/${user}/.sickrage/config.ini
sed -i "s/web_host.*/web_host = 127.0.0.1/g" /home/${user}/.sickrage/config.ini
if [[ $isactive == "active" ]]; then
  systemctl start sickrage@${user}
fi