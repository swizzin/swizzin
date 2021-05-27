#!/bin/bash

# Lidarr installer for swizzin
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

if [ -z "$LIDARR_OWNER" ]; then
    if ! LIDARR_OWNER="$(swizdb get lidarr/owner)"; then
        LIDARR_OWNER=$(_get_master_username)
        echo_info "Setting Lidarr owner = $LIDARR_OWNER"
        swizdb set "lidarr/owner" "$LIDARR_OWNER"
    fi
else
    echo_info "Setting Lidarr owner = $LIDARR_OWNER"
    swizdb set "lidarr/owner" "$LIDARR_OWNER"
fi

install() {
    user="$LIDARR_OWNER"
    apt_install mediainfo sqlite3 libchromaprint-tools

    echo_progress_start "Downloading release archive"

    urlbase="https://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore"
    case "$(_os_arch)" in
        "amd64") dlurl="${urlbase}&arch=x64" ;;
        "armhf") dlurl="${urlbase}&arch=arm" ;;
        "arm64") dlurl="${urlbase}&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o /tmp/lidarr.tar.gz >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"
    tar xfv /tmp/lidarr.tar.gz --directory /opt/ >> $log 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf /tmp/lidarr.tar.gz
    chown -R "${user}": /opt/Lidarr
    echo_progress_done "Archive extracted"
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
    mkdir -p /home/"${user}"/.tmp
    chown -R "${user}": "/home/${user}/.tmp"
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
ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=/home/${user}/.config/Lidarr/
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
    else
        echo_info "Lidarr will run on port 8686"
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
