#!/bin/bash
# Nginx configuration for wg-daashboard

cat > /etc/nginx/apps/wg-dashboard.conf <<EOF
location /wg-dashboard/ {
proxy_pass http://127.0.0.1:3024/;
proxy_http_version 1.1;
proxy_set_header Connection "upgrade";
proxy_set_header Upgrade \$http_upgrade;
proxy_set_header X-Forwarded-For \$remote_addr;
# by default nginx times out connections in one minute
proxy_read_timeout 1d;
}
EOF

nginx -t
nginx -s reload