#!/bin/bash
#QB Panel installer for swizzin
#Author: swizzin | lizaSB
IFACE=$(ip link show|grep -i broadcast|grep -m1 UP|cut -d: -f 2|cut -d@ -f 1|sed -e 's/ //g');
user=$(cat /root/.master.info | cut -d: -f1)

if [[ ! -f /install/.nginx.lock ]]; then
  echo "ERROR: Web server not detected. Please install nginx and restart panel install."
else
  cd /srv/
  export GIT_SSL_NO_VERIFY=true
  git clone https://gitlab.swizzin.ltd/liara/quickbox_dashboard.git panel

  chown -R www-data: /srv/panel

  touch /srv/panel/db/output.log
  printf "${IFACE}" > /srv/panel/db/interface.txt
  printf "${user}" > /srv/panel/db/master.txt
  LOCALE=en_GB.UTF-8
  LANG=lang_en
  sed -i "s/LOCALE/${LOCALE}/g" /srv/panel/inc/localize.php
  sed -i "s/LANG/${LANG}/g" /srv/panel/inc/localize.php
  echo "*/1 * * * * root bash /usr/local/bin/swizzin/set_interface" > /etc/cron.d/set_interface

  cat > /etc/nginx/apps/panel.conf <<PAN
location / {
alias /srv/panel/ ;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd;
try_files $uri $uri/ /index.php?q=$uri&$args;
index index.php;
allow all;
}

PAN

  service nginx force-reload
  touch /install/.panel.lock
fi
