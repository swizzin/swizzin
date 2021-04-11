#!/bin/bash
#shellcheck disable=SC2129
# Lidarr installer for swizzin
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

install() {
    user=$(_get_master_username)
    #shellcheck source=sources/functions/mono
    apt_install curl mediainfo sqlite3 chromaprint

    echo_progress_start "Downloading source files"
    case "$(_os_arch)" in
        "amd64") dlurl="https://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" ;;
        "armhf") dlurl="https://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm" ;;
        "arm64") dlurl="https://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o /tmp/lidarr.tar.gz >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Source downloaded"

    echo_progress_start "Extracting source"
    tar xfv /tmp/lidarr.tar.gz --directory /opt/ >> $log 2>&1
    rm -rf /tmp/lidarr.tar.gz
    chown -R "${user}": /opt/Lidarr
    echo_progress_done "Source extracted"
}

config() {

    echo_progress_start "Creating configuration and service files"
    if [[ ! -d /home/${user}/.config/Lidarr/ ]]; then mkdir -p "/home/${user}/.config/Lidarr/"; fi
    cat > "/home/${user}/.config/Lidarr/config.xml" << LID
<Config>
  <Port>8686</Port>
  <UrlBase>lidarr</UrlBase>
  <BindAddress>*</BindAddress>
  <EnableSsl>False</EnableSsl>
  <LogLevel>Info</LogLevel>
  <LaunchBrowser>False</LaunchBrowser>
</Config>
LID
    chown -R "${user}": "/home/${user}/.config"
}
systemd() {
    cat > /etc/systemd/system/lidarr.service << LID
[Unit]
Description=Lidarr
After=syslog.target network.target

[Service]
Type=simple
User=${user}
Group=${user}
Environment="TMPDIR=/home/${user}/.tmp"
ExecStart=/opt/Lidarr/Lidarr.exe -nobrowser
WorkingDirectory=/home/${user}/
Restart=on-failure

[Install]
WantedBy=multi-user.target
LID
    echo_progress_done "Services configured"
}

nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        sleep 10
        bash /usr/local/bin/swizzin/nginx/lidarr.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    fi
}

install
config
systemd
nginx

echo_progress_start "Enabling auto-start and executing Lidarr"
systemctl enable -q --now lidarr
echo_progress_done

echo_success "Lidarr installed"

touch /install/.lidarr.lock
