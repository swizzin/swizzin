#!/bin/bash

if [[ -f /install/.medusa.lock ]]; then
    if [[ -f /etc/systemd/system/medusa@.service ]]; then
        log=/root/logs/swizzin.log
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active medusa@${user})
        codename=$(lsb_release -cs)

        if [[ $isactive == "active" ]]; then
            systemctl stop medusa@${user}
        fi
        if [[ ! -d /home/${user}/.venv ]]; then
            mkdir -p /home/${user}/.venv
            chown ${user}: /home/${user}/.venv
        fi

        if [[ ! $codename == "jessie" ]]; then
            apt-get -y -q install git-core openssl libssl-dev python3 python3-venv >> $log 2>&1
            python3 -m venv /home/${user}/.venv/medusa
        else
            apt-get -y -q install git-core openssl libssl-dev >> $log 2>&1
            . /etc/swizzin/sources/functions/pyenv
            pyenv_install
            pyenv_install_version 3.7.7
            pyenv_create_venv 3.7.7 /home/${user}/.venv/medusa
        fi
        chown -R ${user}: /home/${user}/.venv/medusa
        cd /home/${user}
        mv .medusa medusa

        cat > /etc/systemd/system/medusa.service <<MSD
[Unit]
Description=Medusa
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/medusa/bin/python /home/${user}/medusa/SickBeard.py -q --daemon --nolaunch --datadir=/home/${user}/medusa
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
MSD

        systemctl daemon-reload

        if [[ $isactive == "active" ]]; then
            systemctl restart medusa
        fi
    fi
fi