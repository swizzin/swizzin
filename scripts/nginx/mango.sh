#!/bin/bash
# Nginx configuration for Mango

cat > /etc/nginx/apps/mango.conf <<EOF
location /mango/ {
  proxy_pass http://localhost:9003/;
}
EOF

sed -i 's=base_url: /=base_url: /mango=' /opt/mango/.config/mango/config.yml
systemctl restart mango

systemctl reload nginx