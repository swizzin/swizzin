#!/bin/bash
# autobrr installer
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

app_reqs=("curl" "sqlite3")
apt_install "${app_reqs[@]}"

users=($(_get_user_list))

if [[ -n $1 ]]; then
    user=$1
    _autobrr_user_config ${user}
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/autobrr.sh
        systemctl reload nginx
        echo_progress_done
    fi
    exit 0
fi

_install_autobrr() {

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

    if ! curl "$latest" -L -o "/tmp/autobrr.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi
    echo_progress_done "Archive downloaded"

    echo_progress_start "Extracting archive"

    # the archive contains both autobrr and autobrrctl to easily setup the user
    tar xfv "/tmp/autobrr.tar.gz" --directory /usr/bin/ >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/autobrr.tar.gz"
    echo_progress_done "Archive extracted"
}

_autobrr_user_config() {
    echo_progress_start "Configuring autobrr"

    # get random available port
    port=$(port 10000 12000)

    # generate a sessionSecret
    sessionSecret="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"

    if [ ! -d "/home/$user/.config/autobrr/" ]; then
        mkdir -p "/home/$user/.config/autobrr/"
    fi
    chown -R "$user": "/home/$user/.config/autobrr"

    cat > "/home/$user/.config/autobrr/config.toml" << CFG
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
port = ${port}
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

# Session secret
#
sessionSecret = "${sessionSecret}"
CFG

    chown -R "$user": "/home/$user/.config/autobrr"

    echo_progress_done

}

_autobrr_add_user() {
    # use autobrrctl to add user into database
    echo_progress_start "Add user"

    for user in "${users[@]}"; do
        echo_log_only "Adding user $user"
        pass=$(_get_user_password "$user")

        # the password needs to be created with argon2 so we use autobrrctl to create the user
        # using sqlite3 directly was not an option
        echo -n "$pass" | autobrrctl --config "/home/$user/.config/autobrr" create-user "$user"
    done
}

_systemd_autobrr() {
    if [[ ! -f /etc/systemd/system/autobrr@.service ]]; then
        type=simple
        if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
            type=exec
        fi

        echo_progress_start "Installing Systemd service"
        cat > /etc/systemd/system/autobrr@.service << EOF
[Unit]
Description=autobrr service for %i
After=syslog.target network.target

[Service]
Type=$type
User=%i
Group=%i
ExecStart=/usr/bin/autobrr --config=/home/%i/.config/autobrr/
# TimeoutStopSec=20
# KillMode=process
# Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    fi
}

_systemd_autobrr_enable_for_user() {
    for user in ${users[@]}; do
        echo_progress_start "Enabling autobrr for $user"
        _autobrr_user_config ${user}
        systemctl enable -q --now autobrr@${user} 2>&1 | tee -a $log
        echo_progress_done "Started autobrr for $user"
        sleep 3
    done
}

_nginx_autobrr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/autobrr.sh
        systemctl reload nginx >> $log 2>&1
        echo_progress_done "Nginx configured"
    fi
}

_install_autobrr

_systemd_autobrr
_systemd_autobrr_enable_for_user
_autobrr_add_user

_nginx_autobrr

touch "/install/.autobrr.lock"
echo_success "autobrr installed"
