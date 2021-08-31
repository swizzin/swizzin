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
# https://github.com/swizzin/swizzin/pull/743
# https://lazylibrarian.gitlab.io/config_users/
# https://lazylibrarian.gitlab.io/config_downloaders/
# https://www.reddit.com/r/LazyLibrarian/
# https://lazylibrarian.gitlab.io/api/
# https://lazylibrarian.gitlab.io/config_commandline/

##########################################################################
# Import Sources
##########################################################################

#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv
#shellcheck source=sources/functions/users
. /etc/swizzin/sources/functions/users
#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests
#shellcheck source=sources/functions/swizdb
. /etc/swizzin/sources/functions/swizdb

##########################################################################
# Variables
##########################################################################

app_name="lazylibrarian"
user="$(_get_app_owner "$app_name" "$LAZYLIB_OWNER")"
pretty_name="LazyLibrarian"
default_port="5299"
config_dir="/home/$user/.config"
data_dir="$config_dir/lazylibrarian"
app_dir="/opt/$app_name"
venv_dir="/opt/.venv/$app_name"
pip_reqs='urllib3 apprise Pillow pyOpenSSL'
download_dir="/home/$user/Downloads/$pretty_name"

##########################################################################
# Functions
##########################################################################

function _dependencies() {
    # TODO: https://lazylibrarian.gitlab.io/config_rtorrent/ says we would require libtorrent for rtorrent compatibility
    apt_install "python3-venv"                                      # Ensure pip is installed. Required for Ubuntu Focal.
    python3_venv "$user" "$app_name"                                # Create venv
    chown -R "$user": "$venv_dir"                                   # Ensure venv's owner is app's owner
    echo_progress_start "Installing pip dependencies for $pretty_name"
    # shellcheck disable=2154                                       # log variable is inherited from box itself.
    "$venv_dir/bin/pip" install --upgrade pip >>"${log}" 2>&1       # Ensure pip is updated.
    # shellcheck disable=2086                                       # We want the $pip_reqs variable to expand. So 2086's warning is invalid here.
    "$venv_dir/bin/pip" install $pip_reqs >>"${log}" 2>&1           # Add required/wanted Python libraries
    echo_progress_done
}

function _install() {
    echo_progress_start "Cloning $pretty_name source"
    mkdir -p "$app_dir"                                             # Ensure app dir exists.
    mkdir -p "$data_dir"                                            # Ensure data dir exists.
    # shellcheck disable=2154                                       # log variable is inherited from box itself.
    git clone "https://gitlab.com/LazyLibrarian/LazyLibrarian.git" "$app_dir" >>"$log" 2>&1
    if [[ ! -e "$app_dir/LazyLibrarian.py" ]]; then                 # Check if git clone failed.
        echo_error "Git clone unsuccessful."
        exit 1
    fi
chown "$user": "$config_dir"                                        # Ensure correct owner\group on config_dir
    chown -R "$user": "$app_dir"                                    # Change owner\group recursively for new dirs.
    chown -R "$user": "$data_dir"
    echo_progress_done "Source cloned"
}

function _configure() {
    echo_info "Creating $download_dir as $pretty_name's default download directory."
    mkdir -p "$download_dir"                                        # Ensure download dir exists
    chown -R "$user": "$download_dir"                               # Ensure download dir has the correct owner
    echo_progress_done

    echo_progress_start "Configuring $pretty_name"
    cat >"$data_dir/config.ini" <<EOF
[General]
http_root = /$app_name
download_dir = $download_dir

[Git]
auto_update = 1
EOF
    echo_progress_done
}

function _systemd() {
    # TODO: add --daemon and --pidfile, probably type forking is necessary
    echo_progress_start "Creating $pretty_name systemd service"
    cat >"/etc/systemd/system/$app_name.service" <<EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
User=$user
Group=$user
Type=forking
ExecStart=$venv_dir/bin/python3 \
$app_dir/LazyLibrarian.py \
--daemon \
--pidfile $data_dir/pidfile \
--nolaunch \
--datadir $data_dir
PIDFile=$data_dir/pidfile
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload                                         # Reload daemons whenever a systemd service is changed
    systemctl enable --quiet --now "$app_name"                      # Enable systemd service for app
    echo_progress_done
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing $app_name's nginx configuration"
        bash "/usr/local/bin/swizzin/nginx/$app_name.sh"
        # shellcheck disable=2154                                   # log variable is inherited from box itself.
        systemctl reload nginx >>"$log" 2>&1
        echo_progress_done
    else
        echo_info "$pretty_name will run on port $default_port"
        echo_info "Please make sure to finalize $pretty_name's configuration in it's web interface\nhttp://127.0.0.1:$(get_port "$app_name")/$app_name"
    fi
}

function _finishing_touch() {
    touch "/install/.$app_name.lock"                                # Create lock file so that swizzin knows the app is installed.
    echo_success "$pretty_name installed."                          # Winner winner. Chicken dinner.
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
