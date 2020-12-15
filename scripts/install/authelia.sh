#!/bin/bash
#
if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "You must install nginx first"
    exit
fi

mkdir -p "/opt/authelia"
wget -qO "/opt/authelia.tar.gz" "https://github.com$(/usr/bin/curl -sNL https://github.com/authelia/authelia/releases | grep -Eom1 '/authelia/(.*)tar.gz')"
tar -xf "/opt/authelia.tar.gz" -C "/opt/authelia/" authelia-linux-amd64
ln -fsn "/opt/authelia/authelia-linux-amd64" "/opt/authelia/authelia"
[[ -f "/opt/authelia.tar.gz" ]] && rm -f "/opt/authelia.tar.gz"
#
mkdir -p /etc/authelia
ex_ip="$(ip -br a | sed -n 2p | awk '{ print $3 }' | cut -f1 -d'/')"
secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
password_hash="$(/opt/authelia/authelia hash-password password | awk '{ print $3 }')"
#
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
#
ln -fsn /etc/authelia/authelia.service /etc/systemd/system/authelia.service

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash "/usr/local/bin/swizzin/nginx/authelia.sh" "${app_port_http}"
    systemctl reload nginx
    echo_progress_done "Nginx config installed"
fi

systemctl enable -q --now authelia 2>&1 | tee -a $log

touch /install/.authelia.lock

echo_success Done
