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
    echo "This is where it would be installing..."
    # chown
}

function _systemd() {
    cat >/etc/systemd/system/"$app_name"@.service <<EOF
EOF
}

function _nginx() {
}

##########################################################################
# Script Main
##########################################################################
app_name="lazylibrarian"
pretty_name="LazyLibrarian"
default_port="5299"
master=

if [[ -n "$1" ]]; then # Configure for JUST the user that was passed to script as arg (i.e. box adduser $user)
    user="$1"
    _configure
    exit 0
fi

readarray -t users < <(_get_user_list)

for user in "${users[@]}"; do
    _install
done

_systemd

for user in "${users[@]}"; do # Enable a separate service for each swizzin user
    echo_progress_start "Enabling service $app_name@$user"
    systemctl enable -q --now "$app_name"@"$user" --quiet
    echo_progress_done
done

touch /install/."$app_name".lock     # Create lock file so that swizzin knows JDownloader is installed.
echo_success "JDownloader installed" # Winner winner. Chicken dinner.
