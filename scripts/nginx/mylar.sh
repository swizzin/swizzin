#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
MYLAR_OWNER="$(swizdb get mylar/owner)"
port="$(sed -rn 's|http_port = (.*)|\1|p' "/home/${MYLAR_OWNER}/.config/mylar/config.ini")"
sed -i 's|http_host = 0.0.0.0|http_host = 127.0.0.1|g' "/home/${MYLAR_OWNER}/.config/mylar/config.ini"
sed -i 's|http_root = /|http_root = /mylar|g' "/home/${MYLAR_OWNER}/.config/mylar/config.ini"

cat > /etc/nginx/apps/mylar.conf << EON
location ^~ /mylar {
    include snippets/proxy.conf;
    proxy_pass http://127.0.0.1:${port};
    
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MYLAR_OWNER};
}
EON
