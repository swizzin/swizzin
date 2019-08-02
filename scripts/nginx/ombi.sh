#!/bin/bash
# Nginx configuration for Ombi
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)

if [[ -f /etc/nginx/apps/ombi.conf ]]; then
  if grep -q '$scheme://$host' /etc/nginx/apps/ombi.conf; then
    :
  else
  cat > /etc/nginx/apps/ombi.conf <<'RAD'
location /ombi {		
     return 301 $scheme://$host/ombi/;		
}
location ^~ /ombi/ {
    proxy_pass http://127.0.0.1:3000/ombi/;
    proxy_pass_header Server;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $server_name;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Scheme $scheme;
    proxy_read_timeout  120;
    proxy_connect_timeout 10;
    proxy_http_version 1.1;
    proxy_redirect off;
}

if ($http_referer ~* /ombi/) {
    rewrite ^/dist/(.*) $scheme://$host/ombi/dist/$1 permanent;
    rewrite ^/images/(.*) $scheme://$host/ombi/images/$1 permanent;
}
RAD
  fi
fi

if [[ ! -f /etc/nginx/apps/ombi.conf ]]; then
  cat > /etc/nginx/apps/ombi.conf <<'RAD'
location /ombi {		
     return 301 $scheme://$host/ombi/;		
}
location ^~ /ombi/ {
    proxy_pass http://127.0.0.1:3000/ombi/;
    proxy_pass_header Server;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $server_name;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Scheme $scheme;
    proxy_read_timeout  120;
    proxy_connect_timeout 10;
    proxy_http_version 1.1;
    proxy_redirect off;
}

if ($http_referer ~* /ombi/) {
    rewrite ^/dist/(.*) $scheme://$host/ombi/dist/$1 permanent;
    rewrite ^/images/(.*) $scheme://$host/ombi/images/$1 permanent;
}
RAD
fi

if grep -q 0.0.0.0 /etc/systemd/system/ombi.service; then
  cat > /etc/systemd/system/ombi.service <<OMB
[Unit]
Description=Ombi - PMS Requests System
After=network-online.target

[Service]
User=ombi
Group=nogroup
WorkingDirectory=/opt/Ombi/
ExecStart=/opt/Ombi/Ombi --baseurl /ombi --host http://127.0.0.1:3000 --storage /etc/Ombi
Type=simple
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
OMB
  systemctl daemon-reload
fi
