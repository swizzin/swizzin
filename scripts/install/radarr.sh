#!/bin/bash
# *Arr Installer for Radarr
# Refactored from existing files by FlyingSausages and others
# Bakerboy448 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

#ToDo this should all be wrote to SwizDB; Need to ensure swizdb is updated for existing installs
app_name="radarr"
app_dir="/opt/${app_name^}"
app_binary="${app_name^}"
app_port="7878"
app_reqs=("curl" "mediainfo" "sqlite3")
app_branch="master"

if [ -z "$RADARR_OWNER" ]; then
    if ! RADARR_OWNER="$(swizdb get $app_name/owner)"; then
        RADARR_OWNER=$(_get_master_username)
        echo_info "Setting ${app_name^} owner = $RADARR_OWNER"
        swizdb set "$app_name/owner" "$RADARR_OWNER"
    fi
else
    echo_info "Setting ${app_name^} owner = $RADARR_OWNER"
    swizdb set "$app_name/owner" "$RADARR_OWNER"
fi

_install_radarr() {
    app_user="$RADARR_OWNER"
    appconfigdir="/home/$app_user/.config/${app_name^}"
    apt_install "${app_reqs[@]}"

    if [ ! -d "$appconfigdir" ]; then
        mkdir -p "$appconfigdir"
    fi
    chown -R "$app_user":"$app_user" "$appconfigdir"

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
    chown -R "${app_user}": "$app_dir"
    echo_progress_done "Archive extracted"

    echo_progress_start "Installing Systemd service"
    cat > "/etc/systemd/system/$app_name.service" << EOF
[Unit]
Description=${app_name^} Daemon
After=syslog.target network.target

[Service]
# Change the app_user and group variables here.
User=${app_user}
Group=${app_user}

Type=simple

# Change the path to ${app_name^} here if it is in a different location for you.
ExecStart=$app_dir/$app_binary -nobrowser -data=$appconfigdir
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) ${app_name^} from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=$app_dir /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-app_user.target
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

_nginx_radarr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        sleep 10
        bash /usr/local/bin/swizzin/nginx/radarr.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "${app_name^} will run on port $app_port"
    fi
}

_install_radarr
_nginx_radarr

if [[ -f /install/.ombi.lock ]]; then
    echo_info "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.tautulli.lock ]]; then
    echo_info "Please adjust your Tautulli setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
    echo_info "Please adjust your Bazarr setup accordingly"
fi

touch "/install/.$app_name.lock"
echo_success "${app_name^} installed"
