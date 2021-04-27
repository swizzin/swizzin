#!/bin/bash
# *Arr Installer for Radarr
# Refactored from existing files by FlyingSausages and others
# Bakerboy448 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

#ToDo this should all be wrote to SwizDB; Need to ensure swizdb is updated for existing installs
appname="radarr"
appdir="/opt/{$appname^}"
appbinary="Radarr"
appport="7878"
app_reqs=("curl" "mediainfo" "sqlite3")
appbranch="master"

if [ -z "$RADARR_OWNER" ]; then
    if ! RADARR_OWNER="$(swizdb get $appname/owner)"; then
        RADARR_OWNER=$(_get_master_username)
        echo_info "Setting {$appname^} owner = $RADARR_OWNER"
        swizdb set "$appname/owner" "$RADARR_OWNER"
    fi
else
    echo_info "Setting {$appname^} owner = $RADARR_OWNER"
    swizdb set "$appname/owner" "$RADARR_OWNER"
fi

_install_radarr() {
    app_user="$RADARR_OWNER"
    appconfigdir="/home/$app_user/.config/{$appname^}"
    apt_install "${app_reqs[@]}"

    if [ ! -d "$appconfigdir" ]; then
        mkdir -p "$appconfigdir"
    fi
    chown -R "$app_user":"$app_user" "$appconfigdir"

    echo_progress_start "Downloading release archive"

    urlbase="https://$appname.servarr.com/v1/update/$appbranch/updatefile?os=linux&runtime=netcore"
    case "$(_os_arch)" in
        "amd64") dlurl="${urlbase}&arch=x64" ;;
        "armhf") dlurl="${urlbase}&arch=arm" ;;
        "arm64") dlurl="${urlbase}&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o "/tmp/$appname.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"
    tar xfv "/tmp/$appname.tar.gz" --directory /opt/ >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/$appname.tar.gz"
    chown -R "${app_user}": "$appdir"
    echo_progress_done "Archive extracted"

    echo_progress_start "Installing Systemd service"
    cat > "/etc/systemd/system/$appname.service" << EOF
[Unit]
Description={$appname^} Daemon
After=syslog.target network.target

[Service]
# Change the app_user and group variables here.
User=${app_user}
Group=${app_user}

Type=simple

# Change the path to {$appname^} here if it is in a different location for you.
ExecStart=$appdir/$appbinary -nobrowser -data=$appconfigdir
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) {$appname^} from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=$appdir /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-app_user.target
EOF

    systemctl -q daemon-reload
    systemctl enable --now -q "$appname"
    sleep 1
    echo_progress_done "{$appname^} service installed and enabled"

    echo_progress_start "{$appname^} is installing an internal upgrade..."
    if ! timeout 30 bash -c -- "while ! curl -sIL http://127.0.0.1:$appport >> \"$log\" 2>&1; do sleep 2; done"; then
        echo_error "The {$appname^} web server has taken longer than 30 seconds to start."
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
        echo_info "{$appname^} will run on port $appport"
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

touch "/install/.$appname.lock"
echo_success "{$appname^} installed"
