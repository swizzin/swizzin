#!/usr/bin/env bash

if [ ! -f /install/.komga.install ]; then
    echo_error "You ain't got no komga, whacha doen"
    exit 1
fi

user=$(_get_master_username)
if [[ $(systemctl is-active komga) == "active" ]]; then
    wasactive=yes
    systemctl stop komga
fi
echo_progress_start "Downloading komga binary"
dlurl="$(curl -sNL https://api.github.com/repos/gotson/komga/releases/latest | jq -r '.assets[]?.browser_download_url | select(contains("jar"))')"
wget "$dlurl" -O /opt/komga/komga.jar || {
    echo_error "Download failed"
    exit 1
}
chown -R "$user":"$user" /opt/komga
echo_progress_done "Bin downloaded"

if [[ $wasactive == "yes" ]]; then
    systemctl start komga
fi
