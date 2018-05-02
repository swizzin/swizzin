#!/bin/bash
# Upgrade ombi
# Author liara

if [[ -f /etc/apt/sources.list.d/ombi.list ]]; then
  echo "Nothing to do! Please update ombi with apt-get"
  exit 1
else
  echo "Upgrading Ombi to v3! Please note, v2 database and settings will be deleted. Hit control-c to quit now if you do not agree."
  read -p "Press enter to continue"
  echo "Upgrading Ombi. Please wait ... "
  systemctl stop ombi
  rm -rf /opt/ombi

  echo "deb http://repo.ombi.turd.me/stable/ jessie main" > /etc/apt/sources.list.d/ombi.list
  wget -qO - https://repo.ombi.turd.me/pubkey.txt | sudo apt-key add -
  apt-get update -q >/dev/null 2>&1
  apt-get install -y -q ombi > /dev/null 2>&1
  cat > /etc/systemd/system/ombi.service <<OMB
[Unit]
Description=Ombi - PMS Requests System
After=network-online.target

[Service]
User=ombi
Group=nogroup
WorkingDirectory=/opt/Ombi/
ExecStart=/opt/Ombi/Ombi --baseurl /ombi --host http://0.0.0.0:3000
Type=simple
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
OMB

  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/ombi.sh
    service nginx reload
  fi
fi

user=$(cat /root/.master.info | cut -d: -f1)

systemctl start ombi