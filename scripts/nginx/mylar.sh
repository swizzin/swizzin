#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin

mylar_owner="$(swizdb get mylar/owner)"
port="$(sed -rn 's|http_port = (.*)|\1|p' "/home/${mylar_owner}/.config/mylar/config.ini")"

[[ -f /install/.mylar.lock ]] && systemctl stop -q mylar
sed -r 's|http_host = (.*)|http_host = 127.0.0.1|g' -i "/home/${mylar_owner}/.config/mylar/config.ini"
sed -r 's|http_root = (.*)|http_root = /mylar|g' -i "/home/${mylar_owner}/.config/mylar/config.ini"
[[ -f /install/.mylar.lock ]] && systemctl -q start mylar

cat > /etc/nginx/apps/mylar.conf << EON
location ^~ /mylar {
    include snippets/proxy.conf;
    proxy_pass http://127.0.0.1:${port};

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${mylar_owner};
}
EON
