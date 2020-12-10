#!/bin/bash

cat > /etc/nginx/apps/moviematch.conf << NGINX
location /moviematch/ {
    # rewrite /foo/(.*) /$1  break;
  proxy_pass http://localhost:8420/;
  proxy_redirect     off;
  proxy_set_header   Host \$host;
}

NGINX
