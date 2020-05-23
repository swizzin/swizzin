#!/bin/bash
# Nginx configuration for Mango


cat > /etc/nginx/apps/mango.conf <<EOF
location /mango {
  # TODO this does not work
  # rewrite /mango(.*) /\$1 break;
  # rewrite ^/mango/(.*)\$  /\$1 break;
  proxy_pass http://127.0.0.1:9003/;
  proxy_redirect https://\$host /mango;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$remote_addr;
  proxy_set_header X-Request-URI \$request; #** This adds the original path as a header **
  proxy_set_header Host \$host:\$server_port;

}
EOF

systemctl reload nginx