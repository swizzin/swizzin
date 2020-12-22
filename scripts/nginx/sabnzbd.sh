#!/bin/bash
# Nginx configuration for sabnzbd
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
active=$(systemctl is-active sabnzbd)

if [[ $active == "active" ]]; then
    systemctl stop sabnzbd
fi

if [[ ! -f /etc/nginx/apps/sabnzbd.conf ]]; then
    cat > /etc/nginx/apps/sabnzbd.conf << SAB
location /sabnzbd {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:65080/sabnzbd;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
SAB
fi

sed -i "s|^host = .*|host = 127.0.0.1|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "s|^url_base = .*|url_base = /sabnzbd|g" /home/${user}/.config/sabnzbd/sabnzbd.ini

if [[ $active == "active" ]]; then
    systemctl start sabnzbd
fi
