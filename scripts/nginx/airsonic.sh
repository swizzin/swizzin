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

#shellcheck disable=SC2016,SC1003
sed -i '/-Dserver.port=${PORT}/c\          -Dserver.port=${PORT} -Dserver.address=127.0.0.1 -Dserver.context-path=/airsonic \\' /etc/systemd/system/airsonic.service
systemctl daemon-reload
systemctl try-restart airsonic
