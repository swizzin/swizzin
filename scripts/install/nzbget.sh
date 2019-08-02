#!/bin/bash
# NZBGet installer for swizzin
# Author: liara
# 
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

function _download {
  cd /tmp
  wget https://nzbget.net/download/nzbget-latest-bin-linux.run >> $log 2>&1
}

function _service {
  cat > /etc/systemd/system/nzbget@.service <<NZBGD
[Unit]
Description=NZBGet Daemon
Documentation=http://nzbget.net/Documentation
After=network.target

[Service]
User=%I
Group=%I
Type=forking
ExecStart=/bin/sh -c "/home/%I/nzbget/nzbget -D"
ExecStop=/bin/sh -c "/home/%I/nzbget/nzbget -Q"
ExecReload=/bin/sh -c "/home/%I/nzbget/nzbget -O"
Restart=on-failure

[Install]
WantedBy=multi-user.target
NZBGD
}

function _install {
  cd /tmp
    for u in "${users[@]}"; do
      sh nzbget-latest-bin-linux.run --destdir /home/$u/nzbget >> $log 2>&1
      chown -R $u:$u /home/$u/nzbget
      if [[ $u == $master ]]; then
        :
      else
        port=$(shuf -i 6000-7000 -n 1)
        secureport=$(shuf -i 6000-7000 -n 1)
        sed -i "s/ControlPort=6789/ControlPort=${port}/g" /home/$u/nzbget/nzbget.conf
        sed -i "s/SecurePort=6791/SecurePort=${secureport}/g" /home/$u/nzbget/nzbget.conf
      fi
    done

  if [[ ! -d /home/$u/.ssl/ ]]; then
    mkdir -p /home/$u/.ssl/
  fi

  . /etc/swizzin/sources/functions/ssl

  create_self_ssl $u

  sed -i "s/SecureControl=no/SecureControl=yes/g" /home/$u/nzbget/nzbget.conf
  sed -i "s/SecureCert=/SecureCert=\/home\/$u\/.ssl\/$u-self-signed.crt/g" /home/$u/nzbget/nzbget.conf
  sed -i "s/SecureKey=/SecureKey=\/home\/$u\/.ssl\/$u-self-signed.key/g" /home/$u/nzbget/nzbget.conf

  
  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/nzbget.sh
    systemctl reload nginx
  fi

  for u in "${users[@]}"; do
    systemctl enable nzbget@$u >> $log 2>&1
    systemctl start nzbget@$u
  done
}

function _cleanup {
  cd /tmp
  rm -rf nzbget-latest-bin-linux.run
}
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi

users=($(cut -d: -f1 < /etc/htpasswd))
master=$(cut -d: -f1 < /root/.master.info)
noexec=$(grep "/tmp" /etc/fstab | grep noexec)

if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi

if [[ -n $1 ]]; then
  users=($1)
  _download
  _install
  _cleanup
  exit 0
fi

_download
_service
_install
_cleanup
touch /install/.nzbget.lock

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi
