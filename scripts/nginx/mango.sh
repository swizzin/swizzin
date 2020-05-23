#!/bin/bash
# Nginx configuration for Mango


cat > /etc/nginx/apps/mango.conf <<EOF
location /mango/ {
  # TODO This needs a doing
  # rewrite ^/mango(.*) /\$1 break;
  proxy_pass http://localhost:9003;
}
EOF

systemctl reload nginx