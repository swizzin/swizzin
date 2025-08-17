#!/bin/bash
# Whisparr Installer
# Refactored from existing files by Bakerboy448, FlyingSausages and others
# By B, 2022 for swizzin
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

app_name="whisparr"
if [ -z "$WHISPARR_OWNER" ]; then
    if ! WHISPARR_OWNER="$(swizdb get "$app_name/owner")"; then
        WHISPARR_OWNER="$(_get_master_username)"
        echo_info "Setting ${app_name^} owner = $WHISPARR_OWNER"
        swizdb set "$app_name/owner" "$WHISPARR_OWNER"
    fi
else
    echo_info "Setting ${app_name^} owner = $WHISPARR_OWNER"
    swizdb set "$app_name/owner" "$WHISPARR_OWNER"
fi
user="$WHISPARR_OWNER"
swiz_configdir="/home/$user/.config"
app_configdir="$swiz_configdir/${app_name^}"
app_group="$user"
app_port="6900"
app_reqs=("curl" "sqlite3")
app_servicefile="$app_name.service"
app_dir="/opt/${app_name^}"
app_binary="${app_name^}"
#Remove any dashes in appname per FS
app_lockname="${app_name//-/}"
app_branch="nightly"
#ToDo: Update branch

if [ ! -d "$swiz_configdir" ]; then
    mkdir -p "$swiz_configdir"
fi
chown "$user":"$user" "$swiz_configdir"

_install_whisparr() {
    if [ ! -d "$app_configdir" ]; then
        mkdir -p "$app_configdir"
    fi
    chown -R "$user":"$user" "$app_configdir"

    apt_install "${app_reqs[@]}"

    echo_progress_start "Downloading release archive"

    urlbase="https://$app_name.servarr.com/v1/update/$app_branch/updatefile?os=linux&runtime=netcore"
    case "$(_os_arch)" in
        "amd64") dlurl="${urlbase}&arch=x64" ;;
        "armhf") dlurl="${urlbase}&arch=arm" ;;
        "arm64") dlurl="${urlbase}&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o "/tmp/$app_name.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"
    tar xfv "/tmp/$app_name.tar.gz" --directory /opt/ >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/$app_name.tar.gz"
    chown -R "${user}": "$app_dir"
    echo_progress_done "Archive extracted"
}
_systemd_whisparr() {

    echo_progress_start "Installing Systemd service"
    cat > "/etc/systemd/system/$app_servicefile" << EOF
[Unit]
Description=${app_name^} Daemon
After=syslog.target network.target
[Service]
# Change the user and group variables here.
User=${user}
Group=${app_group}
Type=simple
# Change the path to ${app_name^} here if it is in a different location for you.
ExecStart=$app_dir/$app_binary -nobrowser -data=$app_configdir
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

    systemctl -q daemon-reload
    systemctl enable --now -q "$app_servicefile"
    sleep 1
    echo_progress_done "${app_name^} service installed and enabled"
}

_nginx_whisparr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/"$app_name".sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "$app_name will run on port $app_port"
    fi
}

_install_whisparr
_systemd_whisparr
_nginx_whisparr

touch "/install/.$app_lockname.lock"
echo_success "${app_name^} installed"
