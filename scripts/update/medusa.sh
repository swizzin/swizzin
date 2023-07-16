#!/bin/bash

if [[ -f /install/.medusa.lock ]]; then
    if [[ -f /etc/systemd/system/medusa@.service ]]; then
        echo_progress_start "Moving medusa to a python venv"
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active medusa@${user})

        if [[ $isactive == "active" ]]; then
            systemctl disable -q --now medusa@${user}
        fi
        if [[ ! -d /opt/.venv ]]; then
            mkdir -p /opt/.venv
            chown ${user}: /opt/.venv
        fi

        apt_install git-core openssl libssl-dev python3 python3-venv
        python3 -m venv /opt/.venv/medusa
        chown -R ${user}: /opt/.venv/medusa
        mv /home/${user}/.medusa /opt/medusa

        cat > /etc/systemd/system/medusa.service << MSD
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

        systemctl daemon-reload
        rm -rf /etc/systemd/system/medusa@.service
        if [[ $isactive == "active" ]]; then
            systemctl enable -q --now medusa 2>&1 | tee -a $log
        fi
        echo_progress_done
    fi
fi
