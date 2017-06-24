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
try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
index index.php;
allow all;
location ~ \.php$
  {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    #fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /srv/panel\$fastcgi_script_name;
  }
}

PAN

cat > /etc/sudoers.d/panel <<SUD
secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin:/usr/local/bin/swizzin/scripts:/usr/local/bin/swizzin/scripts/install:/usr/local/bin/swizzin/scripts/remove:/usr/local/bin/swizzin/panel"
#Defaults  env_keep -="HOME"

# Host alias specification

# User alias specification

# Cmnd alias specification
Cmnd_Alias   CLEANMEM = /usr/local/bin/swizzin/clean_mem, /proc/sys/vm/drop_caches
Cmnd_Alias   SYSCMNDS = /usr/local/bin/swizzin/clean_log, /usr/local/bin/swizzin/set_interface, /usr/local/bin/quickbox/system/setdisk, /usr/local/bin/quickbox/system/showspace, /usr/local/bin/quickbox/system/updateQuickBox, /usr/local/bin/quickbox/system/lang/langSelect-*, /usr/local/bin/quickbox/system/theme/themeSelect-*, /usr/local/bin/quickbox/system/install_ffmpeg, /usr/local/bin/quickbox/system/quickVPN, /usr/local/bin/quickbox/system/box
Cmnd_Alias   PLUGINCMNDS = /usr/local/bin/quickbox/plugin/install/installplugin-*, /usr/local/bin/quickbox/plugin/remove/removeplugin-*
Cmnd_Alias   PACKAGECMNDS = /usr/local/bin/quickbox/package/install/installpackage-*, /usr/local/bin/quickbox/package/remove/removepackage-*
Cmnd_Alias   GENERALCMNDS = /usr/bin/ifstat, /usr/bin/vnstat, /usr/sbin/repquota, /bin/grep, /usr/bin/awk, /usr/bin/reload, /etc/init.d/apache2 restart, /usr/bin/pkill, /usr/bin/killall, /bin/sed, /bin/systemctl

# User privilege specification
root	ALL=(ALL:ALL) ALL
www-data     ALL = (ALL) NOPASSWD: CLEANMEM, SYSCMNDS, PLUGINCMNDS, PACKAGECMNDS, GENERALCMNDS

# Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL

# Allow members of group sudo to execute any command
%www-data     ALL = (ALL) NOPASSWD: CLEANMEM, SYSCMNDS, PLUGINCMNDS, PACKAGECMNDS, GENERALCMNDS
%sudo	ALL=(ALL:ALL) ALL
SUD
  service nginx force-reload
  touch /install/.panel.lock
fi
