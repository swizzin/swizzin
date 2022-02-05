#!/bin/bash

if [[ -f /install/.sickgear.lock ]]; then
    if [[ -f /etc/systemd/system/sickgear@.service ]]; then
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active sickgear@${user})
        codename=$(lsb_release -cs)

        if [[ $isactive == "active" ]]; then
            systemctl disable -q --now sickgear@${user}
        fi
        if [[ ! -d /opt/.venv ]]; then
            mkdir -p /opt/.venv
            chown ${user}: /opt/.venv
        fi

        if [[ ! $codename =~ ("stretch"|"bionic") ]]; then
            apt_install git-core openssl libssl-dev python3 python3-pip python3-dev python3-venv
            python3 -m venv /opt/.venv/sickgear
        else
            apt_install git-core openssl libssl-dev
            . /etc/swizzin/sources/functions/pyenv
            pyenv_install
            pyenv_install_version 3.7.7
            pyenv_create_venv 3.7.7 /opt/.venv/sickgear
        fi

        /opt/.venv/sickgear/bin/pip3 install lxml regex scandir soupsieve cheetah3 >> $log 2>&1
        chown -R ${user}: /opt/.venv/sickgear

        mv /home/${user}/.sickgear /opt/sickgear

        cat > /etc/systemd/system/sickgear.service << MSD
[Unit]
Description=SickGear
After=syslog.target network.target

[Service]
User=${user}
Group=${user}
ExecStart=/opt/.venv/sickgear/bin/python /opt/sickgear/sickgear.py -q --nolaunch --datadir=/opt/sickgear


[Install]
WantedBy=multi-user.target
MSD

        systemctl daemon-reload
        rm /etc/systemd/system/sickchill@.service
        if [[ $isactive == "active" ]]; then
            systemctl enable -q --now sickgear 2>&1 | tee -a $log
        fi
    fi
fi
