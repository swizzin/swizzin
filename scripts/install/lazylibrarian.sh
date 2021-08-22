#!/bin/bash
# LazyLibrarian install script for swizzin
# Author: Aethaeran 2021
# GPLv3

# References
# https://www.reddit.com/r/LazyLibrarian/comments/jw5e22/lazylibrarian_calibre_calibreweb_booksonic/
# https://gitlab.com/LazyLibrarian/LazyLibrarian
# https://lazylibrarian.gitlab.io/

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

function _dependencies() {
    echo_info "Installing dependencies for $pretty_name"

    #shellcheck source=sources/functions/pyenv
    . /etc/swizzin/sources/functions/pyenv
    python3_venv "$user" "$app_name"

    echo_progress_start "Installing python dependencies to venv"
    "$venv_dir/bin/pip" install --upgrade pip >> "${log}" 2>&1
    # shellcheck disable=2086 # We want the $pip_reqs variable to expand. So 2086's warning is invalid here.
    "$venv_dir/bin/pip" install $pip_reqs >> "${log}" 2>&1
    chown -R "$user": "$venv_dir"
    echo_progress_done
    # TODO: https://lazylibrarian.gitlab.io/config_rtorrent/ says we would require libtorrent for rtorrent compatability
}

function _install() {
    # https://lazylibrarian.gitlab.io/install/
    echo_progress_start "Cloning $pretty_name source"
    mkdir -p "$app_dir"
    mkdir -p "$data_dir"
    git clone "https://gitlab.com/LazyLibrarian/LazyLibrarian.git" "$app_dir" >> "$log" 2>&1
    if [[ ! -e "$app_dir/LazyLibrarian.py" ]]; then
        echo_error "Git clone unsuccessful. Try running the box install again."
        exit 1
    fi
    chown "$user": "$config_dir"
    chown -R "$user": "$app_dir"
    chown -R "$user": "$data_dir"
    echo_progress_done "Source cloned"
}

function _configure() {
    echo_progress_start "Configuring $pretty_name"
    cat > "$data_dir/config.ini" << EOF
[General]
http_root = /lazylibrarian

[Git]
auto_update = 1
EOF
    echo_progress_done
}

function _systemd() {
    echo_progress_start "Configuring $pretty_name systemd service"
    # https://lazylibrarian.gitlab.io/config_commandline/
    cat > "/etc/systemd/system/$app_name.service" << EOF
[Unit]
Description=LazyLibrarian
After=network.target

[Service]
User=$user
Group=$user
Type=simple
ExecStart=$venv_dir/bin/python $app_dir/LazyLibrarian.py --datadir $data_dir
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable --quiet --now "$app_name"
    echo_progress_done
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Installing $app_name's nginx configuration"
        bash "/usr/local/bin/swizzin/nginx/$app_name.sh"
        systemctl reload nginx >> "$log" 2>&1
        echo_progress_done
    else
        echo_info "$pretty_name will run on port $default_port"
    fi
}

function _finishing_touch() {
    touch "/install/.$app_name.lock"
    echo_success "$pretty_name installed." # Winner winner. Chicken dinner.
    echo_info "Please make sure to finalise the setup in $pretty_name's web interface"
}

_dependencies
_install
_configure
_systemd
_nginx
_finishing_touch
