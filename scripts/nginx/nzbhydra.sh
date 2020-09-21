#!/bin/bash
# Nginx configuration for nzbhydra
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
. /etc/swizzin/sources/functions/utils
user=$(_get_master_username)
active=$(systemctl is-active nzbhydra)
if [[ $active == "active" ]]; then
  systemctl stop nzbhydra
fi

if [[ ! -f /etc/nginx/apps/nzbhydra.conf ]]; then
  cat > /etc/nginx/apps/nzbhydra.conf <<RAD
location /nzbhydra {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:5076/nzbhydra;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
RAD
fi
sed -i "s/urlBase.*/urlBase: \"\/nzbhydra\"/g"  /home/${user}/.config/nzbhydra2/nzbhydra.yml
sed -i "s/host: \"0.0.0.0\"/host: \"127.0.0.1\"/g"  /home/${user}/.config/nzbhydra2/nzbhydra.yml
if [[ $active == "active" ]]; then
  systemctl start nzbhydra
fi
