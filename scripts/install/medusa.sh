#! /bin/bash
# Medusa installer for swizzin
# Author: liara

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi
user=$(cut -d: -f1 < /root/.master.info)
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ $(systemctl is-active sickgear) == "active" ]]; then
  active=sickgear
fi

if [[ $(systemctl is-active sickchill) == "active" ]]; then
  active=sickchill
fi

if [[ -n $active ]]; then
  echo_info "SickChill and Medusa and Sickgear cannot be active at the same time.\n\tDo you want to disable $active and continue with the installation?\n\tDon't worry, your install will remain at /opt/$active"
  while true; do
  echo_query "Do you want to disable $active? " "y/n"
  read  yn
      case "$yn" in
          [Yy]|[Yy][Ee][Ss]) disable=yes; break;;
          [Nn]|[Nn][Oo]) disable=; break;;
          *) echo_warn "Please answer yes or no.";;
      esac
  done
  if [[ $disable == "yes" ]]; then
    systemctl disable --now ${active}
  else
    exit 1
  fi
fi

mkdir -p /opt/.venv
chown ${user}: /opt/.venv

apt_install git-core openssl libssl-dev python3 python3-venv

# maybe TODO pyenv this up and down?
echo_progress_start "Making venv for medusa"
python3 -m venv /opt/.venv/medusa
chown -R ${user}: /opt/.venv/medusa
echo_progress_done

install_rar

echo_progress_start "Cloning medusa source code"
cd /opt/
git clone https://github.com/pymedusa/Medusa.git medusa >> ${log} 2>&1
chown -R ${user}:${user} medusa
echo_progress_done

echo_progress_start "Installing systemd service"

cat > /etc/systemd/system/medusa.service <<MSD
[Unit]
Description=Medusa
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/opt/.venv/medusa/bin/python3 /opt/medusa/SickBeard.py -q --daemon --nolaunch --datadir=/opt/medusa
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
MSD

systemctl enable --now medusa >>$log 2>&1
echo_progress_done "Medusa started"

if [[ -f /install/.nginx.lock ]]; then
  echo_progress_start "Configuring nginx"
  bash /usr/local/bin/swizzin/nginx/medusa.sh
  systemctl reload nginx
  echo_progress_done
fi

echo_success "Medua installed"
touch /install/.medusa.lock
