#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/couchpotato.conf ]]; then
  cat > /etc/nginx/apps/couchpotato.conf <<RAD
location /couchpotato {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:5050/couchpotato;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
