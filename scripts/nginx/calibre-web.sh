#!/bin/bash
cat > /etc/nginx/apps/calibre-web.conf << EOF
location /calibre-web {
        proxy_bind              \$server_addr;
        proxy_pass              http://127.0.0.1:8083;
        proxy_set_header        Host            \$http_host;
        proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header        X-Scheme        \$scheme;
        proxy_set_header        X-Script-Name   /calibre-web;  # IMPORTANT: path has NO trailing slash
}
EOF

sed '/ExecStart=/ s/$/ -i 127.0.0.1/' -i /etc/systemd/system/calibre-web.service
systemctl daemon-reload
systemctl try-restart calibre-web