#!/bin/bash
# Nginx Configuration for Jellyfin
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
username="$(cut </root/.master.info -d: -f1)"
ip_address="$(curl -s4 icanhazip.com)"
app_port_https=$(grep -oP "<PublicHttpsPort>\K[^<]+" /home/"${username}"/.config/Jellyfin/config/system.xml)

if [[ -f /install/.jellyfin.lock ]]; then
	service jellyfin stop
fi

sed -r 's#<WanDdns>(.*)</WanDdns>#<WanDdns>https://'"${ip_address}"'/jellyfin</WanDdns>#g' -i "/home/${username}/.config/Jellyfin/config/system.xml"
sed -r 's#<string>0.0.0.0</string>#<string>127.0.0.1</string>#g' -i "/home/${username}/.config/Jellyfin/config/system.xml"

if [[ -f /install/.jellyfin.lock ]]; then
	service jellyfin start
fi

cat >/etc/nginx/apps/jellyfin.conf <<-NGINGCONF
location /jellyfin/ {
	proxy_pass https://127.0.0.1:${app_port_https}/;
	#
	proxy_pass_request_headers on;
	#
	proxy_set_header Host \$host;
	#
	proxy_http_version 1.1;
	#
	proxy_set_header X-Real-IP				\$remote_addr;
	proxy_set_header X-Forwarded-For		\$proxy_add_x_forwarded_for;
	proxy_set_header X-Forwarded-Proto		\$scheme;
	proxy_set_header X-Forwarded-Protocol	\$scheme;
	proxy_set_header X-Forwarded-Host		\$http_host;
	#
	proxy_set_header Upgrade				\$http_upgrade;
	proxy_set_header Connection				\$http_connection;
	#
	proxy_set_header X-Forwarded-Ssl		on;
	#
	proxy_redirect							off;
	proxy_buffering							off;
	auth_basic								off;
}
NGINGCONF
