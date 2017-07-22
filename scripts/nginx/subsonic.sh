#!/bin/bash
# Nginx Configuration for Subsonic
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/subsonic.conf ]]; then
cat > /etc/nginx/apps/subsonic.conf <<SUB
location /subsonic/ {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass              http://localhost:4040/subsonic;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SUB
fi
sed -i 's/SUBSONIC_HOST=0.0.0.0/SUBSONIC_HOST=localhost/g' /usr/share/subsonic/subsonic.sh
sed -i 's/SUBSONIC_CONTEXT_PATH=\//SUBSONIC_CONTEXT_PATH=\/subsonic/g' /usr/share/subsonic/subsonic.sh
