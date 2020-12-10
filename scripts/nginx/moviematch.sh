#!/bin/bash

cat > /etc/nginx/apps/moviematch.conf << NGINX
    location ^~ /moviematch/ {
        proxy_pass http://127.0.0.1:8420/;
        proxy_set_header Upgrade \$http_upgrade;
    }

NGINX

echo "ROOT_PATH=/moviematch" >> /opt/moviematch/.env