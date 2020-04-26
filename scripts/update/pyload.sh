#!/bin/bash
#
# [swizzin :: Install pyLoad package]
#
# Swizzin by liara
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /install/.pyload.lock ]]; then
    if [[ -f /etc/systemd/system/pyload@.service ]]; then
        codename=$(lsb_release -cs)
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active pyload@${user})
        log="/root/logs/swizzin.log"
        if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
            LIST='tesseract-ocr gocr rhino python2-dev python-pip virtualenv libcurl4-openssl-dev sqlite3'
        else
            LIST='tesseract-ocr gocr rhino libcurl4-openssl-dev python2-dev sqlite3'
        fi
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
        python2 -m virtualenv /home/${user}/.venv/pyload >>"${log}" 2>&1

        PIP='wheel setuptools pycurl pycrypto tesseract pillow pyOpenSSL js2py feedparser beautifulsoup'
        /home/${user}/.venv/pyload/bin/pip install $PIP >>"${log}" 2>&1
        chown -R ${user}: /home/${user}/.venv/pyload

        cd /home/${user}
        mv .pyload pyload

        cat >/etc/systemd/system/pyload.service<<PYSD
[Unit]
Description=pyLoad
After=network.target

[Service]
Type=forking
KillMode=process
User=${user}
ExecStart=/home/${user}/.venv/pyload/bin/python2 /home/${user}/pyload/pyLoadCore.py --config=/home/${user}/pyload --pidfile=/home/${user}/.pyload.pid --daemon
PIDFile=/home/${user}/.pyload.pid
ExecStop=-/bin/kill -HUP
WorkingDirectory=/home/${user}/pyload

[Install]
WantedBy=multi-user.target

PYSD
        if [[ $isactive == "active" ]]; then
            systemctl restart pyload
        fi
    fi
fi

