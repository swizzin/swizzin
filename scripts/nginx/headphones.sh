#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/headphones.conf ]]; then
  cat > /etc/nginx/apps/headphones.conf <<RAD
location /headphones {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:8004/;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
