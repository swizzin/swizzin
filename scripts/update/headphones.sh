#!/bin/bash

if [[ -f /install/.headphones.lock ]]; then
    user=$(cut -d: -f1 < /root/.master.info)
    if [[ -d /home/${user}/.headphones ]]; then
        active=$(systemctl is-active headphones)
        log=/root/logs/swizzin.log
        codename=$(lsb_release -cs)
        . /etc/swizzin/sources/functions/pyenv
        systemctl stop headphones
        if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            LIST='git python2-dev virtualenv python-virtualenv python-pip'
        else
            LIST='git python2-dev'
        fi
        apt-get -y -q update >> $log 2>&1

        for depend in $LIST; do
            apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
        done

        if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            python_getpip
        fi

        python2_home_venv ${user} headphones

        PIP='wheel cheetah asn1'
        /home/${user}/.venv/headphones/bin/pip install $PIP >>"${log}" 2>&1
        chown -R ${user}: /home/${user}/.venv/headphones

        mv /home/${user}/.headphones /home/${user}/headphones

        cat > /etc/systemd/system/headphones.service <<HEADSD
[Unit]
Description=Headphones
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/headphones/bin/python2 /home/${user}/headphones/Headphones.py -d --pidfile /run/${user}/headphones.pid --datadir /home/${user}/headphones --nolaunch --config /home/${user}/headphones/config.ini --port 8004
PIDFile=/run/${user}/headphones.pid


[Install]
WantedBy=multi-user.target
HEADSD
        systemctl daemon-reload
        sed -i 's/.headphones/headphones/g' /home/${user}/headphones/config.ini

        if [[ $active == "active" ]]; then
            systemctl enable --now headphones >> ${log} 2>&1
        fi
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q 'http_proxy = 1' /home/${user}/headphones/config.ini; then
            sed -i 's/http_proxy = 1/http_proxy = 0/g' /home/${user}/headphones/config.ini
            systemctl try-restart headphones
        fi
    fi
fi