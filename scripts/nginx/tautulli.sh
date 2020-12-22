#!/bin/bash
# Nginx Configuration for Tautulli
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active tautulli)
if [[ $isactive == "active" ]]; then
    systemctl stop tautulli
fi
if [[ ! -f /etc/nginx/apps/tautulli.conf ]]; then
    cat > /etc/nginx/apps/tautulli.conf << RAD
location /plexpy {
  return 301 /tautulli/;
}


location /tautulli {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:8181/tautulli;
}
RAD
fi
sed -i "s/http_root.*/http_root = \"tautulli\"/g" /opt/tautulli/config.ini
sed -i "s/http_host.*/http_host = 127.0.0.1/g" /opt/tautulli/config.ini
if [[ $isactive == "active" ]]; then
    systemctl start tautulli
fi
