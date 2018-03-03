#!/bin/bash

if [[ -f /install/.lounge.sh ]]; then
    if grep -q "/usr/bin/lounge" /etc/systemd/system/lounge.service; then
        sed -i "s/ExecStart=\/usr\/bin\/lounge/ExecStart=\/usr\/bin\/thelounge/g" /etc/systemd/system/lounge.service
        systemctl daemon-reload
    fi
fi