#!/bin/bash
# Nginx configuration for Deluge
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in "${users[@]}"; do
  if [[ ! -f /etc/nginx/apps/dindex.${u}.conf ]]; then
  cat > /etc/nginx/apps/dindex.${u}.conf <<DIN
location /${u}.deluge.downloads {
  alias /home/${u}/torrents/deluge;
  fancyindex on;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${u};
}
DIN
  fi
done