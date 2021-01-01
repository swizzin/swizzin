#!/usr/bin/env bash

cat > /etc/nginx/apps/overseerr.conf << EOF
location /overseerr/ {
  proxy_pass http://localhost:5055/;
}
EOF
