#!/bin/bash

if [[ -f /install/.nzbget.lock ]]; then
    if grep -q "ExecStart=/home/%I/nzbget/nzbget -D" /etc/systemd/system/nzbget@.service; then
        cat > /etc/systemd/system/nzbget@.service << NZBGD
[Unit]
Description=NZBGet Daemon
Documentation=http://nzbget.net/Documentation
After=network.target

[Service]
User=%I
Group=%I
Type=forking
ExecStart=/bin/sh -c "/home/%I/nzbget/nzbget -D"
ExecStop=/bin/sh -c "/home/%I/nzbget/nzbget -Q"
ExecReload=/bin/sh -c "/home/%I/nzbget/nzbget -O"
Restart=on-failure

[Install]
WantedBy=multi-user.target
NZBGD
    fi
    systemctl daemon-reload
fi
