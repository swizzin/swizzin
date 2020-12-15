#!/bin/bash
#
if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "Nginx is required for this application"
    exit
fi

# Set the current version using a git ls-remote tag check
authelia_latestv="$(git ls-remote -t --sort=-v:refname --refs https://github.com/authelia/authelia.git | awk '{sub("refs/tags/", "");sub("(.*)-alpha(.*)", ""); print $2 }' | head -n1)"
# Create the download url using the version provided by authelia_latestv
authelia_url="https://github.com/authelia/authelia/releases/download/${authelia_latestv}/authelia-linux-amd64.tar.gz"
# Create the loction for the stored binary
mkdir -p "/opt/authelia"
# Download the binary
wget -qO "/opt/authelia/authelia-linux-amd64.tar.gz" "${authelia_url}"
# Extract the specific file we need and nothing else.
tar -xf "/opt/authelia/authelia-linux-amd64.tar.gz" -C "/opt/authelia/" 'authelia-linux-amd64'
# Symlink the extracted binary authelia-linux-amd64 to authelia
ln -fsn "/opt/authelia/authelia-linux-amd64" "/opt/authelia/authelia"
# Remove the archive we no longer need
[[ -f "/opt/authelia/authelia-linux-amd64.tar.gz" ]] && rm -f "/opt/authelia/authelia-linux-amd64.tar.gz"
# Make the configuration directory
mkdir -p /etc/authelia
# Get our external IP to set in the config.yml
ex_ip="$(ip -br a | sed -n 2p | awk '{ print $3 }' | cut -f1 -d'/')"
# Create a random secret for the config.yml
secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
# Set our password for this example
password='password'
# Hash our password using authelia hash-password to use in the users_database.yml
password_hash="$(/opt/authelia/authelia hash-password "${password}" | awk '{ print $3 }')"
# generate the /etc/authelia/config.yml
cat > "/etc/authelia/config.yml" << AUTHELIA_CONF
host: 127.0.0.1
port: 9091

server:
  read_buffer_size: 4096
  write_buffer_size: 4096
  path: ""

log_level: debug
log_file_path: /etc/authelia/authelia.log
jwt_secret: ${secret}
default_redirection_url: https://${ex_ip}/login

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
      policy: one_factor

session:
  name: authelia_session
  secret: insecure_session_secret
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
    displayname: "username"
    password: "${password_hash}"
    email: username@swizzin.com
    groups:
      - admins
      - dev
AUTHELIA_USER
# Generate the /etc/authelia/authelia.service
cat > "/etc/authelia/authelia.service" << AUTHELIA_SERVICE
[Unit]
Description=Authelia
After=network-online.target

[Service]
Type=exec
ExecStart= /opt/authelia/authelia --config /etc/authelia/config.yml
Restart=always
RestartSec=2
TimeoutStopSec=5
SyslogIdentifier=authelia

[Install]
WantedBy=default.target
AUTHELIA_SERVICE
# Symlink our service file from /etc/authelia/authelia.service to /etc/systemd/system/authelia.service
ln -fsn /etc/authelia/authelia.service /etc/systemd/system/authelia.service
# Install nginx stuff
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash "/usr/local/bin/swizzin/nginx/authelia.sh"
    systemctl reload nginx
    echo_progress_done "Nginx config installed"
fi
# enabel the service
systemctl enable -q --now authelia 2>&1 | tee -a $log
# Create the lock file
touch /install/.authelia.lock
# echo we are done
echo_success Authelia Installed
