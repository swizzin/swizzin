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
    echo_info "SickChill and Medusa and Sickgear cannot be active at the same time.\nDo you want to disable $active and continue with the installation?\nDon't worry, your install will remain at /opt/$active"
    if ask "Do you want to disable $active?" Y; then
        disable=yes
    fi
    if [[ $disable == "yes" ]]; then
        echo_progress_start "Disabling service"
        systemctl disable -q --now ${active}
        echo_progress_done
    else
        exit 1
    fi
fi

LIST='git python3-dev python3-venv python3-pip'
apt_install $LIST
echo_progress_start "Installing venv for sickchill"
python3 -m venv /opt/.venv/sickchill >> ${log} 2>&1
echo_progress_done

chown -R ${user}: /opt/.venv/sickchill
echo_progress_start "Cloning SickChill"
git clone https://github.com/SickChill/SickChill.git /opt/sickchill >> ${log} 2>&1
chown -R $user: /opt/sickchill
echo_progress_done

echo_progress_start "Installing requirements.txt with pip"
sudo -u ${user} bash -c "/opt/.venv/sickchill/bin/pip3 install -r /opt/sickchill/requirements.txt" >> $log 2>&1
echo_progress_done

install_rar

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/sickchill.service << SCSD
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

systemctl enable -q --now sickchill 2>&1 | tee -a $log
echo_progress_done "Sickchill started"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/sickchill.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "SickChill will run on port 8081"
fi

echo_success "SickChill installed"
touch /install/.sickchill.lock
