#!/usr/bin/env bash

cat > /etc/nginx/apps/komga.conf <<- NGX
location /komga {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:6800/komga;
}
NGX
