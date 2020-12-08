#!/bin/bash

if [[ -f /install/.nzbhydra.lock ]]; then
    if [[ -f /etc/systemd/system/nzbhydra@.service ]]; then
        user=$(cut -d: -f1 < /root/.master.info)
        codename=$(lsb_release -cs)
        active=$(systemctl is-active nzbhydra@${user})
        . /etc/swizzin/sources/functions/pyenv
        if [[ $active == "active" ]]; then
            systemctl disable -q --now nzbhydra@${user} >> ${log} 2>&1
        fi

        if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            LIST='git python2.7-dev virtualenv python-virtualenv'
        else
            LIST='git python2.7-dev'
        fi

        apt_install $LIST

        if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            python_getpip
        fi

        python2_venv ${user} nzbhydra

        if [[ ! -d /home/${user}/.config ]]; then
            mkdir /home/${user}/.config
            chown ${user}: /home/${user}/.config
        fi

        mv /home/${user}/.nzbhydra /home/${user}/.config/nzbhydra
        mv /home/${user}/nzbhydra /opt
        cat > /etc/systemd/system/nzbhydra.service << NZBH
[Unit]
Description=NZBHydra
Documentation=https://github.com/theotherp/nzbhydra
After=syslog.target network.target

[Service]
Type=forking
KillMode=control-group
User=${user}
Group=${user}
ExecStart=/opt/.venv/nzbhydra/bin/python2 /opt/nzbhydra/nzbhydra.py --daemon --nobrowser --pidfile /opt/nzbhydra/nzbhydra.pid --logfile /home/${user}/.config/nzbhydra/nzbhydra.log --database /home/${user}/.config/nzbhydra/nzbhydra.db --config /home/${user}/.config/nzbhydra/settings.cfg
GuessMainPID=no
ExecStop=-/bin/kill -HUP
Restart=on-failure

[Install]
WantedBy=multi-user.target
NZBH

        systemctl daemon-reload
        rm /etc/systemd/system/nzbhydra@.service
        if [[ $active == "active" ]]; then
            systemctl enable -q --now nzbhydra 2>&1 | tee -a $log
        fi
    fi
fi
