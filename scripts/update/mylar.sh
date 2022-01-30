#!/bin/bash
#
# Mylar updater
# Author: Brett
# Copyright (C) 2021 Swizzin

#shellcheck source=sources/functions/pyenv

if [[ -f /install/.mylar.lock ]]; then
    mylar_owner=$(swizdb get mylar/owner)
    echo_log_only "Fixing the mylar systemd service"
    if ! grep -q "forking" /etc/systemd/system/mylar.service; then
        cat > /etc/systemd/system/mylar.service << EOF
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
EOF
        systemctl daemon-reload --quiet
        systemctl try-restart mylar
    fi
fi
