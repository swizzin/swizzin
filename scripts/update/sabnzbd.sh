#!/bin/bash

if [[ -f /install/.sabnzbd.lock ]]; then
    if [[ -f /etc/systemd/system/sabnzbd@.service ]]; then
        user=$(cut -d: -f1 < /root/.master.info)
        password=$(cut -d: -f2 < /root/.master.info)
        codename=$(lsb_release -cs)
        log=/root/logs/swizzin.log
        . /etc/swizzin/sources/functions/pyenv
        active=$(systemctl is-active sabnzbd@${user})
        systemctl disable --now sabnzbd@${user} >> ${log} 2>&1
        if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            LIST='par2 p7zip-full python2-dev python-pip virtualenv python-virtualenv libglib2.0-dev libdbus-1-dev'
        else
            LIST='par2 p7zip-full python2-dev libxml2-dev libxslt1-dev libglib2.0-dev'
        fi
        apt-get -y update >>"${log}" 2>&1
        for depend in $LIST; do
            apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
        done

        if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            python_getpip
        fi

        python2_home_venv ${user} sabnzbd

        PIP='wheel setuptools dbus-python configobj feedparser pgi lxml utidylib yenc cheetah pyOpenSSL'
        /home/${user}/.venv/sabnzbd/bin/pip install $PIP >>"${log}" 2>&1
        chown -R ${user}: /home/${user}/.venv/sabnzbd

        mkdir /home/${user}/.config > /dev/null 2>&1
        chown ${user}: /home/${user}/.config

        mv /home/${user}/.sabnzbd /home/${user}/.config/sabnzbd
        mv /home/${user}/SABnzbd /home/${user}/sabnzbd

        cat >/etc/systemd/system/sabnzbd.service<<SABSD
[Unit]
Description=Sabnzbd
Wants=network-online.target
After=network-online.target

[Service]
User=${user}
ExecStart=/home/${user}/.venv/sabnzbd/bin/python2 /home/${user}/sabnzbd/SABnzbd.py --config-file /home/${user}/.config/sabnzbd/sabnzbd.ini --logging 1
WorkingDirectory=/home/${user}/sabnzbd
Restart=on-failure

[Install]
WantedBy=multi-user.target

SABSD
        systemctl daemon-reload
        rm /etc/systemd/system/sabnzbd@.service

        if [[ $active == "active" ]]; then
            systemctl enable --now sabnzbd >> ${log} 2>&1
        fi
    fi
fi