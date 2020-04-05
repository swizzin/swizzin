#!/usr/bin/env bash
#
# Set the required variables
username="$(cat /root/.master.info | cut -d: -f1)"
#
# A functions for reused commands.
function reused_commands () {
    sed -r 's#<string>0.0.0.0</string>#<string>127.0.0.1</string>#g' -i "/home/${username}/.config/Jellyfin/config/system.xml"
    sed -r 's#<BaseUrl />#<BaseUrl>/jellyfin</BaseUrl>#g' -i "/home/${username}/.config/Jellyfin/config/system.xml"
}
#
# Do this for jellyfin if is not already installed
if [[ ! -f /install/.jellyfin.lock ]]; then
    app_port_http="$1"
    app_port_https="$2"
    #
    reused_commands
fi
#
# Do this for jellyfin if is already installed
if [[ -f /install/.jellyfin.lock ]]; then
    service jellyfin stop
    app_port_https="$(sed -rn 's#(.*)<HttpsPortNumber>(.*)</HttpsPortNumber>#\2#p' "/home/${username}/.config/Jellyfin/config/system.xml")"
    #
    reused_commands
    #
    service jellyfin start
fi
#
# Create our nginx application conf for jellyfin
cat > /etc/nginx/apps/jellyfin.conf <<-NGINGCONF
location /jellyfin {
    proxy_pass https://127.0.0.1:${app_port_https};
    #
    proxy_pass_request_headers on;
    #
    proxy_set_header Host \$host;
    #
    proxy_http_version 1.1;
    #
    proxy_set_header X-Real-IP              \$remote_addr;
    proxy_set_header X-Forwarded-For        \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto      \$scheme;
    proxy_set_header X-Forwarded-Protocol   \$scheme;
    proxy_set_header X-Forwarded-Host       \$http_host;
    #
    proxy_set_header Upgrade                \$http_upgrade;
    proxy_set_header Connection             \$http_connection;
    #
    proxy_set_header X-Forwarded-Ssl        on;
    #
    proxy_redirect                          off;
    proxy_buffering                         off;
    auth_basic                              off;
}
NGINGCONF