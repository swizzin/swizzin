#!/usr/bin/env bash
#
app_name="$1"
port="$2"
#
username="$(cat /root/.master.info | cut -d: -f1)"
#
cat > /etc/nginx/apps/${app_name}.conf <<-NGINGCONF
location /${app_name} {
    # access_log /home/${username}/${app_name}.access.log;
    # error_log /home/${username}/${app_name}.error.log;
    #
    proxy_pass http://127.0.0.1:${port};
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
#
#