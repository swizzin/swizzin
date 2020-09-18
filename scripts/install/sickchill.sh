#!/bin/bash
# SickChill installer for swizzin
# Author: liara

user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)
. /etc/swizzin/sources/functions/pyenv
. /etc/swizzin/sources/functions/utils

if [[ $(systemctl is-active medusa) == "active" ]]; then
  active=medusa
fi

if [[ $(systemctl is-active sickgear) == "active" ]]; then
  active=sickgear
fi

if [[ -n $active ]]; then
  echo_info "SickChill and Medusa and Sickgear cannot be active at the same time.\n\tDo you want to disable $active and continue with the installation?\n\tDon't worry, your install will remain at /opt/$active"
  while true; do
    echo_query "Do you want to disable $active? " "y/n"
    read yn
    case "$yn" in
        [Yy]|[Yy][Ee][Ss]) disable=yes; break;;
        [Nn]|[Nn][Oo]) disable=; break;;
        *) echo_warn "Please answer yes or no.";;
    esac
  done
  if [[ $disable == "yes" ]]; then
    echo_progress_start "Disabling $active"
    systemctl disable --now ${active} >> ${log} 2>&1
    echo_progress_done
  else
    exit 1
  fi
fi

if [[ $codename =~ ("xenial"|"stretch") ]]; then
    pyenv_install
    pyenv_install_version 3.7.7
    pyenv_create_venv 3.7.7 /opt/.venv/sickchill
else
    LIST='git python3-dev python3-venv python3-pip'
    apt_install $LIST
    echo_progress_start "Installing venve for sickchill"
    python3 -m venv /opt/.venv/sickchill >> ${log} 2>&1
    echo_progress_done
fi

chown -R ${user}: /opt/.venv/sickchill
echo_progress_start "Cloning SickChill"
git clone https://github.com/SickChill/SickChill.git  /opt/sickchill >> ${log} 2>&1
chown -R $user: /opt/sickchill
echo_progress_done

echo_progress_start "Installing requirements.txt with pip"
sudo -u ${user} bash -c "/opt/.venv/sickchill/bin/pip3 install -r /opt/sickchill/requirements.txt" >> $log 2>&1
echo_progress_done

install_rar

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/sickchill.service <<SCSD
[Unit]
Description=SickChill
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/opt/.venv/sickchill/bin/python3 /opt/sickchill/SickChill.py -q --daemon --nolaunch --datadir=/opt/sickchill


[Install]
WantedBy=multi-user.target
SCSD

systemctl enable -q --now sickchill 2>&1  | tee -a $log
echo_progress_done "Sickchill started"

if [[ -f /install/.nginx.lock ]]; then
  echo_progress_start "Configuring nginx"
  bash /usr/local/bin/swizzin/nginx/sickchill.sh
  systemctl reload nginx
  echo_progress_done
fi

echo_success
touch /install/.sickchill.lock
