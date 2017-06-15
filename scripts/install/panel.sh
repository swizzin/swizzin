#!/bin/bash
#QB Panel installer for swizzin
#Author: swizzin | lizaSB
IFACE=$(ip link show|grep -i broadcast|grep -m1 UP|cut -d: -f 2|cut -d@ -f 1|sed -e 's/ //g');
user=$(cat /etc/.master.info | cut -d: -f2)
cd /srv/
git clone https://gitlab.swizzin.ltd/quickbox_dashbord panel

chown -R www-data: /srv/panel

touch /srv/panel/db/output.log
printf "${IFACE}" > /srv/panel/db/interface.txt
printf "${user}" > /srv/panel/db/master.txt
LOCALE=en_GB.UTF-8
LANG=lang_en
sed -i "s/LOCALE/${LOCALE}/g" /srv/panel/inc/localize.php
sed -i "s/LANG/${LANG}/g" /srv/panel/inc/localize.php
echo "*/1 * * * * root bash /usr/local/bin/swizzin/set_interface" > /etc/cron.d/set_interface

cat > /etc/nginx/sites-enabled/panel.conf <<PAN
location / {
alias /srv/panel;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd;
}
PAN

service nginx force-reload
touch /install/.panel.lock
