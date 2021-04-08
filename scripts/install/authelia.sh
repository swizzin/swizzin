#!/usr/bin/env bash
#
# authors: liara userdocs
#
# GNU General Public License v3.0 or later
#
if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "Nginx is required for this application"
    exit
fi
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/os
. /etc/swizzin/sources/functions/os
#shellcheck source=sources/functions/app_port
. /etc/swizzin/sources/functions/app_port
#shellcheck source=sources/functions/ip
. /etc/swizzin/sources/functions/ip
#
username="$(_get_master_username)"                           # Get our main user name to use when bootstrapping filebrowser.
password="$(_get_user_password "${username}")"               # Get our main password name to use when bootstrapping filebrowser.
app_proxy_port="$(_get_app_port "$(basename -- "$0" \.sh)")" # Get our app port using the install script name as the app name
external_ip="$(_external_ip)"                                # Get our external IP
#
# Get the current version using a git ls-remote tag check
authelia_latestv="$(git ls-remote -t --refs https://github.com/authelia/authelia.git | awk '{sub("refs/tags/", "");sub("(.*)-alpha(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n1)"
case "$(_os_arch)" in
    "amd64") authelia_arch="amd64" ;;
    "armhf") authelia_arch="arm32v7" ;;
    "arm64") authelia_arch="arm64v8" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac
authelia_url="https://github.com/authelia/authelia/releases/download/${authelia_latestv}/authelia-linux-${authelia_arch}.tar.gz"
#
echo_progress_start "Downloading and extracting Authelia"
mkdir -p "/opt/authelia"
wget -qO "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" "${authelia_url}"
tar -xf "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" -C "/opt/authelia/" "authelia-linux-${authelia_arch}"
ln -fsn "/opt/authelia/authelia-linux-${authelia_arch}" "/opt/authelia/authelia"
rm_if_exists "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz"
echo_progress_done
#
echo_progress_start "Configuring Authelia"
mkdir -p /etc/authelia
jwt_secret="$(cat < /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
insecure_secret="$(cat < /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
password_hash="$(/opt/authelia/authelia hash-password "${password}" | awk '{ print $3 }')"
# generate the /etc/authelia/config.yml
cat > "/etc/authelia/config.yml" << AUTHELIA_CONF
host: 127.0.0.1
port: ${app_proxy_port}

server:
  read_buffer_size: 4096
  write_buffer_size: 4096
  path: "login"

theme: dark
log_level: debug
log_file_path: /var/log/authelia/authelia.log
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
    - domain: ${external_ip}
      resources:
        - "^/(sonarr|radarr|jackett)/api.*$"
        - "^/filebrowser/share/(.*)$"
      policy: bypass

    - domain: ${external_ip}
      policy: one_factor

session:
  name: authelia_session
  secret: ${insecure_secret}
  expiration: 1h
  inactivity: 5m
  remember_me_duration: 1M
  domain: ${external_ip}

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
echo_progress_done
#
echo_progress_start "Installing systemd service"
cat > "/etc/systemd/system/authelia.service" << AUTHELIA_SERVICE
[Unit]
Description=Authelia
After=network-online.target

[Service]
Type=exec
User=authelia
Group=authelia
ExecStart=/opt/authelia/authelia --config /etc/authelia/config.yml
Restart=always
RestartSec=2
TimeoutStopSec=5
SyslogIdentifier=authelia

[Install]
WantedBy=default.target
AUTHELIA_SERVICE
echo_progress_done

echo_progress_start "Configuring the correct permissions"
useradd --system authelia &>> "$log"
chown -R authelia: /opt/authelia
chown -R authelia: /etc/authelia
mkdir -p /var/log/authelia
chown -R authelia: /var/log/authelia
echo_progress_done
#
# Install nginx stuff
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash "/usr/local/bin/swizzin/nginx/authelia.sh" install
    systemctl reload nginx
    echo_progress_done "Nginx config installed"
fi

if [[ -f /install/.panel.lock ]]; then
    echo_progress_start "tmp qol panel changes"
    #
    sed 's|systemd = "jackett@"|systemd = "jackett"|g' -i /opt/swizzin/core/profiles.py
    echo 'RATELIMIT_ENABLED = False' >> /opt/swizzin/swizzin.cfg
    systemctl restart -q panel &>> "$log"
    #
    echo_progress_done "done"
fi
# enable the service
systemctl enable -q --now authelia &>> "$log"
# Create the lock file
touch /install/.authelia.lock
# echo we are done
echo_success "Authelia Installed"
