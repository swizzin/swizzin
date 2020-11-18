#! /bin/bash
# Netdata nginx proxy installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active netdata)

if [[ ! -f /etc/nginx/apps/netdata.conf ]]; then
	cat > /etc/nginx/apps/netdata.conf << NET
location /netdata {
  return 301 /netdata/;
}

location ~ /netdata/(?<ndpath>.*) {
  proxy_redirect off;
  proxy_set_header Host \$host;

  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-Server \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_http_version 1.1;
  proxy_pass_request_headers on;
  proxy_set_header Connection "keep-alive";
  proxy_store off;
  proxy_pass http://127.0.0.1:19999/\$ndpath\$is_args\$args;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};

  gzip on;
  gzip_proxied any;
  gzip_types *;
}
NET
fi
sed -i "s/# bind to = \*/bind to = 127.0.0.1/g" /etc/netdata/netdata.conf
if [[ $isactive == "active" ]]; then
	systemctl restart netdata
fi
