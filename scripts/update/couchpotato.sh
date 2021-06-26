#!/bin/bash

if [[ -f /install/.couchpotato.lock ]]; then
    if [[ -f /etc/systemd/system/couchpotato@.service ]]; then
        codename=$(lsb_release -cs)
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active couchpotato@${user})
        . /etc/swizzin/sources/functions/pyenv
        systemctl disable -q --now couchpotato@${user} >> ${log} 2>&1
        if [[ $codename =~ ("stretch"|"buster"|"bionic") ]]; then
            LIST='git python2.7-dev python-virtualenv virtualenv'
        else
            LIST='git python2.7-dev'
        fi
        apt_install $LIST

        if [[ ! $codename =~ ("stretch"|"buster"|"bionic") ]]; then
            python_getpip
        fi
        python2_venv ${user} couchpotato
        /opt/.venv/couchpotato/bin/pip install pyOpenSSL lxml >> "${log}" 2>&1
        chown -R ${user}: /opt/.venv/couchpotato

        mv /home/${user}/.couchpotato /opt/couchpotato
        cat > /etc/systemd/system/couchpotato.service << CPSD
[Unit]
Description=CouchPotato
After=syslog.target network.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/opt/.venv/couchpotato/bin/python2 /opt/couchpotato/CouchPotato.py --daemon --data_dir /home/${user}/.config/couchpotato
GuessMainPID=no

[Install]
WantedBy=multi-user.target
CPSD
        mkdir -p /home/${user}/.config/couchpotato
        chown ${user}: /home/${user}/.config
        chown ${user}: /home/${user}/.config/couchpotato
        mv /opt/couchpotato/{cache,custom_plugins,database,db_backup,logs,settings.conf} /home/${user}/.config/couchpotato
        rm /etc/systemd/system/couchpotato@.service
        systemctl daemon-reload

        if [[ $isactive == "active" ]]; then
            systemctl enable -q --now couchpotato 2>&1 | tee -a $log
        fi
    fi
fi
