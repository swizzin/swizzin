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

cat > /etc/nginx/apps/ombi.conf << 'RAD'
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

status=$(systemctl is-active ombi)
if [[ $status = "active" ]]; then
    systemctl stop -q ombi
fi

mkdir -p /etc/systemd/system/ombi.service.d
cat > /etc/systemd/system/ombi.service.d/override.conf << CONF
[Service]
ExecStart=
ExecStart=/opt/Ombi/Ombi --baseurl /ombi --host http://127.0.0.1:3000 --storage /etc/Ombi
CONF
systemctl daemon-reload

if [[ $status = "active" ]]; then
    systemctl start -q ombi
fi
