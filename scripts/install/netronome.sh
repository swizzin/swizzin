#!/bin/bash
# netronome installer
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/netronome
. /etc/swizzin/sources/functions/netronome

_systemd() {
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        type=exec
    fi

    echo_progress_start "Installing Systemd service"
    cat > /etc/systemd/system/netronome@.service << EOF
[Unit]
Description=netronome service for %i
After=syslog.target network.target

[Service]
Type=$type
User=%i
Group=%i
ExecStart=/usr/bin/netronome --config=/home/%i/.config/netronome/

[Install]
WantedBy=multi-user.target
EOF
    echo_progress_done "Service installed"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for netronome"
        bash /etc/swizzin/scripts/nginx/netronome.sh
        systemctl reload nginx >> $log 2>&1
        echo_progress_done "Nginx configured for netronome"
    fi
}

# This method will perform all logic related to user accounts. For each user when installed, and for only one user when via box adduser
_add_users() {
    for user in "${users[@]}"; do
        echo_progress_start "Enabling netronome for $user"

        # get random available port
        port=$(port 10000 12000)

        # generate a sessionSecret
        sessionSecret="$(head /dev/urandom | xxd -p -l 32)"

        mkdir -p "/home/$user/.config/netronome/"
        chown "$user": "/home/$user/.config"
        chown -R "$user": "/home/$user/.config/netronome"

        cat > "/home/$user/.config/netronome/config.toml" << CFG
# Netronome Configuration

[database]
type = "sqlite"
path = "netronome.db"

[server]
host = "0.0.0.0"
port = ${port}

[logging]
level = "debug"  # trace, debug, info, warn, error, fatal, panic

[speedtest]
timeout = 30

[speedtest.iperf]
test_duration = 10
parallel_conns = 4

[session]
session_secret = "${sessionSecret}"
CFG

        _get_user_password "$user" | /usr/bin/netronome --config "/home/$user/.config/netronome/config.toml" create-user "$user" || {
            echo_error "Failed to execute netronome command"
            exit 1
        }

        chown -R "$user": "/home/$user/.config/netronome"

        systemctl enable -q --now netronome@"${user}" 2>&1 | tee -a $log
        echo_progress_done "Started netronome for $user"

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

netronome_download_latest
_systemd

readarray -t users < <(_get_user_list)
_add_users
_nginx

touch "/install/.netronome.lock"
echo_success "netronome installed"
