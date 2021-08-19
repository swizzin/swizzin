#!/bin/bash
# LazyLibrarian install script for swizzin
# Author: Aethaeran

##########################################################################
# References
##########################################################################

# https://github.com/Aethaeran/swizzin/blob/feat/jdownloader/scripts/install/jdownloader.sh
# https://lazylibrarian.gitlab.io/install/
# https://github.com/lazylibrarian/LazyLibrarian
# https://gitlab.com/LazyLibrarian/LazyLibrarian

##########################################################################
# Import Sources
##########################################################################

. /etc/swizzin/sources/functions/utils

##########################################################################
# Functions
##########################################################################

function _dependencies() {
    echo "This is where it would be installing dependencies..."
    # chown
}

function _install() {

    # LazyLibrarian runs by default on port 5299 at http://localhost:5299
    #
    #    Install Python 2 v2.6 or higher, or Python 3 v3.5 or higher
    #    Git clone/extract LL wherever you like
    #    Run "python LazyLibrarian.py -d" to start in daemon mode
    #    Fill in all the config (see docs for full configuration)
    echo "This is where it would be installing..."
    # chown
}

function _configure() {

    # LazyLibrarian runs by default on port 5299 at http://localhost:5299
    #
    #    Install Python 2 v2.6 or higher, or Python 3 v3.5 or higher
    #    Git clone/extract LL wherever you like
    #    Run "python LazyLibrarian.py -d" to start in daemon mode
    #    Fill in all the config (see docs for full configuration)
    echo "This is where it would be configuring..."
    # chown
}

function _systemd() {

    cat >/etc/systemd/system/"$app_name".service <<EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/lazylibrarian/LazyLibrarian.py
Type=simple
User=htpc
Group=htpc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo_progress_start "Enabling service $app_name"
    systemctl enable -q --now "$app_name" --quiet
    echo_progress_done
}

function _nginx() {
}

function _finishing_touch() {
    touch "/install/.$app_name.lock"   # Create lock file so that swizzin knows the app is installed.
    echo_success "$pretty_name installed." # Winner winner. Chicken dinner.
}

##########################################################################
# Script Main
##########################################################################
app_name="lazylibrarian"
pretty_name="LazyLibrarian"
default_port="5299"
master=$(_get_master_username)
readarray -t users < <(_get_user_list)

if [[ -n "$1" ]]; then # Configure for JUST the user that was passed to script as arg (i.e. box adduser $user)
    user="$1"
    _configure
    exit 0
fi

_dependencies

_install

_configure

_systemd

_nginx

_finishing_touch
