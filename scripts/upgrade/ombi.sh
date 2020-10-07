#!/bin/bash
# Upgrade ombi
# Author liara

if grep -q "\-\-storage" /etc/systemd/system/ombi.service; then
  :
else
  sed -i '/^ExecStart=/ s/$/ --storage \/etc\/Ombi/' /etc/systemd/system/ombi.service
  systemctl daemon-reload
  for f in Ombi.db Ombi.db.backup Schedules.db; do
    if [[ -f /opt/Ombi/$f ]]; then
      if [[ /opt/Ombi/$f -nt /etc/Ombi/$f ]] || [[ ! -f /etc/Ombi/$f ]]; then
        cp -a /opt/Ombi/$f /etc/Ombi/$f
      fi
    fi
  done
  if [[ -f /etc/Ombi/Ombi.db ]] && [[ -f /etc/Ombi/Ombi.db.backup ]]; then
    if [[ /etc/Ombi/Ombi.db.backup -nt /etc/Ombi/Ombi.db ]]; then
      mv /etc/Ombi/Ombi.db /etc/Ombi/Ombi.db.backup.swizz
      cp -a /etc/Ombi/Ombi.db.backup /etc/Ombi/Ombi.db
    fi
  fi
  chown -R ombi:nogroup /etc/Ombi
  systemctl restart ombi
fi

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
  apt_install ombi
  cat > /etc/systemd/system/ombi.service <<OMB
[Unit]
Description=Ombi - PMS Requests System
After=network-online.target

[Service]
User=ombi
Group=nogroup
WorkingDirectory=/opt/Ombi/
ExecStart=/opt/Ombi/Ombi --baseurl /ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
Type=simple
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
OMB

  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/ombi.sh
    systemctl reload nginx
  fi
fi

user=$(cut -d: -f1 < /root/.master.info)

systemctl start ombi