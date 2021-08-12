#!/bin/bash
# Installer for autobrr
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

app_name="autobrr"
if [ -z "$AUTOBRR_OWNER" ]; then
    if ! AUTOBRR_OWNER="$(swizdb get "$app_name/owner")"; then
        AUTOBRR_OWNER="$(_get_master_username)"
        echo_info "Setting ${app_name} owner = $AUTOBRR_OWNER"
        swizdb set "$app_name/owner" "$AUTOBRR_OWNER"
    fi
else
    echo_info "Setting ${app_name} owner = $AUTOBRR_OWNER"
    swizdb set "$app_name/owner" "$AUTOBRR_OWNER"
fi
user="$AUTOBRR_OWNER"
swiz_configdir="/home/$user/.config"
app_configdir="$swiz_configdir/${app_name}"
app_group="$user"
app_port="9090"
app_reqs=("curl")
app_servicefile="$app_name.service"
app_dir="/opt/${app_name}"
app_binary="${app_name}"
#Remove any dashes in appname per FS
app_lockname="${app_name//-/}"

if [ ! -d "$swiz_configdir" ]; then
    mkdir -p "$swiz_configdir"
fi
chown "$user":"$user" "$swiz_configdir"

_install_autobrr() {
    if [ ! -d "$app_configdir" ]; then
        mkdir -p "$app_configdir"
    fi
    chown -R "$user":"$user" "$app_configdir"

    apt_install "${app_reqs[@]}"

    echo_progress_start "Downloading release archive"

    case "$(_os_arch)" in
        "amd64") arch='x86_64' ;;
        "arm64") arch="arm64" ;;
        "armhf") arch="armv6" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    latest=$(curl -sL https://api.github.com/repos/autobrr/autobrr/releases/latest | grep "linux_$arch" | grep browser_download_url | cut -d \" -f4) || {
        echo_error "Failed to query GitHub for latest version"
        exit 1
    }

    if ! curl "$latest" -L -o "/tmp/$app_name.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"

    mkdir -p "$app_dir"

    tar xfv "/tmp/$app_name.tar.gz" --directory /opt/$app_name >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/$app_name.tar.gz"
    chown -R "${user}": "$app_dir"
    echo_progress_done "Archive extracted"

    echo_progress_start "Configuring autobrr"
    cat > "$app_configdir/config.toml" << CFG
# config.toml
# Hostname / IP
#
# Default: "localhost"
#
host = "127.0.0.1"
# Port
#
# Default: 8989
#
port = 9090
# Base url
# Set custom baseUrl eg /autobrr/ to serve in subdirectory.
# Not needed for subdomain, or by accessing with the :port directly.
#
# Optional
#
baseUrl = "/autobrr/"
# autobrr logs file
# If not defined, logs to stdout
#
# Optional
#
#logPath = "log/autobrr.log"
# Log level
#
# Default: "DEBUG"
#
# Options: "ERROR", "DEBUG", "INFO", "WARN"
#
logLevel = "DEBUG"
CFG
    echo_progress_done

}

_systemd_autobrr() {

    echo_progress_start "Installing Systemd service"
    cat > "/etc/systemd/system/$app_servicefile" << EOF
[Unit]
Description=${app_name}
After=syslog.target network.target
[Service]
# Change the user and group variables here.
User=${user}
Group=${app_group}
Type=simple
# Change the path to ${app_name} here if it is in a different location for you.
ExecStart=$app_dir/$app_binary --config=$app_configdir
TimeoutStopSec=20
KillMode=process
Restart=on-failure
# These lines optionally isolate (sandbox) ${app_name} from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=$app_dir
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true
[Install]
WantedBy=multi-user.target
EOF

    systemctl -q daemon-reload
    systemctl enable --now -q "$app_servicefile"
    sleep 1
    echo_progress_done "${app_name} service installed and enabled"

    # In theory there should be no updating needed, so let's generalize this
    echo_progress_start "${app_name} is loading..."
    if ! timeout 30 bash -c -- "while ! curl -sIL http://127.0.0.1:$app_port >> \"$log\" 2>&1; do sleep 2; done"; then
        echo_error "The ${app_name} web server has taken longer than 30 seconds to start."
        exit 1
    fi
    echo_progress_done "Loading finished"

}

_nginx_autobrr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/"$app_name".sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "$app_name will run on port $app_port"
    fi
}
_install_autobrr
_systemd_autobrr
_nginx_autobrr

touch "/install/.$app_lockname.lock"
echo_success "${app_name} installed"
