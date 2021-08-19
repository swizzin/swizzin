#!/bin/bash
# autobrr installer
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/autobrr
. /etc/swizzin/sources/functions/autobrr

# install needed tools
apt_install curl

users=($(_get_user_list))

_autobrr_user_config() {
    echo_progress_start "Configuring autobrr"

    # get random available port
    port=$(port 10000 12000)

    # generate a sessionSecret
    sessionSecret="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"

    if [ ! -d "/home/$user/.config/autobrr/" ]; then
        mkdir -p "/home/$user/.config/autobrr/"
        chown -R "$user": "/home/$user/.config"
    fi

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

    chown -R "$user": "/home/$user/.config/autobrr"

    echo_progress_done

}

if [[ -n $1 ]]; then
    user=$1
    _autobrr_user_config ${user}
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/autobrr.sh
        systemctl reload nginx
        echo_progress_done
    fi
    systemctl enable -q --now autobrr@${user} 2>&1 | tee -a $log

    exit 0
fi

_autobrr_create_users() {
    # use autobrrctl to add user into database
    echo_progress_start "Add user"

    for user in "${users[@]}"; do
        echo_log_only "Adding user $user"

        # the password needs to be created with argon2 so we use autobrrctl to create the user
        # using sqlite3 directly was not an option
        _get_user_password "$user" | /usr/bin/autobrrctl --config "/home/$user/.config/autobrr" create-user "$user"
    done
}

_systemd_autobrr() {
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

autobrr_download_latest

_systemd_autobrr
_autobrr_create_users

_nginx_autobrr

touch "/install/.autobrr.lock"
echo_success "autobrr installed"
