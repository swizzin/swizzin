#!/bin/bash
# Nginx configuration for Mango

cat > /etc/nginx/apps/mango.conf << EOF
location /mango/ {
  proxy_pass http://localhost:9003/;
  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "upgrade";
}
EOF

systemctl restart mango
