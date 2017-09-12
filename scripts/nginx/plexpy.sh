#!/bin/bash
# Nginx Configuration for Plexpy
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cat /root/.master.info | cut -d: -f1)
isactive=$(systemctl is-active plexpy)
if [[ $isactive == "active" ]]; then
  systemctl stop plexpy
fi
if [[ ! -f /etc/nginx/apps/plexpy.conf ]]; then
  cat > /etc/nginx/apps/plexpy.conf <<RAD
location /plexpy {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:8181/plexpy;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
sed -i "s/http_root.*/http_root = \"plexpy\"/g" /opt/plexpy/config.ini
sed -i "s/http_host.*/http_host = 127.0.0.1/g" /opt/plexpy/config.ini
if [[ $isactive == "active" ]]; then
  systemctl start plexpy
fi