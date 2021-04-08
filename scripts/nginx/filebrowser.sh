#!/usr/bin/env bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/app_port
. /etc/swizzin/sources/functions/app_port
#
username=$(_get_master_username)
app_proxy_port="$(_get_app_port "$(basename -- "$0" \.sh)")"
#
if [[ -z "$1" && -f /install/.filebrowser.lock ]]; then
    if [[ "$(systemctl is-active filebrowser)" == "active" ]]; then
        systemctl stop -q filebrowser &>> "${log}"
    fi
    #
    "/opt/filebrowser/filebrowser" config set -a "127.0.0.1" -b "/filebrowser" -d "/home/${username}/.config/Filebrowser/filebrowser.db"
    #
    if [[ "${1}" != "upgrade" ]]; then
        systemctl start -q filebrowser &>> "${log}"
    fi
fi
#
cat > /etc/nginx/apps/filebrowser.conf <<- NGINGCONF
	location /filebrowser {
	    proxy_pass http://127.0.0.1:${app_proxy_port}/filebrowser;
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
        auth_basic off;
	}
NGINGCONF
