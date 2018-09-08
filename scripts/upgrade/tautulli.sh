#!/bin/bash

if [[ ! -f /install/.plexpy.lock && ! -f /install/.tautulli.lock ]]; then
  exit 0
fi

# backup plexpy config and remove it
if [[ -f /install/.plexpy.lock ]]; then
  systemctl stop plexpy
  cp -a /opt/plexpy/config.ini /tmp/config.ini.tautulli_bak &>/dev/null
  cp -a /opt/plexpy/plexpy.db /tmp/tautulli.db.tautulli_bak &>/dev/null
  cp -a /opt/plexpy/tautulli.db /tmp/tautulli.db.tautulli_bak &>/dev/null

  systemctl stop plexpy
  systemctl disable plexpy
  rm -rf /opt/plexpy
  rm /install/.plexpy.lock
  rm -f /etc/nginx/apps/plexpy.conf
  service nginx reload
  rm /etc/systemd/system/plexpy.service
fi

# backup tautulli
if [[ -f /install/.tautulli.lock ]]; then
  systemctl stop tautulli
  cp -a /opt/tatulli/config.ini /tmp/config.ini.tautulli_bak &>/dev/null
  cp -a /opt/tautulli/tautulli.db /tmp/tautulli.db.tautulli_bak &>/dev/null
fi


# install latest version
if [[ ! -f /install/.tautulli.lock ]]; then
  # plexpy was installed, install tautulli
  source /usr/local/bin/swizzin/install/tautulli.sh &>/dev/null
  systemctl stop tautulli
else
  mkdir -p /opt/tautulli
  curl -s https://api.github.com/repos/tautulli/tautulli/releases/latest | grep "tarball" | cut -d : -f 2,3 | tr -d \", | wget -q -i- -O- | tar xz -C /opt/tautulli --strip-components 1
  chown tautulli:nogroup -R /opt/tautulli
fi

# restore backups
mv  /tmp/config.ini.tautulli_bak /opt/tautulli/config.ini &>/dev/null
mv  /tmp/tautulli.db.tautulli_bak /opt/tautulli/tautulli.db &>/dev/null
systemctl start tautulli
