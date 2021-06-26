#!/bin/bash

if [[ -f /install/.headphones.lock ]]; then
    user=$(cut -d: -f1 < /root/.master.info)
    if [[ -d /home/${user}/.headphones ]]; then
        active=$(systemctl is-active headphones)
        codename=$(lsb_release -cs)
        . /etc/swizzin/sources/functions/pyenv
        systemctl stop headphones
        if [[ $codename =~ ("stretch"|"buster"|"bionic") ]]; then
            LIST='git python2.7-dev virtualenv python-virtualenv python-pip'
        else
            LIST='git python2.7-dev'
        fi
        apt_install $LIST

        if [[ ! $codename =~ ("stretch"|"buster"|"bionic") ]]; then
            python_getpip
        fi

        python2_venv ${user} headphones

        PIP='wheel cheetah asn1'
        /opt/.venv/headphones/bin/pip install $PIP >> "${log}" 2>&1
        chown -R ${user}: /opt/.venv/headphones

        mv /home/${user}/.headphones /opt/headphones

        cat > /etc/systemd/system/headphones.service << HEADSD
[Unit]
Description=Headphones
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/opt/.venv/headphones/bin/python2 /opt/headphones/Headphones.py -d --pidfile /run/${user}/headphones.pid --datadir /opt/headphones --nolaunch --config /opt/headphones/config.ini --port 8004
PIDFile=/run/${user}/headphones.pid


[Install]
WantedBy=multi-user.target
HEADSD
        systemctl daemon-reload
        sed -i "s|/home/${user}/.headphones|/opt/headphones|g" /opt/headphones/config.ini

        if [[ $active == "active" ]]; then
            systemctl enable -q --now headphones 2>&1 | tee -a $log
        fi
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q 'http_proxy = 1' /opt/headphones/config.ini; then
            sed -i 's/http_proxy = 1/http_proxy = 0/g' /opt/headphones/config.ini
            systemctl try-restart headphones
        fi
    fi
fi
