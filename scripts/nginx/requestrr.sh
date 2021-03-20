#!/bin/bash
# Nginx Configuration for requestrr
master=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /etc/nginx/apps/requestrr.conf ]]; then
    cat > /etc/nginx/apps/requestrr.conf << SRC
location /requestrr {
  proxy_pass        http://127.0.0.1:4545/requestrr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  # Basic Auth if Wanted
  # auth_basic "What's the password?";
  # auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
  # This shouldn't be needed.
}
SRC
fi
