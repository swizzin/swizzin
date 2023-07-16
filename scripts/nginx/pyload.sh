#!/bin/bash
# Nginx configuration for PyLoad
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
if [[ ! -f /etc/nginx/apps/pyload.conf ]]; then
    cat > /etc/nginx/apps/pyload.conf << PYLOAD
location /pyload/ {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass http://127.0.0.1:8000/;
  proxy_set_header Accept-Encoding "";
  sub_filter_types text/css text/xml text/javascript;
  sub_filter '/media/' '/pyload/media/';
  sub_filter '/json/' '/pyload/json/';
  sub_filter '/api/' '/pyload/api/';
  sub_filter '<a href="/' '<a href="/pyload/';
  sub_filter_once off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
PYLOAD
    sed -i 's/"Path prefix" = /"Path prefix" = \/pyload/g' /opt/pyload/pyload.conf
    sed -i 's/"IP" = 0.0.0.0/"IP" = 127.0.0.1/g' /opt/pyload/pyload.conf
fi
