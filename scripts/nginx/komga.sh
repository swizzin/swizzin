#!/usr/bin/env bash

cat > /etc/nginx/apps/komga.conf <<- NGX
location /komga {
    proxy_pass      http://127.0.0.1:6800/komga;
    auth_basic      "Realm";
}
NGX
