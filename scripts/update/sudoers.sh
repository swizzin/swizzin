#!/bin/bash

users=($(cut -d: -f1 < /etc/htpasswd))
master=$(cut -d: -f1 < /root/.master.info)
distribution=$(lsb_release -is)

if [[ ! -f /etc/sudoers.d/env_keep ]] && [[ $distribution = "Ubuntu" ]]; then
    echo 'Defaults  env_keep -="HOME"' > /etc/sudoers.d/env_keep
fi

for u in "${users[@]}"; do
  if [[ $u = "$master" ]]; then continue; fi
  USER=${u^^}
  if grep -q ${USER}CMNDS /etc/sudoers.d/$u; then
    echo "Fixing sudo permissions for $u"
    sed -i "s/${USER}CMNDS/${USER}CMDS/g" /etc/sudoers.d/$u
  fi
done

for u in "${users[@]}"; do
  if [[ $u = "$master" ]]; then continue; fi
  USER=${u^^}
  if grep -q flood /etc/sudoers.d/$u; then
    :
  else
    echo "Adding flood sudo permissions for $u"
    sed -i "s/${USER}CMDS = /${USER}CMDS = \/bin\/systemctl stop flood@${user}, \/bin\/systemctl restart flood@${user}, \/bin\/systemctl start flood@${user}, /g" /etc/sudoers.d/$u
  fi
done

if [[ -f /etc/sudoers.d/panel ]]; then
  if grep -q -E "(sed|grep|box|drop_caches|set_interface|pkill|killall|reload|vnstat|ifstat|PACKAGECMNDS)" /etc/sudoers.d/panel; then
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
fi
fi
