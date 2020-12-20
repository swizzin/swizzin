#!/bin/bash
# *Arr Installer for Readarr
# Refactored from existing files by FlyingSausages and others
# Bakerboy448 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

app_name="readarr"
if [ -z "$READARR_OWNER" ]; then
    if ! READARR_OWNER="$(swizdb get $app_name/owner)"; then
        READARR_OWNER=$(_get_master_username)
        echo_info "Setting ${app_name^} owner = $READARR_OWNER"
        swizdb set "$app_name/owner" "$READARR_OWNER"
    fi
else
    echo_info "Setting ${app_name^} owner = $READARR_OWNER"
    swizdb set "$app_name/owner" "$READARR_OWNER"
fi

_install_readarr() {
    user="$READARR_OWNER"
    app_configdir="/home/$user/.config/${app_name^}"
    app_port="8787"
    app_reqs=("curl" "sqlite3")
    app_servicename="${app_name}"
    app_servicefile="$app_servicename".service
    app_dir="/opt/${app_name^}"
    app_binary="${app_name^}"
    app_lockname=$app_name
    app_group="$user"

    apt_install "${app_reqs[@]}"

    if [ ! -d "$app_configdir" ]; then
        mkdir -p "$app_configdir"
    fi
    chown -R "$user":"$app_group" "$app_configdir"

    echo_progress_start "Downloading release archive"

    #ToDo: Update branch
    urlbase="https://$app_name.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore"
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

# These lines optionally isolate (sandbox) ${app_name^} from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=$app_dir /path/to/media/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl -q daemon-reload
    systemctl enable --now -q "$app_name"
    sleep 1
    echo_progress_done "${app_name^} service installed and enabled"

    echo_progress_start "${app_name^} is installing an internal upgrade..."
    if ! timeout 30 bash -c -- "while ! curl -sIL http://127.0.0.1:$app_port >> \"$log\" 2>&1; do sleep 2; done"; then
        echo_error "The ${app_name^} web server has taken longer than 30 seconds to start."
        exit 1
    fi
    echo_progress_done "Internal upgrade finished"

}

_nginx_readarr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        sleep 10
        bash /usr/local/bin/swizzin/nginx/"$app_name".sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "$app_name will run on port $app_port"
    fi
}

_calibre_cs_readarr() {
    if [[ -f /install/.calibre.lock ]]; then
        if ! systemctl -q is-active $app_servicename; then
            if ask "Enable Calibre's Content Server for Readarr integration?" Y; then
                systemctl enable --now -q $app_servicename
            else
                return 0
            fi
        fi
        # We should set up the library here actually
        # We know the location, ports, the user and password, so I see no reason not to
    fi
}
_calibre_cs_readarr
_install_readarr
_nginx_readarr

touch "/install/.$app_lockname.lock"
echo_success "${app_name^} installed"
