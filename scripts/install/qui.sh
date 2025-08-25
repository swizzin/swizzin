#!/bin/bash
# qui installer
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/qui
. /etc/swizzin/sources/functions/qui

_systemd() {
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        type=exec
    fi

    echo_progress_start "Installing Systemd service"
    cat > /etc/systemd/system/qui@.service << EOF
[Unit]
Description=qui service for %i
After=syslog.target network.target

[Service]
Type=$type
User=%i
Group=%i
ExecStart=/usr/bin/qui serve --config-dir=/home/%i/.config/qui/

[Install]
WantedBy=multi-user.target
EOF
    echo_progress_done "Service installed"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for qui"
        bash /etc/swizzin/scripts/nginx/qui.sh
        systemctl reload nginx >> $log 2>&1
        echo_progress_done "Nginx configured for qui"
    fi
}

# This method will perform all logic related to user accounts. For each user when installed, and for only one user when via box adduser
_add_users() {
    for user in "${users[@]}"; do
        echo_progress_start "Enabling qui for $user"

        # get random available port
        port=$(port 10300 10500)

        # generate a sessionSecret
        sessionSecret="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c32)"

        mkdir -p "/home/$user/.config/qui/"
        chown "$user": "/home/$user/.config"
        chown -R "$user": "/home/$user/.config/qui"

        cat > "/home/$user/.config/qui/config.toml" << CFG
# qui Configuration

[database]
type = "sqlite"
path = "qui.db"

[server]
host = "0.0.0.0"
port = ${port}
baseUrl = "/qui/"

[logging]
level = "info"  # ERROR, DEBUG, INFO, WARN, TRACE

[session]
sessionSecret = "${sessionSecret}"

[storage]
dataDir = "/home/$user/.config/qui/data"
CFG

        # Create data directory
        mkdir -p "/home/$user/.config/qui/data"

        # Create user account using qui CLI
        _get_user_password "$user" | /usr/bin/qui create-user --config-dir "/home/$user/.config/qui/" --username "$user" >> "$log" 2>&1 || {
            echo_error "Failed to execute qui command"
            exit 1
        }

        chown -R "$user": "/home/$user/.config/qui"

        systemctl enable -q --now qui@"${user}" 2>&1 | tee -a $log
        echo_progress_done "Started qui for $user"

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

# No specific dependencies needed for qui

qui_download_latest
_systemd

readarray -t users < <(_get_user_list)
_add_users
_nginx

touch "/install/.qui.lock"
echo_success "qui installed"
