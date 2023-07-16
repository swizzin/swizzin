#!/bin/bash
# autobrr installer
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/autobrr
. /etc/swizzin/sources/functions/autobrr

_systemd() {
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

[Install]
WantedBy=multi-user.target
EOF
    echo_progress_done "Service installed"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for autobrr"
        bash /etc/swizzin/scripts/nginx/autobrr.sh
        systemctl reload nginx >> $log 2>&1
        echo_progress_done "Nginx configured for autobrr"
    fi
}

# This method will perform all logic related to user accounts. For each user when installed, and for only one user when via box adduser
_add_users() {
    for user in "${users[@]}"; do
        echo_progress_start "Enabling autobrr for $user"

        # get random available port
        port=$(port 10000 12000)

        # generate a sessionSecret
        sessionSecret="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"

        mkdir -p "/home/$user/.config/autobrr/"
        chown "$user": "/home/$user/.config"
        chown -R "$user": "/home/$user/.config/autobrr"

        cat > "/home/$user/.config/autobrr/config.toml" << CFG
# config.toml
# Hostname / IP
#
# Default: "localhost"
#
host = "0.0.0.0"
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
logPath = "/home/${user}/.config/autobrr/logs/autobrr.log"
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

        _get_user_password "$user" | /usr/bin/autobrrctl --config "/home/$user/.config/autobrr" create-user "$user" || {
            echo_error "Failed to execute autobrrctl command"
            exit 1
        }

        chown -R "$user": "/home/$user/.config/autobrr"

        systemctl enable -q --now autobrr@"${user}" 2>&1 | tee -a $log
        echo_progress_done "Started autobrr for $user"

    done
}

##############################

# If `box adduser` is running, only do _add_users and then exit. Otherwise, run the whole installer
if [ -n "$1" ]; then
    users=("$1")
    _add_users
    _nginx
    exit 0
fi

autobrr_download_latest
_systemd

readarray -t users < <(_get_user_list)
_add_users
_nginx

touch "/install/.autobrr.lock"
echo_success "autobrr installed"
