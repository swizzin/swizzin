#!/bin/bash
#
# Mylar Updater
# Author: Brett
# Copyright (C) 2022 Swizzin

if [[ -f /install/.mylar.lock ]]; then
    if ! grep "forking" /etc/systemd/system/mylar.service; then
        mylar_owner=$(swizdb get)
        cat > /etc/systemd/system/mylar.service << EOS
[Unit]
Description=Mylar service
After=network-online.target

[Service]
Type=forking
User=${mylar_owner}
ExecStart=/opt/.venv/mylar/bin/python3 /opt/mylar/Mylar.py --datadir /home/${mylar_owner}/.config/mylar/ -v --daemon  --nolaunch --quiet
WorkingDirectory=/opt/mylar
GuessMainPID=no
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
        systemctl daemon-reload
        systemctl try-restart mylar
    fi
fi
