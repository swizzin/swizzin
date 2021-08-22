#!/bin/bash
# LazyLibrarian install script for swizzin
# Author: Aethaeran

##########################################################################
# References
##########################################################################

# https://github.com/Aethaeran/swizzin/blob/feat/jdownloader/scripts/install/jdownloader.sh
# https://lazylibrarian.gitlab.io/install/
# https://www.reddit.com/r/LazyLibrarian/comments/jw5e22/lazylibrarian_calibre_calibreweb_booksonic/
# https://github.com/lazylibrarian/LazyLibrarian
# https://gitlab.com/LazyLibrarian/LazyLibrarian
# https://lazylibrarian.gitlab.io/config_commandline/
# https://github.com/swizzin/swizzin/pull/743
# https://lazylibrarian.gitlab.io/config_users/
# https://lazylibrarian.gitlab.io/config_downloaders/
# https://www.reddit.com/r/LazyLibrarian/
# https://lazylibrarian.gitlab.io/api/

##########################################################################
# Import Sources
##########################################################################

#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

##########################################################################
# Variables
##########################################################################

app_name="lazylibrarian"

if [ -z "$LAZYLIB_OWNER" ]; then
    if ! LAZYLIB_OWNER="$(swizdb get "$app_name/owner")"; then
        LAZYLIB_OWNER="$(_get_master_username)"
        echo_log_only "Setting ${app_name^} owner = $LAZYLIB_OWNER"
        swizdb set "$app_name/owner" "$LAZYLIB_OWNER"
    fi
else
    echo_info "Setting ${app_name^} owner = $LAZYLIB_OWNER"
    swizdb set "$app_name/owner" "$LAZYLIB_OWNER"
fi
user="$LAZYLIB_OWNER"

pretty_name="LazyLibrarian"
default_port="5299"
config_dir="/home/$user/.config"
data_dir="$config_dir/lazylibrarian"
app_dir="/opt/$app_name"
venv_dir="/opt/.venv/$app_name"
pip_reqs='apprise pyOpenSSL'

##########################################################################
# Functions
##########################################################################

function _dependencies() {
    echo_info "Installing dependencies for $pretty_name..."

    echo_progress_start "Creating $pretty_name venv"
    python3_venv "$user" "$app_name"
    echo_progress_done

    echo_progress_start "Installing python dependencies to venv"
    # shellcheck disable=2154           # log variable is inherited from box itself.
    "$venv_dir/bin/pip" install --upgrade pip >> "${log}" 2>&1 # Upgrade pip
    # shellcheck disable=2086           # We want the $pip_reqs variable to expand. So 2086's warning is invalid here.
    "$venv_dir/bin/pip" install $pip_reqs >> "${log}" 2>&1
    chown -R "$user": "$venv_dir"
    echo_progress_done
    # TODO: https://lazylibrarian.gitlab.io/config_rtorrent/ says we would require libtorrent for rtorrent compatability
}

function _install() {
    echo_progress_start "Installing $pretty_name..."
    mkdir -p "$app_dir"
    mkdir -p "$data_dir"
    #    Git clone/extract LL wherever you like
    # shellcheck disable=2154           # log variable is inherited from box itself.
    git clone "https://gitlab.com/LazyLibrarian/LazyLibrarian.git" "$app_dir" >> "$log" 2>&1
    if [[ ! -e "$app_dir/LazyLibrarian.py" ]]; then
        ecoh_error "Git clone unsuccessful. Try running the box install again."
        exit 1
    fi
    chown "$user": "$config_dir" # Ensure correct owner\group on config_dir
    chown -R "$user": "$app_dir" # Change owner\group recursively for new dirs.
    chown -R "$user": "$data_dir"
    echo_progress_done
}

function _configure() {
    #    Fill in all the config (see docs for full configuration)
    echo_progress_start "Configuring $pretty_name..."
    cat > "$data_dir/config.ini" << EOF
[General]
http_root = /lazylibrarian

[Git]
auto_update = 1
EOF
    echo_progress_done
}

function _systemd() {
    # CommandLine Options¶
    #-d --daemon - Run the server as a daemon - not available on windows
    #-q --quiet - Don't log to console
    #-p --pidfile - Store the process id in this file
    #--debug - Show debug log messages
    #--nolaunch - Don't launch browser
    #--update - Update to latest version from GitHub at start-up (only git installations)
    #--port - Force webserver to listen on this port
    #--datadir - Path to the datadir used to store database, config, cache - Default is to use program directory if this is unset
    #--config - Path to config.ini - Default is to use datadir
    #    Run "python LazyLibrarian.py -d" to start in daemon mode
    echo_progress_start "Configuring $pretty_name systemd service..."
    cat > "/etc/systemd/system/$app_name.service" << EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
User=$user
Group=$user
Type=simple
ExecStart=$venv_dir/bin/python \
$app_dir/LazyLibrarian.py \
--datadir $data_dir
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    echo_progress_done

    echo_progress_start "Enabling $app_name's systemd service..."
    systemctl enable --quiet --now "$app_name"
    echo_progress_done
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing $app_name's nginx configuration..."
        bash "/usr/local/bin/swizzin/nginx/$app_name.sh"
        # shellcheck disable=2154           # log variable is inherited from box itself.
        systemctl reload nginx >> "$log" 2>&1
        echo_progress_done
    else
        echo_info "$pretty_name will run on port $default_port"
    fi
}

function _finishing_touch() {
    touch "/install/.$app_name.lock"       # Create lock file so that swizzin knows the app is installed.
    echo_success "$pretty_name installed." # Winner winner. Chicken dinner.
}

##########################################################################
# Main
##########################################################################

_dependencies

_install

_configure

_systemd

_nginx

_finishing_touch
