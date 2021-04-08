#!/usr/bin/env bash
#
username="$(cut -d: -f1 < /root/.master.info)"
#
if [[ -n "$1" && ! -f /install/.filebrowser.lock ]]; then
    port="$1"
    "/opt/filebrowser/filebrowser" config set -a "127.0.0.1" -b "/filebrowser" -d "/home/${username}/.config/Filebrowser/filebrowser.db" &>> "${log}"
fi
#
if [[ -z "$1" && -f /install/.filebrowser.lock ]]; then
    systemctl stop filebrowser &>> "${log}"
    port="$("/opt/filebrowser/filebrowser" config cat -d "/home/${username}/.config/Filebrowser/filebrowser.db" | grep 'Port:' | awk '{ print $2 }')"
    "/opt/filebrowser/filebrowser" config set -a "127.0.0.1" -b "/filebrowser" -d "/home/${username}/.config/Filebrowser/filebrowser.db" &>> "${log}"
    systemctl start filebrowser &>> "${log}"
fi
#
cat > /etc/nginx/apps/filebrowser.conf <<- NGINGCONF
    location /filebrowser {
        proxy_pass https://127.0.0.1:${port}/filebrowser;
        #
        proxy_pass_request_headers on;
        #
        proxy_set_header Host \$host;
        #
        proxy_http_version 1.1;
        #
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Protocol \$scheme;
        proxy_set_header X-Forwarded-Host \$http_host;
        #
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        #
        proxy_set_header X-Forwarded-Ssl on;
        #
        proxy_redirect off;
        proxy_buffering off;
        include /etc/nginx/apps/authelia/authelia_auth.conf;
    }
NGINGCONF
