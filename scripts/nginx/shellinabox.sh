#!/bin/bash
# Nginx configuration for Shell in a Box
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active shellinabox)
if [[ ! -f /etc/nginx/apps/shell.conf ]]; then
  cat > /etc/nginx/apps/shell.conf <<RAD
location /shell/ {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:4200;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
if [[ -z $(grep disable-ssl /etc/default/shellinabox) ]]; then
    sed -i 's/SHELLINABOX_ARGS="/SHELLINABOX_ARGS="--disable-ssl /g' /etc/default/shellinabox
fi
if [[ -z $(grep localhost-only /etc/default/shellinabox) ]]; then
    sed -i 's/SHELLINABOX_ARGS="/SHELLINABOX_ARGS="--localhost-only /g' /etc/default/shellinabox
fi
systemctl reload nginx

if [[ $isactive == "active" ]]; then
  systemctl restart shellinabox
fi
