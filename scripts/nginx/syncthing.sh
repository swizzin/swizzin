#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/syncthing.conf ]]; then
cat > /etc/nginx/apps/syncthing.conf <<SYNC
location /syncthing/ {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass              http://localhost:8384/;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SYNC
fi
