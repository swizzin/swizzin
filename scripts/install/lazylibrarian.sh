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

##########################################################################
# Import Sources
##########################################################################

. /etc/swizzin/sources/functions/utils

##########################################################################
# Functions
##########################################################################

function _dependencies() {
    echo "This is where it would be installing dependencies..."
    #    Install Python 2 v2.6 or higher, or Python 3 v3.5 or higher
}

function _install() {
    echo "This is where it would be installing..."
    mkdir -p "$app_dir"
    mkdir -p "$data_dir"
    #    Git clone/extract LL wherever you like
    git clone "https://gitlab.com/LazyLibrarian/LazyLibrarian.git" "$app_dir"
    # chown
    chown -R "$master": "$app_dir"
    chown -R "$master": "$data_dir"
}

function _configure() {
    echo "This is where it would be configuring..."
    #    Fill in all the config (see docs for full configuration)
}

function _systemd() {

    #    Run "python LazyLibrarian.py -d" to start in daemon mode
    cat >/etc/systemd/system/"$app_name".service <<EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/lazylibrarian/LazyLibrarian.py --daemon --datadir=/home/$master/.config/lazylibrarian --nolaunch
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

function _nginx_sonarr() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing nginx configuration"
        bash "/usr/local/bin/swizzin/nginx/$app_name.sh"
        systemctl reload nginx >> "$log" 2>&1
        echo_progress_done
    else
        echo_info "$pretty_name will run on port $default_port"
    fi
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
data_dir="/home/$master/.config/lazylibrarian"
app_dir="/opt/$app_name"

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
