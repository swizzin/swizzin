#!/bin/bash

if [[ -f /install/.medusa.lock ]]; then
    if [[ -f /etc/systemd/system/medusa@.service ]]; then
        log=/root/logs/swizzin.log
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active medusa@${user})

        if [[ $isactive == "active" ]]; then
            systemctl disable --now medusa@${user}
        fi
        if [[ ! -d /home/${user}/.venv ]]; then
            mkdir -p /home/${user}/.venv
            chown ${user}: /home/${user}/.venv
        fi
        
        apt-get -y -q update >> $log 2>&1
        apt-get -y -q install git-core openssl libssl-dev python3 python3-venv >> $log 2>&1
        python3 -m venv /home/${user}/.venv/medusa
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
ExecStart=/home/${user}/.venv/medusa/bin/python3 /home/${user}/medusa/SickBeard.py -q --daemon --nolaunch --datadir=/home/${user}/medusa
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
MSD

        systemctl daemon-reload
        rm -rf /etc/systemd/system/medusa@.service
        if [[ $isactive == "active" ]]; then
            systemctl enable --now medusa >> ${log} 2>&1
        fi
    fi
fi