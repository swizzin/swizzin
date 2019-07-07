#! /bin/bash

if [[ -d /srv/panel ]]; then
  echo "Updating panel"
  cd /srv/panel
  if grep -q "repquota /home" /srv/panel/widgets/disk_data.php; then 
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
  if [[ $disk = "home" ]]; then
    /usr/local/bin/swizzin/panel/fix-disk home
  fi
  if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
    systemctl restart php7.3-fpm
    if [[ $(systemctl is-active php7.2-fpm) == "active" ]]; then
      systemctl stop php7.2-fpm
      systemctl disable php7.2-fpm
    fi
    if [[ $(systemctl is-active php7.1-fpm) == "active" ]]; then
      systemctl stop php7.1-fpm
      systemctl disable php7.1-fpm
    fi
    if [[ $(systemctl is-active php7.0-fpm) == "active" ]]; then
      systemctl stop php7.0-fpm
      systemctl disable php7.0-fpm
    fi
  elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
    systemctl restart php7.2-fpm
    if [[ $(systemctl is-active php7.1-fpm) == "active" ]]; then
      systemctl stop php7.1-fpm
      systemctl disable php7.1-fpm
    fi
    if [[ $(systemctl is-active php7.0-fpm) == "active" ]]; then
      systemctl stop php7.0-fpm
      systemctl disable php7.0-fpm
    fi
  elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
    systemctl restart php7.1-fpm
    if [[ $(systemctl is-active php7.0-fpm) == "active" ]]; then
      systemctl stop php7.0-fpm
      systemctl disable php7.0-fpm
    fi
  else
    systemctl restart php7.0-fpm
  fi
   systemctl restart nginx
fi