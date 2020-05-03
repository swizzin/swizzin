#!/bin/bash
# Nginx configuration for wg-daashboard

MASTER=$(cut -d: -f1 < /root/.master.info)
cat > /etc/nginx/apps/wg-dashboard.conf <<EOF
location /wg-dashboard/ {
  rewrite /wg-dashboard/(.*) /$1 break;
  proxy_pass http://localhost:3000/;
  proxy_redirect     off;
  proxy_set_header   Host \$host;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}

# location / {
#   if (\$http_referer ~ "^https?://[^/]+/wg-dashboard"){
#     rewrite ^/(.*) https://\$http_host/wg-dashboard/\$1 redirect;
#   }
# }


EOF

nginx -t
nginx -s reload