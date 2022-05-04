#!/bin/bash
#
# [Quick Box :: Install rclone]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   DedSec | d2dyno
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/navidrome
. /etc/swizzin/sources/functions/rclone

_systemd() {
    type="simple"
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        type="exec"
    else
        type="simple"
    fi

    echo_progress_start "Installing Systemd service"
    cat >/etc/systemd/system/rclone@.service <<-EOF
[Unit]
Description=rclonemount
After=network.target

[Service]
Type=${type}
User=%i
Group=%i
ExecStartPre=-/bin/mkdir -p /home/%i/cloud/
ExecStart=/usr/bin/rclone mount gdrive: /home/%i/cloud/ \
  --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36' \
  --config /home/%i/.config/rclone/rclone.conf \
  --use-mmap \
  --dir-cache-time 1h \
  --timeout 30s \
  --umask 002 \
  --allow-other \
  --poll-interval=1h \
  --vfs-cache-mode writes \
  --vfs-read-chunk-size 1M \
  --vfs-read-chunk-size-limit 64M \
  --tpslimit 10
ExecStop=/bin/fusermount -u /home/%i/cloud
Restart=on-failure
RestartSec=30
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF
    echo_progress_done
}

_rclone_download_latest
_systemd

touch /install/.rclone.lock
echo_success "Rclone installed"
echo_info "Setup Rclone remote named \"gdrive\" And run sudo systemctl start rclone@username.service"
