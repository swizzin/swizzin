#!/bin/bash
# Nginx proxy for Calibre-Web Automated (CWA)
cat > /etc/nginx/apps/calibrewebautomated.conf << EOF
location /calibrewebautomated {
        proxy_pass              http://127.0.0.1:8083;
        proxy_set_header        Host            \$http_host;
        proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header        X-Scheme        \$scheme;
        proxy_set_header        X-Script-Name   /calibrewebautomated;  # IMPORTANT: path has NO trailing slash
}
EOF

sed '/ExecStart=/ s/$/ -i 127.0.0.1/' -i /etc/systemd/system/calibrewebautomated.service
systemctl daemon-reload
systemctl try-restart calibrewebautomated
