#!/bin/bash
# Mylar installer
# Author: Brett
# Copyright (C) 2021 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#! /bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

user=$(_get_master_username)
port=$(port 7000 11000)
systempy3_ver=$(get_candidate_version python3)

if dpkg --compare-versions "${systempy3_ver}" lt 3.7.5; then
    LIST='acl'
    PYENV=True
else
    LIST='python3-pip python3-venv acl'
fi

apt_install $LIST

case ${PYENV} in
    True)
        pyenv_install
        pyenv_install_version 3.8.1
        pyenv_create_venv 3.8.1 /opt/.venv/mylar
        chown -R mylar: /opt/.venv/mylar
        ;;
    *)
        python3_venv "${user}" mylar
        ;;
esac

echo_progress_start "Cloning mylar"
git clone https://github.com/mylar3/mylar3.git /opt/mylar >> ${log} 2>&1 || {
    echo_warn "Clone failed!"
    exit 1
}
echo_progress_done "Mylar cloned"

echo_progress_start "Installing python dependencies"
/opt/.venv/mylar/bin/pip install -r /opt/mylar/requirements.txt >> ${log} 2>&1 || {
    echo_warn "Failed to install requirements."
    exit 1
}
echo_progress_done

echo_progress_start "Setting permissions"
chown -R "$user": /opt/mylar
chown -R "$user": /opt/.venv/mylar
setfacl -m g:"$user":rx /home/*
echo_progress_done

echo_progress_start "Configuring Mylar"
cat > /home/"$user"/.config/mylar/config.ini << EOF
[Interface]
http_port = ${port}
http_host = 0.0.0.0
http_root = /mylar
http_username = ${user}
http_password = $(_get_user_password "${user}")
authentication = 1
EOF
echo_progress_done

# Checking nginx existence is the first thing that happens in the script
echo_progress_start "Configuring nginx"
bash /usr/local/bin/swizzin/nginx/mylar.sh
systemctl reload nginx
echo_progress_done

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/mylar.service << EOS
[Unit]
Description=Mylar service
[Service]
Type=simple
User=${user}
ExecStart=/opt/.venv/mylar/bin/python Mylar.py --datadir /home/${user}/.config/mylar/
WorkingDirectory=/opt/mylar
Restart=on-failure
TimeoutStopSec=300
[Install]
WantedBy=multi-user.target
EOS

systemctl enable -q --now mylar >> ${log} 2>&1
echo_progress_done "Mylar started"

echo_info "Mylar is now running on port ${port}."

echo_success "Mylar installed"
touch /install/.mylar.lock
