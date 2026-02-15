#!/bin/bash
# Scrutiny nginx configuration by flying_sausages for Swizzin 2020
# GPLv3 applies

scrutinydir="/opt/scrutiny"
webport=8087
user=$(cut -d: -f1 < /root/.master.info)

cat > /etc/nginx/apps/scrutiny.conf << EOF
location /scrutiny/ {
    proxy_pass          http://localhost:$webport;
    proxy_set_header    X-Forwarded-Host    \$http_host;
    auth_basic          "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
EOF
sed -i "/^  listen:/a \ \ \ \ \basepath: '/scrutiny'" "$scrutinydir/config/scrutiny.yaml"
sed -i "s/^\(\s*host:\s*\)0.0.0.0/\1127.0.0.1/" "$scrutinydir/config/scrutiny.yaml"

systemctl restart scrutiny-web.service
