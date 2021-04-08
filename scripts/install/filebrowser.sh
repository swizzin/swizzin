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
username="$(_get_master_username)"                           # Get our master username
password="$(_get_user_password "${username}")"               # Get our master user's password
app_proxy_port="$(_get_app_port "$(basename -- "$0" \.sh)")" # Get the application port from an array using the name of this script
external_ip="$(_external_ip)"                                # Get our external IP address
#
# Create the required directories for this application.
mkdir -p "/home/${username}/.config/Filebrowser"
#
app_latest_version="$(git ls-remote -t --sort=-v:refname --refs https://github.com/filebrowser/filebrowser.git | awk '{sub("refs/tags/v", "");sub("(.*)(rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | head -n 1)"
case "$(_os_arch)" in
    "amd64") app_arch="amd64" ;;
    "armhf") app_arch="armv7" ;;
    "arm64") app_arch="arm64" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac
app_url="https://github.com/filebrowser/filebrowser/releases/download/v${app_latest_version}/linux-${app_arch}-filebrowser.tar.gz"
# Download and extract the files to the desired location.
echo_progress_start "Downloading and extracting Filebrowser"
wget -O "/tmp/filebrowser.tar.gz" "${app_url}" &>> "${log}"
mkdir -p "/opt/filebrowser"
tar -xvzf "/tmp/filebrowser.tar.gz" -C "/opt/filebrowser" filebrowser &>> "${log}"
rm -f "/tmp/filebrowser.tar.gz" &>> "${log}"
echo_progress_done
#
# Perform some bootstrapping commands on filebrowser to create the database settings we desire.
# This command initialise our database.
echo_progress_start "Initialising database and configuring Filebrowser"
"/opt/filebrowser/filebrowser" config init -d "/home/${username}/.config/Filebrowser/filebrowser.db" &>> "${log}"
# These commands configure some options in the database.
"/opt/filebrowser/filebrowser" config set -a 0.0.0.0 -p "${app_proxy_port}" -l "/home/${username}/.config/Filebrowser/filebrowser.log" -d "/home/${username}/.config/Filebrowser/filebrowser.db" &>> "$log"
"/opt/filebrowser/filebrowser" users add "${username}" "${password}" --perm.admin -d "/home/${username}/.config/Filebrowser/filebrowser.db" &>> "$log"
# Set the permissions after we are finsished configuring filebrowser.
chown "${username}.${username}" -R "/home/${username}/.config" &>> "${log}"
chown "${username}.${username}" -R "/opt/filebrowser" &>> "${log}"
chmod 700 "/opt/filebrowser/filebrowser" &>> "${log}"
echo_progress_done
#
# Configure the nginx proxypass using positional parameters.
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash "/usr/local/bin/swizzin/nginx/filebrowser.sh" install
    systemctl -q reload nginx &>> "${log}"
    echo_progress_done "Nginx config installed"
fi
#
# Create the service file that will start and stop filebrowser.
echo_progress_start "Installing systemd service"
cat > "/etc/systemd/system/filebrowser.service" <<- SERVICE
	[Unit]
	Description=filebrowser
	After=network.target

	[Service]
	User=${username}
	Group=${username}
	UMask=002

	Type=simple
	WorkingDirectory=/home/${username}
	ExecStart=/opt/filebrowser/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db
	TimeoutStopSec=20
	KillMode=process
	Restart=always
	RestartSec=2

	[Install]
	WantedBy=multi-user.target
SERVICE
#
# Start the filebrowser service.
systemctl -q daemon-reload &>> "${log}"
systemctl -q enable --now "filebrowser.service" &>> "${log}"
echo_progress_done "Systemd service installed"
#
# This file is created after installation to prevent reinstalling. You will need to remove the app first which deletes this file.
touch "/install/.filebrowser.lock"
#
echo_success "FileBrowser installed and available in the panel"
#
echo_warn "Make sure to use your swizzin credentials when logging in"
#
exit
