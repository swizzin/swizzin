#!/bin/bash
# Nginx configuration for Jackett
# Author: liara userdocs
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/app_port
. /etc/swizzin/sources/functions/app_port
# Get our main user credentials to use when bootstrapping filebrowser.
username="$(_get_master_username)"
# Get our app port using the install script name as the app name
app_proxy_port="$(_get_app_port "$(basename -- "$0" \.sh)")"

if [[ "$(systemctl is-active jackett)" == "active" ]]; then
    systemctl stop jackett &>> "${log}"
fi

if [[ ! -f /etc/nginx/apps/jackett.conf ]]; then
    cat > /etc/nginx/apps/jackett.conf <<- JACKETT_NGINX
    location /jackett {
        return 301 /jackett/;
    }

    location /jackett/ {
        include /etc/nginx/snippets/proxy.conf;
        proxy_pass http://127.0.0.1:${app_proxy_port}/jackett/;
        include /etc/nginx/apps/authelia/authelia_auth.conf;
    }
JACKETT_NGINX
fi

sed "s/\"BasePathOverride.*/\"BasePathOverride\": \"\/jackett\",/g" -i "/home/${username}/.config/Jackett/ServerConfig.json"

if [[ "$(systemctl is-active jackett)" =~ (inactive|failed) ]]; then
    systemctl start jackett &>> "${log}"
fi
