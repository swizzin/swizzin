#!/bin/bash
# Jackett updater script

if [[ -f /install/.jackett.lock ]]; then
  if grep -q "WorkingDirectory=/home/%I/Jackett" /etc/systemd/system/jackett@.service; then
    :
  else
    sed -i 's/WorkingDirectory.*/WorkingDirectory=\/home\/%I\/Jackett/g' /etc/systemd/system/jackett@.service
    sleep 1; systemctl daemon-reload
  fi

  if grep -q 'ExecStart=/bin/sh -c "/home/%I/Jackett/jackett --NoRestart"' /etc/systemd/system/jackett@.service; then
    :
  else
    sed -i 's|ExecStart.*|ExecStart=/bin/sh -c "/home/%I/Jackett/jackett --NoRestart"|g' /etc/systemd/system/jackett@.service
    systemctl daemon-reload
  fi

  if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/jackett@.service; then
    user=$(cat /root/.master.info | cut -d: -f1)
    active=$(systemctl is-active jackett@$user)
    jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | grep -v repository | awk -F "[><]" '{print $3}')
    sed -i 's|ExecStart.*|ExecStart=/bin/sh -c "/home/%I/Jackett/jackett --NoRestart"|g' /etc/systemd/system/jackett@.service
    systemctl daemon-reload
    if [[ $active == "active" ]]; then
      systemctl stop jackett@$user
    fi
    rm -rf /home/$user/Jackett
    cd /home/$user
    wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.LinuxAMDx64.tar.gz
    tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz > /dev/null 2>&1
    rm -f Jackett.Binaries.LinuxAMDx64.tar.gz
    chown ${username}.${username} -R Jackett
    if [[ $active == "active" ]]; then
      systemctl start jackett@$user
    fi
  else
    :
  fi
  if grep -q "proxy_set_header Host" /etc/nginx/apps/jackett.conf; then
    sed -i "/proxy_set_header Host/d" /etc/nginx/apps/jackett.conf
    systemctl reload nginx
  fi
fi