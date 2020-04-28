#!/bin/bash


if [[ -f /install/.couchpotato.lock ]]; then
    if [[ -f /etc/systemd/system/couchpotato@.service ]]; then
        codename=$(lsb_release -cs)
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active couchpotato@${user})
        log="/root/logs/swizzin.log"
        . /etc/swizzin/sources/functions/pyenv
        systemctl disable --now couchpotato@${user} >> ${log} 2>&1
        if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            LIST='git python2-dev python-virtualenv virtualenv'
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
        python2_home_venv ${user} couchpotato
        /home/${user}/.venv/couchpotato/bin/pip install pyOpenSSL lxml >>"${log}" 2>&1
        chown -R ${user}: /home/${user}/.venv/couchpotato

        cd /home/${user}
        mv .couchpotato couchpotato
        cat > /etc/systemd/system/couchpotato.service <<CPSD
[Unit]
Description=CouchPotato
After=syslog.target network.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/couchpotato/bin/python2 /home/${user}/couchpotato/CouchPotato.py --daemon --data_dir /home/${user}/.config/couchpotato
GuessMainPID=no

[Install]
WantedBy=multi-user.target
CPSD
        mkdir -p /home/${user}/.config/couchpotato
        chown ${user}: /home/${user}/.config
        chown ${user}: /home/${user}/.config/couchpotato
        mv /home/${user}/couchpotato/{cache,custom_plugins,database,db_backup,logs,settings.conf} /home/${user}/.config/couchpotato
        rm /etc/systemd/system/couchpotato@.service
        systemctl daemon-reload

        if [[ $isactive == "active" ]]; then
            systemctl enable --now couchpotato >> ${log} 2>&1
        fi
    fi
fi

