#!/bin/bash
#
# Mylar installer
# Author: Brett
# Copyright (C) 2021 Swizzin

#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

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

echo_progress_start "Cloning mylar"
git clone https://github.com/mylar3/mylar3.git /opt/mylar >> "${log}" 2>&1 || {
    echo_warn "Clone failed!"
    exit 1
}
echo_progress_done "Mylar cloned"

echo_progress_start "Installing python dependencies"
/opt/.venv/mylar/bin/pip install --upgrade pip >> "${log}" 2>&1
/opt/.venv/mylar/bin/pip3 install -r /opt/mylar/requirements.txt >> "${log}" 2>&1 || {
    echo_warn "Failed to install requirements."
    exit 1
}
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
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Mylar is now running on port ${http_port}."
fi

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/mylar.service << EOS
[Unit]
Description=Mylar service
[Service]
Type=simple
User=${mylar_owner}
ExecStart=/opt/.venv/mylar/bin/python3 /opt/mylar/Mylar.py --datadir /home/${mylar_owner}/.config/mylar/
WorkingDirectory=/opt/mylar
Restart=on-failure
TimeoutStopSec=300
[Install]
WantedBy=multi-user.target
EOS

systemctl enable -q --now mylar >> "${log}" 2>&1
echo_progress_done "Mylar started"
echo_success "Mylar installed"
touch /install/.mylar.lock
