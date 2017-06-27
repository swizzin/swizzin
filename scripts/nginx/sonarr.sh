#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/sonarr.conf ]]; then
cat > /etc/nginx/apps/sonarr.conf <<SONARR
location /sonarr {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:8989/sonarr;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SONARR
fi
