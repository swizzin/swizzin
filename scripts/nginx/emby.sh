#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/emby.conf ]]; then
cat > /etc/nginx/apps/emby.conf <<EMB
location /pyload {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:8096/emby-server;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "upgrade";
}
fi
EMB
