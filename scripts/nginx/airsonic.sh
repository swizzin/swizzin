#!/bin/bash
# Nginx Configuration for Airsonic
# Author: flying-sausages
# Copyright (C) 2020 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)

cat > /etc/nginx/apps/airsonic.conf << NGINXCONF
location /airsonic {
	proxy_set_header X-Real-IP         \$remote_addr;
	proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
	proxy_set_header X-Forwarded-Proto https;
	proxy_set_header X-Forwarded-Host  \$http_host;
	proxy_set_header Host              \$http_host;
	proxy_max_temp_file_size           0;
	proxy_pass                         http://127.0.0.1:8185;
	proxy_redirect                     http:// https://;
}
NGINXCONF

sed -i 's|-Dserver.port=8085|-Dserver.port=8085 -Dserver.address=127.0.0.1 -Dserver.context-path=/airsonic|g' /etc/systemd/system/airsonic.service
systemctl try-restart airsonic
