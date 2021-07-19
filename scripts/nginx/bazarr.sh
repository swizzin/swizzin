#!/bin/bash
# Bazarr configuration for nginx
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active bazarr)

if [[ $isactive == "active" ]]; then
    systemctl stop bazarr
fi

cat > /etc/nginx/apps/bazarr.conf << BAZN
location /bazarr/ {
    proxy_pass              http://127.0.0.1:6767/bazarr/;
    proxy_set_header        X-Real-IP               \$remote_addr;
    proxy_set_header        Host                    \$http_host;
    proxy_set_header        X-Forwarded-For         \$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto       \$scheme;
    proxy_http_version      1.1;
    proxy_set_header        Upgrade                 \$http_upgrade;
    proxy_set_header        Connection              "Upgrade";
    proxy_redirect off;

    auth_basic              "What's the password?";
    auth_basic_user_file    /etc/htpasswd.d/htpasswd.${user};
    
    # Allow the Bazarr API through if you enable Auth on the block above
    location /bazarr/api {
        auth_request off;
        proxy_pass http://127.0.0.1:6767/bazarr/api;
    }
}

BAZN

if ! grep -q "\[general\]" /opt/bazarr/data/config/config.ini > /dev/null 2>&1; then
    cat >> /opt/bazarr/data/config/config.ini << BAZC

[general]
ip = 127.0.0.1
base_url = /bazarr/
BAZC
fi

if [[ $isactive == "active" ]]; then
    systemctl start bazarr
fi
