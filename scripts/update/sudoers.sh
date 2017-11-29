#!/bin/bash

users=($(cat /etc/htpasswd | cut -d ":" -f 1))
master=$(cat /root/.master.info | cut -d: -f1)

for u in "${users[@]}"; do
  if [[ $u = "$master" ]]; then continue; fi
  USER=${u^^}
  if grep -q ${USER}CMNDS /etc/sudoers.d/$u; then
    echo "Fixing sudo permissions for $u"
    sed -i "s/${USER}CMNDS/${USER}CMDS/g" /etc/sudoers.d/$u
  fi
done
