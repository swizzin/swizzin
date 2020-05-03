#!/bin/bash
# Nginx configuration for wg-daashboard

MASTER=$(cut -d: -f1 < /root/.master.info)
cat > /etc/nginx/apps/wg-dashboard.conf <<EOF
location /wg-dashboard/ {
proxy_pass http://127.0.0.1:3000/;
proxy_http_version 1.1;
proxy_set_header Connection "upgrade";
proxy_set_header Upgrade \$http_upgrade;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
EOF

nginx -t
nginx -s reload