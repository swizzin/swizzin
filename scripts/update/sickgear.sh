#!/bin/bash

if [[ -f /install/.sickgear.lock ]]; then
    if [[ -f /etc/systemd/system/sickgear@.service ]]; then
        log=/root/logs/swizzin.log
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active sickgear@${user})
        codename=$(lsb_release -cs)

        if [[ $isactive == "active" ]]; then
            systemctl stop sickgear@${user}
        fi
        if [[ ! -d /home/${user}/.venv ]]; then
            mkdir -p /home/${user}/.venv
            chown ${user}: /home/${user}/.venv
        fi
        apt-get -y -q update >> $log 2>&1

        if [[ ! $codename =~ ("xenial"|"stretch"|"bionic") ]]; then
            apt-get -y -q install git-core openssl libssl-dev python3 python3-pip python3-dev python3-venv >> $log 2>&1
            python3 -m venv /home/${user}/.venv/sickgear
        else
            apt-get -y -q install git-core openssl libssl-dev >> $log 2>&1
            . /etc/swizzin/sources/functions/pyenv
            pyenv_install
            pyenv_install_version 3.7.7
            pyenv_create_venv 3.7.7 /home/${user}/.venv/sickgear
        fi

        /home/${user}/.venv/sickgear/bin/pip3 install lxml regex scandir soupsieve cheetah3 >> $log 2>&1
        chown -R ${user}: /home/${user}/.venv/sickgear

        cd /home/${user}
        mv .sickgear sickgear

        cat > /etc/systemd/system/sickgear.service <<MSD
[Unit]
Description=SickGear
After=syslog.target network.target

[Service]
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/sickgear/bin/python /home/${user}/sickgear/sickgear.py -q --nolaunch --datadir=/home/${user}/sickgear


[Install]
WantedBy=multi-user.target
MSD

        systemctl daemon-reload

        if [[ $isactive == "active" ]]; then
            systemctl restart sickgear
        fi
    fi
fi