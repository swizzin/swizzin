#!/bin/bash
#
if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "Nginx is required for this application"
    exit
fi

. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/os

# Get the current version using a git ls-remote tag check
authelia_latestv="$(git ls-remote -t --refs https://github.com/authelia/authelia.git | awk '{sub("refs/tags/", "");sub("(.*)-alpha(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n1)"
# Create the download url using the version provided by authelia_latestv
case "$(_os_arch)" in
    "amd64") authelia_arch="amd64" ;;
    "armhf") authelia_arch="arm32v7" ;;
    "arm64") authelia_arch="arm64v8" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac
#
authelia_url="https://github.com/authelia/authelia/releases/download/${authelia_latestv}/authelia-linux-${authelia_arch}.tar.gz"
# Create the loction for the stored binary
mkdir -p "/opt/authelia"
# Download the binary
wget -qO "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" "${authelia_url}"
# Extract the specific file we need and nothing else.
tar -xf "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" -C "/opt/authelia/" "authelia-linux-${authelia_arch}"
# Symlink the extracted binary authelia-linux-${authelia_arch} to authelia
ln -fsn "/opt/authelia/authelia-linux-${authelia_arch}" "/opt/authelia/authelia"
# Remove the archive we no longer need
[[ -f "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" ]] && rm -f "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz"
# Make the configuration directory
mkdir -p /etc/authelia
# Get our external IP to set in the config.yml
ex_ip="$(ip -br a | sed -n 2p | awk '{ print $3 }' | cut -f1 -d'/')"
# Create a random secret for the config.yml
jwt_secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
insecure_secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
# Set our password for this example
username="$(_get_master_username)"
password="$(_get_user_password "${username}")"
# Hash our password using authelia hash-password to use in the users_database.yml
password_hash="$(/opt/authelia/authelia hash-password "${password}" | awk '{ print $3 }')"
# generate the /etc/authelia/config.yml
cat > "/etc/authelia/config.yml" << AUTHELIA_CONF
host: 127.0.0.1
port: 9091

server:
  read_buffer_size: 4096
  write_buffer_size: 4096
  path: "authelia"

theme: dark
log_level: debug
log_file_path: /var/log/authelia.log
jwt_secret: ${jwt_secret}
default_redirection_url: /

authentication_backend:
  disable_reset_password: false
  refresh_interval: 5m

  file:
    path: /etc/authelia/users_database.yml
    password:
      algorithm: argon2id
      iterations: 1
      key_length: 32
      salt_length: 16
      memory: 1024
      parallelism: 8

access_control:
  default_policy: deny
  rules:
    - domain: ${ex_ip}
      resources:
        - "^/(sonarr|radarr|jackett)/api.*$"
      policy: bypass

    - domain: ${ex_ip}
      policy: one_factor

session:
  name: authelia_session
  secret: ${insecure_secret}
  expiration: 1h
  inactivity: 5m
  remember_me_duration: 1M
  domain: ${ex_ip}

regulation:
  max_retries: 3
  find_time: 2m
  ban_time: 5m

storage:
  local:
    path: /etc/authelia/db.sqlite3

notifier:
  disable_startup_check: false

  filesystem:
    filename: /etc/authelia/notification.txt
AUTHELIA_CONF
# Generate the /etc/authelia/users_database.yml
cat > "/etc/authelia/users_database.yml" << AUTHELIA_USER
###############################################################
#                         Users Database                      #
###############################################################

# This file can be used if you do not have an LDAP set up.

users:
  username:
    displayname: "${username}"
    password: "${password_hash}"
    email: ${username}@swizzin.com
    groups:
      - admins
      - dev
AUTHELIA_USER
# Generate the /etc/authelia/authelia.service
cat > "/etc/systemd/system/authelia.service" << AUTHELIA_SERVICE
[Unit]
Description=Authelia
After=network-online.target

[Service]
Type=exec
user=www-data
ExecStart= /opt/authelia/authelia --config /etc/authelia/config.yml
Restart=always
RestartSec=2
TimeoutStopSec=5
SyslogIdentifier=authelia

[Install]
WantedBy=default.target
AUTHELIA_SERVICE

# Install nginx stuff
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash "/usr/local/bin/swizzin/nginx/authelia.sh"
    systemctl reload nginx
    echo_progress_done "Nginx config installed"
fi

useradd --system authelia &>> "$log"
chown -R authelia: /opt/authelia
chown -R authelia: /etc/authelia
# enable the service
systemctl enable -q --now authelia &>> "$log"
# Create the lock file
touch /install/.authelia.lock
# echo we are done
echo_success "Authelia Installed"
