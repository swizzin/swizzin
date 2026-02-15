#!/bin/bash
# Nginx proxy for Calibre-Web Automated (CWA)
cat > /etc/nginx/apps/calibreweb.conf << EOF
location /calibreweb {
        proxy_pass              http://127.0.0.1:8083;
        proxy_set_header        Host            \$http_host;
        proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header        X-Scheme        \$scheme;
        proxy_set_header        X-Script-Name   /calibreweb;  # IMPORTANT: path has NO trailing slash
        
        # Add Kobo Support. See https://github.com/janeczku/calibre-web/issues/1891#issuecomment-801886803
        proxy_buffer_size       1024k;
        proxy_buffers           4 512k;
        proxy_busy_buffers_size 1024k;
}
EOF

sed '/ExecStart=/ s/$/ -i 127.0.0.1/' -i /etc/systemd/system/calibreweb.service
systemctl daemon-reload
systemctl try-restart calibreweb
