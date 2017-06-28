#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
if [[ ! -f /etc/nginx/apps/sickrage.conf ]]; then
  cat > /etc/nginx/apps/sickrage.conf <<SRC
location /sickrage {
    include /etc/nginx/conf.d/proxy.conf;
    proxy_pass        http://127.0.0.1:8081/sickrage;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SRC
fi
sed -i "s/web_root.*/web_root = \"sickrage\"/g" /home/"${MASTER}"/.sickrage/config.ini
sed -i "s/web_host.*/web_host = localhost/g" /home/"${MASTER}"/.sickrage/config.ini
