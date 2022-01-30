#!/bin/bash
#
# Mylar installer
# Author: Brett
# Copyright (C) 2021 Swizzin

#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv
#shellcheck source=sources/functions/mylar
. /etc/swizzin/sources/functions/mylar

http_port="9645"
systempy3_ver="$(get_candidate_version python3)"
mylar_owner="${mylar_owner:-$(_get_master_username)}"

echo_info "Setting Mylar owner = ${mylar_owner}"
swizdb set "mylar/owner" "${mylar_owner}"

if dpkg --compare-versions "${systempy3_ver}" lt 3.7.5; then
    pyenv_install="true"
    dependency_list=("libsqlite3-dev")
else
    dependency_list=("python3-pip" "python3-venv" "libsqlite3-dev")
fi

apt_install "${dependency_list[@]}"

case "${pyenv_install}" in
    true)
        pyenv_install
        pyenv_install_version 3.8.1
        pyenv_create_venv 3.8.1 /opt/.venv/mylar
        chown -R "${mylar_owner}": /opt/.venv/mylar
        ;;
    *)
        python3_venv "${mylar_owner}" mylar
        ;;
esac

_download_latest
echo_progress_done

echo_progress_start "Setting permissions"
chown -R "${mylar_owner}": /opt/mylar
chown -R "${mylar_owner}": /opt/.venv/mylar
echo_progress_done

echo_progress_start "Configuring Mylar"
mkdir -p "/home/${mylar_owner}/.config/mylar/"
cat > "/home/${mylar_owner}/.config/mylar/config.ini" << EOF
[Interface]
http_port = ${http_port}
http_host = 0.0.0.0
http_root = /
authentication = 0
EOF
chown -R "${mylar_owner}": "/home/${mylar_owner}/.config/mylar"
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/mylar.sh
    systemctl reload -q nginx
    echo_progress_done
    echo_info "Mylar is now running on /mylar"
else
    echo_info "Mylar is now running on port ${http_port}"
fi

echo_progress_start "Installing systemd service"
_service
systemctl -q daemon-reload
systemctl enable -q --now mylar >> "${log}" 2>&1
echo_progress_done "Mylar started"
echo_success "Mylar installed"
touch /install/.mylar.lock
