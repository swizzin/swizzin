#!/usr/bin/env bash
#
# authors: liara userdocs
#
# GNU General Public License v3.0 or later

# Get our main user credentials to use when bootstrapping filebrowser.
username="$(_get_master_username)"
password="$(_get_user_password "$username")"

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
# This will generate a random port for the script between the range 10001 to 32001 to use with applications.
app_port_http="$(port 10001 32001)"

_install() {
    # Create the required directories for this application.
    mkdir -p "/home/${username}/bin"
    mkdir -p "/home/${username}/.config/Filebrowser"
    #
    # Download and extract the files to the desired location.
    echo_progress_start "Downloading and extracting source code"

    case "$(_os_arch)" in
        "amd64" | "arm64")
            fb_arch="$(_os_arch)"
            ;;
        "armhf")
            fb_arch="(uname -r)"
            ;;
        *)
            echo_error "$(_os_arch) not supported by filebrowser"
            exit 1
            ;;
    esac

    dlurl="$(curl -sNL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | jq -r '.assets[]?.browser_download_url' | grep linux-"${fb_arch}")"
    wget -O "/home/${username}/filebrowser.tar.gz" "$dlurl" >> $log 2>&1 || {
        echo_error "Failed to download archive"
        exit 1
    }
    tar -xvzf "/home/${username}/filebrowser.tar.gz" --exclude LICENSE --exclude README.md -C "/home/${username}/bin" >> $log 2>&1 || {
        echo_error "Failed to extract downloaded file"
        exit 1
    }
    # Removes the archive as we no longer need it.
    rm -f "/home/${username}/filebrowser.tar.gz" >> "$log" 2>&1
    echo_progress_done
}

# Perform some bootstrapping commands on filebrowser to create the database settings we desire.
_config() {
    #shellcheck source=sources/functions/ssl
    . /etc/swizzin/sources/functions/ssl
    # Create a self signed cert in the config directory to use with filebrowser.
    create_self_ssl "${username}"

    # This command initialise our database.
    echo_progress_start "Initialising database and configuring Filebrowser"
    {
        "/home/${username}/bin/filebrowser" config init -d "/home/${username}/.config/Filebrowser/filebrowser.db"
        # These commands configure some options in the database.
        "/home/${username}/bin/filebrowser" config set -t "/home/${username}/.ssl/${username}-self-signed.crt" -k "/home/${username}/.ssl/${username}-self-signed.key" -d "/home/${username}/.config/Filebrowser/filebrowser.db"
        "/home/${username}/bin/filebrowser" config set -a 0.0.0.0 -p "${app_port_http}" -l "/home/${username}/.config/Filebrowser/filebrowser.log" -d "/home/${username}/.config/Filebrowser/filebrowser.db"
        "/home/${username}/bin/filebrowser" users add "${username}" "${password}" --perm.admin -d "/home/${username}/.config/Filebrowser/filebrowser.db"
    } >> "$log" 2>&1

    # Set the permissions after we are finsished configuring filebrowser.
    chown "${username}:" -R "/home/${username}/bin"
    chown "${username}:" "/home/${username}/.config"
    chown "${username}:" -R "/home/${username}/.config/Filebrowser"
    chmod 700 "/home/${username}/bin/filebrowser"
    chmod 700 -R "/home/${username}/.config/Filebrowser"
    echo_progress_done
}

# Configure the nginx proxypass using positional parameters.
_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing nginx config"
        bash "/usr/local/bin/swizzin/nginx/filebrowser.sh" "${app_port_http}"
        systemctl reload nginx
        echo_progress_done "Nginx config installed"
    else
        echo_info "FileBrowser will run on port ${app_port_http}"
    fi
}

# Create the service file that will start and stop filebrowser.
_systemd() {
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
	ExecStart=/home/${username}/bin/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db
	TimeoutStopSec=20
	KillMode=process
	Restart=always
	RestartSec=2

	[Install]
	WantedBy=multi-user.target
SERVICE

    # Start the filebrowser service.
    systemctl enable -q --now "filebrowser.service" 2>&1 | tee -a "$log"
    echo_progress_done "Filebrowser service started"
}

_install
_config
_nginx
_systemd

# This file is created after installation to prevent reinstalling. You will need to remove the app first which deletes this file.
touch "/install/.filebrowser.lock"

# A helpful echo to the terminal.
echo_success "FileBrowser installed"
echo_warn "Make sure to use your swizzin credentials when logging in"
