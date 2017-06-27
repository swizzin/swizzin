#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/sabnzbd.conf ]]; then
  cat > /etc/nginx/apps/sabnzbd.conf <<SAB
location /sabnzbd {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass        http://127.0.0.1:65080/sabnzbd;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SAB
fi
