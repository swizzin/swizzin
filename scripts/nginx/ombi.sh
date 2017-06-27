#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/ombi.conf ]]; then
  cat > /etc/nginx/apps/ombi.conf <<RAD
location /ombi {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:3000/ombi;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
