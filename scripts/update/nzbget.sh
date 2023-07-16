#!/bin/bash

if [[ -f /install/.nzbget.lock ]]; then
    if grep -q "ExecStart=/home/%I/nzbget/nzbget -D" /etc/systemd/system/nzbget@.service; then
        echo_progress_start "Updating NZBGet systemd service file with forking"
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
        echo_progress_done
    fi
    # Do we always want to do this?
    systemctl daemon-reload
fi
