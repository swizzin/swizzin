#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/subsonic.conf ]]; then
cat > /etc/nginx/apps/subsonic.conf <<SUB
location /subsonic/ {
  proxy_set_header        Host \$host;
  proxy_set_header        X-Real-IP \$remote_addr;
  proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header        X-Forwarded-Proto \$scheme;

  proxy_pass              http://localhost:4040/subsonic;

  proxy_read_timeout      600s;
  proxy_send_timeout      600s;

  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SUB
fi
