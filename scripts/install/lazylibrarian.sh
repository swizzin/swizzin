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
    # TODO: venv please
    # 19-Aug-2021 17:43:39 - WARNING :: MAIN : __init__.py:initialize:976 : apprise: library missing
    #19-Aug-2021 17:43:39 - WARNING :: MAIN : __init__.py:initialize:976 : pyOpenSSL: module missing
    #19-Aug-2021 17:43:40 - WARNING :: MAIN : LazyLibrarian.py:main:276 : Looking for Apprise library: No module named 'apprise'
    echo "This is where it would be installing dependencies..."
    #    Install Python 2 v2.6 or higher, or Python 3 v3.5 or higher
    # TODO: https://lazylibrarian.gitlab.io/config_rtorrent/ claims it might require libtorrent
}

function _install() {
    echo "This is where it would be installing..."
    mkdir -p "$app_dir"
    mkdir -p "$data_dir"
    #    Git clone/extract LL wherever you like
    git clone "https://gitlab.com/LazyLibrarian/LazyLibrarian.git" "$app_dir" >>$log 2>&1
    # chown
    chown -R "$master": "$app_dir"
    chown -R "$master": "$data_dir"
}

function _configure() {
    #    Fill in all the config (see docs for full configuration)
    echo "This is where it would be configuring for $user..."
    # TODO: this is gross. Would much rather pass the single config with the api
    # https://lazylibrarian.gitlab.io/api/
    cat >"$app_dir/config.ini" << EOF
[General]
http_root = /lazylibrarian
EOF
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
    cat >"/etc/systemd/system/$app_name.service" <<EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
ExecStart=/usr/bin/python3 \
$app_dir/LazyLibrarian.py
Type=simple
User=$master
Group=$master
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo_progress_start "Enabling service $app_name"
    systemctl enable --quiet --now "$app_name"
    echo_progress_done
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing nginx configuration"
        bash "/usr/local/bin/swizzin/nginx/$app_name.sh"
        # shellcheck disable=2154 # log variable is inherited from box itself.
        systemctl reload nginx >>"$log" 2>&1
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
