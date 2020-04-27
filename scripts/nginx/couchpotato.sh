#!/bin/bash
# Nginx configuration for couchpotato
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active couchpotato)
if [[ $isactive == "active" ]]; then
  systemctl stop couchpotato
fi
if [[ ! -f /etc/nginx/apps/couchpotato.conf ]]; then
  cat > /etc/nginx/apps/couchpotato.conf <<RAD
location /couchpotato {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:5050/couchpotato;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
RAD
fi
sed -i "s/url_base.*/url_base = couchpotato\nhost = 127.0.0.1/g" /home/${user}/.config/couchpotato/settings.conf
if [[ $isactive == "active" ]]; then
  systemctl start couchpotato
fi