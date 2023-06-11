#!/bin/bash
# Sick Gear Installer for swizzin
# Author: liara

user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ $(systemctl is-active medusa) == "active" ]]; then
    active=medusa
fi

if [[ $(systemctl is-active sickchill) == "active" ]]; then
    active=sickchill
fi

if [[ -n $active ]]; then
    echo_info "SickChill and Medusa and Sickgear cannot be active at the same time.\nDo you want to disable $active and continue with the installation?\nDon't worry, your install will remain at /opt/$active"
    if ask "Do you want to disable $active?" Y; then
        disable=yes
    fi
    if [[ $disable == "yes" ]]; then
        echo_progress_start "Disabling service"
        systemctl disable -q --now ${active} >> ${log} 2>&1
        echo_progress_done
    else
        exit 1
    fi
fi

mkdir -p /opt/.venv
chown ${user}: /opt/.venv

#minver 3.7.2
apt_install git-core openssl libssl-dev python3 python3-pip python3-dev python3-venv
echo_progress_start "Setting up venv for Sickgear"
python3 -m venv /opt/.venv/sickgear
echo_progress_done

echo_progress_start "Installing python requirements"
/opt/.venv/sickgear/bin/pip3 install lxml regex scandir soupsieve cheetah3 >> $log 2>&1
chown -R ${user}: /opt/.venv/sickgear
echo_progress_done

install_rar

echo_progress_start "Cloning Sickgear"
git clone https://github.com/SickGear/SickGear.git /opt/sickgear >> ${log} 2>&1
chown -R $user:$user /opt/sickgear
echo_progress_done

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/sickgear.service << SRS
[Unit]
Description=SickGear
After=syslog.target network.target

[Service]
User=${user}
Group=${user}
ExecStart=/opt/.venv/sickgear/bin/python /opt/sickgear/sickgear.py -q --nolaunch --datadir=/opt/sickgear


[Install]
WantedBy=multi-user.target
SRS
systemctl daemon-reload
systemctl enable -q --now sickgear 2>&1 | tee -a $log
sleep 5
# Restart because first start doesn't always generate the config.ini
systemctl restart sickgear
# Sleep to allow time for background processes
sleep 10
echo_progress_done "Started Sickgear"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/sickgear.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "SickGear will run on port 8081"
fi

echo_success "Sickgear installed"
touch /install/.sickgear.lock
