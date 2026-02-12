#!/bin/bash
# shinkro installer
# 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/shinkro
. /etc/swizzin/sources/functions/shinkro

_systemd() {
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        type="exec"
    fi

    echo_progress_start "Installing Systemd service"
    cat > /etc/systemd/system/shinkro@.service << EOF
[Unit]
Description=shinkro service for %i
After=syslog.target network.target

[Service]
Type=$type
User=%i
Group=%i
ExecStart=/usr/bin/shinkro --config=/home/%i/.config/shinkro/

[Install]
WantedBy=multi-user.target
EOF
    echo_progress_done "Service installed"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for shinkro"
        bash /etc/swizzin/scripts/nginx/shinkro.sh
        systemctl reload nginx >> "$log" 2>&1
        echo_progress_done "Nginx configured for shinkro"
    fi
}

# This method will perform all logic related to user accounts. For each user when installed, and for only one user when via box adduser
_add_users() {
    for user in "${users[@]}"; do
        echo_progress_start "Enabling shinkro for $user"

        # get random available port
        port=$(port 10000 12000)

        # generate sessionSecret (32 character hex string)
        sessionSecret="$(head /dev/urandom | tr -dc A-Fa-f0-9 | head -c32)"

        # generate encryptionKey (64 character hex string)
        encryptionKey="$(head /dev/urandom | tr -dc A-Fa-f0-9 | head -c64)"

        mkdir -p "/home/$user/.config/shinkro/"
        chown "$user": "/home/$user/.config"
        chown -R "$user": "/home/$user/.config/shinkro"

        # Run shinkro setup to create config, DB, and admin user
        user_password="$(_get_user_password "$user")"
        /usr/bin/shinkro setup --config="/home/$user/.config/shinkro" --username="$user" --password="$user_password" >> "$log" 2>&1 || {
            echo_error "Failed to execute shinkro setup command"
            exit 1
        }

        # Update config with our custom values (port, secrets, etc.)
        cat > "/home/$user/.config/shinkro/config.toml" << CFG
Host = "0.0.0.0"
Port = ${port}
BaseUrl = "/shinkro/"
SessionSecret = "${sessionSecret}"
EncryptionKey = "${encryptionKey}"
LogLevel = "INFO"
LogPath = "/home/${user}/.config/shinkro/logs/shinkro.log"
LogMaxSize = 50
LogMaxBackups = 3
CheckForUpdates = true
CFG

        chown -R "$user": "/home/$user/.config/shinkro"

        systemctl enable -q --now shinkro@"${user}" 2>&1 | tee -a "$log"
        echo_progress_done "Started shinkro for $user"

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

shinkro_download_latest
_systemd

readarray -t users < <(_get_user_list)
_add_users
_nginx

touch "/install/.shinkro.lock"
echo_success "shinkro installed"
