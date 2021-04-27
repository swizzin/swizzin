#!/bin/bash
# *Arr Installer for Radarr
# Refactored from existing files by FlyingSausages and others
# Bakerboy448 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

appname_lower="radarr"
appname_camel="Radarr"
appconfigdir="/home/$user/.config/$appname_camel"
appdir="/opt/$appname_camel"
appbinary="Radarr"
appport="7878"
appprereqs="curl mediainfo sqlite3"
appbranch="master"

if [ -z "$RADARR_OWNER" ]; then
    if ! RADARR_OWNER="$(swizdb get $appname_lower/owner)"; then
        RADARR_OWNER=$(_get_master_username)
        echo_info "Setting $appname_camel owner = $RADARR_OWNER"
        swizdb set "$appname_lower/owner" "$RADARR_OWNER"
    fi
else
    echo_info "Setting $appname_camel owner = $RADARR_OWNER"
    swizdb set "$appname_lower/owner" "$RADARR_OWNER"
fi

_install_radarr() {
    user="$RADARR_OWNER"

    apt_install "$appprereqs"

    if [ ! -d "$appconfigdir" ]; then
        mkdir -p "$appconfigdir"
    fi
    chown -R "$user":"$user" "$appconfigdir"

    echo_progress_start "Downloading release archive"

    urlbase="https://$appname_lower.servarr.com/v1/update/$appbranch/updatefile?os=linux&runtime=netcore"
    case "$(_os_arch)" in
        "amd64") dlurl="${urlbase}&arch=x64" ;;
        "armhf") dlurl="${urlbase}&arch=arm" ;;
        "arm64") dlurl="${urlbase}&arch=arm64" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    if ! curl "$dlurl" -L -o "/tmp/$appname_lower.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"
    tar xfv "/tmp/$appname_lower.tar.gz" --directory /opt/ >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/$appname_lower.tar.gz"
    chown -R "${user}": "$appdir"
    echo_progress_done "Archive extracted"

    echo_progress_start "Installing Systemd service"
    cat > "/etc/systemd/system/$appname_lower.service" << EOF
[Unit]
Description=$appname_camel Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=${user}
Group=${user}

Type=simple

# Change the path to $appname_camel here if it is in a different location for you.
ExecStart=$appdir/$appbinary -nobrowser -data=$appconfigdir
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) $appname_camel from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=$appdir /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl -q daemon-reload
    systemctl enable --now -q "$appname_lower"
    sleep 1
    echo_progress_done "$appname_camel service installed and enabled"

    echo_progress_start "$appname_camel is installing an internal upgrade..."
    if ! timeout 30 bash -c -- "while ! curl -sIL http://127.0.0.1:$appport >> \"$log\" 2>&1; do sleep 2; done"; then
        echo_error "The $appname_camel web server has taken longer than 30 seconds to start."
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
        echo_info "$appname_camel will run on port $appport"
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

touch "/install/.$appname_lower.lock"
echo_success "$appname_camel installed"
