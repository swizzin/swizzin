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
        echo_progress_start "Updating pyLoad to use pyenv"
        codename=$(lsb_release -cs)
        user=$(cut -d: -f1 < /root/.master.info)
        isactive=$(systemctl is-active pyload@${user})
        . /etc/swizzin/sources/functions/pyenv
        systemctl disable -q --now pyload@${user} >> ${log} 2>&1
        if [[ $codename = "buster" ]]; then
            LIST='tesseract-ocr gocr rhino python2.7-dev python-pip virtualenv python-virtualenv libcurl4-openssl-dev sqlite3'
        else
            LIST='tesseract-ocr gocr rhino libcurl4-openssl-dev python2.7-dev sqlite3'
        fi
        apt_install $LIST

        if [[ ! $codename = "buster" ]]; then
            python_getpip
        fi

        python2_venv ${user} pyload

        PIP='wheel setuptools pycurl pycrypto tesseract pillow pyOpenSSL js2py feedparser beautifulsoup'
        /opt/.venv/pyload/bin/pip install $PIP >> "${log}" 2>&1
        chown -R ${user}: /opt/.venv/pyload

        mv /home/${user}/.pyload /opt/pyload
        echo "/opt/pyload" > /opt/pyload/module/config/configdir

        cat > /etc/systemd/system/pyload.service << PYSD
[Unit]
Description=pyLoad
After=network.target

[Service]
User=${user}
ExecStart=/opt/.venv/pyload/bin/python2 /opt/pyload/pyLoadCore.py --config=/opt/pyload
WorkingDirectory=/opt/pyload

[Install]
WantedBy=multi-user.target
PYSD
        systemctl daemon-reload
        rm /etc/systemd/system/pyload@.service
        if [[ $isactive == "active" ]]; then
            systemctl enable -q --now pyload 2>&1 | tee -a $log
        fi
        echo_progress_done
    fi
fi
