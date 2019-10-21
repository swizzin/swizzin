#! /bin/bash

if [[ -d /srv/panel ]]; then
  echo "Updating panel"
  cd /srv/panel
  if ! grep -q 'disk_total_space(".")' /srv/panel/widgets/disk_data.php; then 
    disk=home
  fi
  git fetch origin master
  menu=$(git diff master:custom/custom.menu.php  -- custom/custom.menu.php)
  if [[ -n $menu ]]; then
    cp -a custom/custom.menu.php /tmp/
  fi
  git reset HEAD --hard > /dev/null 2>&1
  git pull || { panelreset=1; }
  if [[ $panelreset == 1 ]]; then
    echo "Updating the panel appears to have failed. This is probably my fault, not yours."
    echo ""
    read -n 1 -s -r -p "Press any key to forcefully reset the panel. Your custom entires, theme and language will be backed up and restored"
    echo ""
    cd /srv
    lang=$(grep \$language inc/localize.php | cut -d\' -f2)
    if [[ -f /srv/panel/db/.defaulted.lock ]]; then default=1; fi;
    cp -a /srv/panel/custom /tmp
    /usr/local/bin/swizzin/remove/panel.sh
    /usr/local/bin/swizzin/install/panel.sh
    mv /tmp/custom/* /srv/panel/custom/
    if [[ $default == 1 ]]; then
      bash /usr/local/bin/swizzin/panel/theme/themeSelect-defaulted
    fi
    bash /usr/local/bin/swizzin/panel/lang/langSelect-$lang
  fi
  if [[ -n $menu ]]; then
    cd /srv/panel
    cp -a /tmp/custom.menu.php custom/
  fi
  if ! grep -q pam_session /etc/sudoers.d/panel; then
  cat > /etc/sudoers.d/panel <<SUD
#secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin:/usr/local/bin/swizzin/scripts:/usr/local/bin/swizzin/scripts/install:/usr/local/bin/swizzin/scripts/remove:/usr/local/bin/swizzin/panel"
#Defaults  env_keep -="HOME"
Defaults:www-data !logfile
Defaults:www-data !syslog
Defaults:www-data !pam_session


# Host alias specification

# User alias specification

# Cmnd alias specification
Cmnd_Alias   CLEANMEM = /usr/local/bin/swizzin/panel/clean_mem
Cmnd_Alias   SYSCMNDS = /usr/local/bin/swizzin/panel/lang/langSelect-*, /usr/local/bin/swizzin/panel/theme/themeSelect-*
Cmnd_Alias   GENERALCMNDS = /usr/bin/quota, /bin/systemctl

www-data     ALL = (ALL) NOPASSWD: CLEANMEM, SYSCMNDS, GENERALCMNDS

SUD
  fi
  if grep -q /usr/sbin/repquota /etc/sudoers.d/panel; then
    sed -i 's|/usr/sbin/repquota|/usr/bin/quota|g' /etc/sudoers.d/panel
  fi
  if [[ $disk = "home" ]]; then
    /usr/local/bin/swizzin/panel/fix-disk home
  fi
  . /etc/swizzin/sources/functions/php
  restart_php_fpm
  systemctl restart nginx
fi