#!/bin/bash
# navidrome nginx conf
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user="$(_get_master_username)"
http_port="4533" # default port used by navidrome

cat > /etc/nginx/apps/navidrome.conf <<- NGX
location /navidrome {
    proxy_pass        http://127.0.0.1:${http_port}/navidrome;
    proxy_set_header Host \$proxy_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_redirect off;
    auth_basic off;
}
NGX
