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

. /etc/swizzin/sources/functions/utils

##########################################################################
# Variables
##########################################################################

app_name="lazylibrarian"
pretty_name="LazyLibrarian"
default_port="5299"
master=$(_get_master_username)
data_dir="/home/$master/.config/lazylibrarian"
app_dir="/opt/$app_name"

##########################################################################
# Functions
##########################################################################

function _dependencies() {
    # TODO: Create a venv for LazyLibrarian
    # TODO: When run from CLI LazyLibrarian throws the following warnings early on. Add these libs to venv to ensure LazyLib has full functionality.
    # 19-Aug-2021 17:43:39 - WARNING :: MAIN : __init__.py:initialize:976 : apprise: library missing
    #19-Aug-2021 17:43:39 - WARNING :: MAIN : __init__.py:initialize:976 : pyOpenSSL: module missing
    #19-Aug-2021 17:43:40 - WARNING :: MAIN : LazyLibrarian.py:main:276 : Looking for Apprise library: No module named 'apprise'
    echo_progress_start "Installing dependencies for $pretty_name..."
    #    Install Python 2 v2.6 or higher, or Python 3 v3.5 or higher
    # TODO: https://lazylibrarian.gitlab.io/config_rtorrent/ claims it might require libtorrent
    echo_progress_done
}

function _install() {
    echo_progress_start "Installing $pretty_name..."
    mkdir -p "$app_dir"
    mkdir -p "$data_dir"
    #    Git clone/extract LL wherever you like
    # TODO: Should add some logic in here to verify git cloned successfully. It passed by here without doing so on me once.
    # shellcheck disable=2154           # log variable is inherited from box itself.
    git clone "https://gitlab.com/LazyLibrarian/LazyLibrarian.git" "$app_dir" >>"$log" 2>&1

    chown -R "$master": "$app_dir" # Change owner\group recursively for new dirs.
    chown -R "$master": "$data_dir"
    echo_progress_done
}

function _configure() {
    #    Fill in all the config (see docs for full configuration)
    echo_progress_start "Configuring $pretty_name..."
    cat >"$app_dir/config.ini" << EOF
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
    cat >"/etc/systemd/system/$app_name.service" <<EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
User=$master
Group=$master
Type=simple
ExecStart=/usr/bin/python3 \
$app_dir/LazyLibrarian.py
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
        systemctl reload nginx >>"$log" 2>&1
        echo_progress_done
    else
        echo_info "$pretty_name will run on port $default_port"
    fi
}

function _finishing_touch() {
    touch "/install/.$app_name.lock"        # Create lock file so that swizzin knows the app is installed.
    echo_success "$pretty_name installed."  # Winner winner. Chicken dinner.
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
