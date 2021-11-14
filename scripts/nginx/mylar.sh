#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
MYLAR_OWNER=$(swizdb get mylar/owner)
port=$(awk -F "=" '/http_port/ {print $2}' /home/${MYLAR_OWNER}/.config/mylar/config.ini | tr -d ' ')
sed -i 's|http_host = 0.0.0.0|http_host = 127.0.0.1|g' /home/${MYLAR_OWNER}/.config/mylar/config.ini
cat > /etc/nginx/apps/mylar.conf << EON
location ^~ /mylar {
    include snippets/proxy.conf;
    proxy_pass http://127.0.0.1:${port};
    
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MYLAR_OWNER};
}
EON