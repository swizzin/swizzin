#!/bin/bash


if [[ -f /install/.couchpotato.lock ]]; then
    if [[ -f /etc/systemd/system/couchpotato@.service ]]; then
        codename=$(lsb_release -cs)
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active couchpotato@${user})
        log="/root/logs/swizzin.log"
        if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            LIST='git python2-dev virtualenv'
        else
            LIST='git python2-dev'
        fi
        apt-get -y -q update >> $log 2>&1
        for depend in $LIST; do
            apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
        done

        if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            . /etc/swizzin/sources/functions/pyenv
            python_getpip
            pip install -m virtualenv >>"${log}" 2>&1
        fi

        mkdir -p /home/${user}/.venv
        chown ${user}: /home/${user}/.venv
        python2 -m virtualenv /home/${user}/.venv/couchpotato >>"${log}" 2>&1
        /home/${user}/.venv/couchpotato/bin/pip install pyOpenSSL lxml >>"${log}" 2>&1
        chown -R ${user}: /home/${user}/.venv/couchpotato

        cd /home/${user}
        mv .couchpotato couchpotato
        cat > /etc/systemd/system/couchpotato.service <<CPSD
Description=CouchPotato
After=syslog.target network.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/couchpotato/bin/python2 /home/${user}/couchpotato/CouchPotato.py --daemon
GuessMainPID=no
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
CPSD
        systemctl daemon-reload

        if [[ $isactive == "active" ]]; then
            systemctl restart couchpotato
        fi
    fi
fi

