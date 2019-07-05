#!/bin/bash
# QuickBox dashboard installer for Swizzin
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
IFACE=$(ip link show|grep -i broadcast|grep -m1 UP|cut -d: -f 2|cut -d@ -f 1|sed -e 's/ //g');
user=$(cat /root/.master.info | cut -d: -f1)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi

cd /srv/
git clone https://github.com/liaralabs/quickbox_dashboard.git panel >>$log 2>&1

chown -R www-data: /srv/panel

touch /srv/panel/db/output.log
printf "${IFACE}" > /srv/panel/db/interface.txt
printf "${user}" > /srv/panel/db/master.txt
LOCALE=en_GB.UTF-8
LANG=lang_en
sed -i "s/LOCALE/${LOCALE}/g" /srv/panel/inc/localize.php
sed -i "s/LANG/${LANG}/g" /srv/panel/inc/localize.php
echo "*/1 * * * * root bash /usr/local/bin/swizzin/panel/set_interface" > /etc/cron.d/set_interface

if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
  sock=php7.3-fpm
elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
  sock=php7.2-fpm
elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
  sock=php7.1-fpm
else
  sock=php7.0-fpm
fi

cat > /etc/nginx/apps/panel.conf <<PAN
location / {
alias /srv/panel/ ;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd;
try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
index index.php;
allow all;
location ~ \.php$
  {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/$sock.sock;
    #fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /srv/panel\$fastcgi_script_name;
  }
}

PAN

cat > /etc/sudoers.d/panel <<SUD
#secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin:/usr/local/bin/swizzin/scripts:/usr/local/bin/swizzin/scripts/install:/usr/local/bin/swizzin/scripts/remove:/usr/local/bin/swizzin/panel"
#Defaults  env_keep -="HOME"

# Host alias specification

# User alias specification

# Cmnd alias specification
Cmnd_Alias   CLEANMEM = /usr/local/bin/swizzin/panel/clean_mem
Cmnd_Alias   SYSCMNDS = /usr/local/bin/swizzin/panel/lang/langSelect-*, /usr/local/bin/swizzin/panel/theme/themeSelect-*
Cmnd_Alias   GENERALCMNDS = /usr/sbin/repquota, /bin/systemctl

www-data     ALL = (ALL) NOPASSWD: CLEANMEM, SYSCMNDS, GENERALCMNDS

SUD
service nginx force-reload

