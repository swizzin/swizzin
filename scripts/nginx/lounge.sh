#!/bin/bash
# Nginx configuration for The Lounge

isactive=$(systemctl is-active lounge)

cat > /etc/nginx/apps/lounge.conf <<EOF
location /irc/ {
proxy_pass http://127.0.0.1:9000/;
proxy_http_version 1.1;
proxy_set_header Connection "upgrade";
proxy_set_header Upgrade \$http_upgrade;
proxy_set_header X-Forwarded-For \$remote_addr;
# by default nginx times out connections in one minute
proxy_read_timeout 1d;
}
EOF
sed -i 's/host: undefined,/host: "127.0.0.1",/g' /home/lounge/.thelounge/config.js
sed -i 's/reverseProxy: false,/reverseProxy: true,/g' /home/lounge/.thelounge/config.js

if [[ $isactive == "active" ]]; then
  systemctl restart lounge
fi