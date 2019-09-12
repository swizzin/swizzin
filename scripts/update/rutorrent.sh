#!/bin/bash

#Update club-QuickBox with latest changes
if [[ -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
  cd /srv/rutorrent/plugins/theme/themes/club-QuickBox
  git reset HEAD --hard
  git pull
fi

if [[ -d /srv/rutorrent/plugins/theme/themes/DarkBetter ]]; then
  if [[ -z "$(ls -A /srv/rutorrent/plugins/theme/themes/DarkBetter/)" ]]; then
    cd /srv/rutorrent
    git submodule update --init --recursive > /dev/null 2>&1
  fi
fi

if [[ -f /install/.flood.lock ]]; then
  users=($(cut -d: -f1 < /etc/htpasswd))
  for u in ${users[@]}; do
    if [[ ! -f /etc/nginx/apps/${u}.scgi.conf ]]; then
      cat > /etc/nginx/apps/${u}.scgi.conf <<RUC
location /${u} {
include scgi_params;
scgi_pass unix:/var/run/${u}/.rtorrent.sock;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd.d/htpasswd.${u};
}
RUC
    fi
  done
  systemctl reload nginx
fi

if [[ -f /install/.quota.lock ]] && { ! grep -q "/usr/bin/quota -wu" /srv/rutorrent/plugins/diskspace/action.php > /dev/null 2>&1 || [[ ! $(grep -c cachedEcho /srv/rutorrent/plugins/diskspace/action.php) == 2 ]] ;} ; then
  cat > /srv/rutorrent/plugins/diskspace/action.php <<'DSKSP'
<?php
#################################################################################
##  [Quick Box - action.php modified for quota systems use]
#################################################################################
# QUICKLAB REPOS
# QuickLab _ packages:   https://github.com/QuickBox/quickbox_rutorrent-plugins
# LOCAL REPOS
# Local _ packages   :   ~/QuickBox/rtplugins
# Author             :   QuickBox.IO
# URL                :   https://plaza.quickbox.io
#
#################################################################################
  require_once( '../../php/util.php' );
  if (isset($quotaUser) && file_exists('/install/.quota.lock')) {
    $total = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $3*1024}'");
    $used = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $2*1024}'");
    $free = sprintf($total - $used);
    cachedEcho('{ "total": '.$total.', "free": '.$free.' }',"application/json");
  } else {
      cachedEcho('{ "total": '.disk_total_space($topDirectory).', "free": '.disk_free_space($topDirectory).' }',"application/json");
  }
?>
DSKSP
. /etc/swizzin/sources/functions/php
restart_php_fpm
fi