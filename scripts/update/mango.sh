#!/bin/bash

#If the user tried to upgrade mango before the issue got fixed, the binary was downloaded to the / dir and nothing got refreshed.
if [[ -f /mango ]]; then
    rm /mango
fi

#If this file existed, delete it
if [[ -f /root/mango.info ]]; then
    rm /root/mango.info
fi

# Adding support for websockets
if [[ -f /etc/nginx/apps/mango.conf ]]; then
    if ! grep -q "proxy_set_header Upgrade \$http_upgrade;" /etc/nginx/apps/mango.conf; then
        echo_log_only "Adding websocket support to mango nginx conf"
        cat > /etc/nginx/apps/mango.conf << EOF
location /mango/ {
  proxy_pass http://localhost:9003/;
  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "upgrade";
}
EOF
        systemctl nginx reload
    fi
fi
