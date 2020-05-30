#!/bin/bash
# Nginx Configuration for Mylar
# Author: Public920

user=$(cut -d: -f1 < /root/.master.info)

isactive=$(systemctl is-active mylar)
if [[ $isactive == "active" ]]; then
    systemctl stop mylar
fi

if [[ ! -f /etc/nginx/apps/mylar.conf ]]; then
    cat > /etc/nginx/apps/mylar.conf <<MYNG
location /mylar {
    include /etc/nginx/snippets/proxy.conf;
    proxy_pass http://127.0.0.1:8090/mylar;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
MYNG
fi

if [[ $isactive == "active" ]]; then
  systemctl restart mylar
fi