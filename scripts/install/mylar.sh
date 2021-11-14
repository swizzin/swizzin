#!/bin/bash
# Mylar installer
# Author: Brett
# Copyright (C) 2021 Swizzin
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

port=9645
systempy3_ver=$(get_candidate_version python3)

if [ -z "$MYLAR_OWNER" ]; then
    if ! MYLAR_OWNER="$(swizdb get mylar/owner)"; then
        MYLAR_OWNER=$(_get_master_username)
        echo_info "Setting Mylar owner = $MYLAR_OWNER"
        swizdb set "mylar/owner" "$MYLAR_OWNER"
    fi
else
    echo_info "Setting Mylar owner = $MYLAR_OWNER"
    swizdb set "mylar/owner" "$MYLAR_OWNER"
fi

if dpkg --compare-versions "${systempy3_ver}" lt 3.7.5; then
    PYENV=True
    LIST=("libsqlite3-dev")
else
    LIST=("python3-pip" "python3-venv" "libsqlite3-dev")
fi

apt install "${LIST[@]}"

case ${PYENV} in
    True)
        pyenv_install
        pyenv_install_version 3.8.1
        pyenv_create_venv 3.8.1 /opt/.venv/mylar
        chown -R "${MYLAR_OWNER}": /opt/.venv/mylar
        ;;
    *)
        python3_venv "${MYLAR_OWNER}" mylar
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
chown -R "$MYLAR_OWNER": /opt/mylar
chown -R "$MYLAR_OWNER": /opt/.venv/mylar
echo_progress_done

echo_progress_start "Configuring Mylar"
mkdir -p "/home/${MYLAR_OWNER}/.config/mylar/"
cat > "/home/${MYLAR_OWNER}/.config/mylar/config.ini" << EOF
[Interface]
http_port = ${port}
http_host = 0.0.0.0
http_root = /mylar
authentication = 0
EOF

chown -R "$MYLAR_OWNER": /home/$MYLAR_OWNER/.config/mylar
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/mylar.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Mylar is now running on port ${port}/mylar."
fi

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/mylar.service << EOS
[Unit]
Description=Mylar service
[Service]
Type=simple
User=${MYLAR_OWNER}
ExecStart=/opt/.venv/mylar/bin/python3 /opt/mylar/Mylar.py --datadir /home/${MYLAR_OWNER}/.config/mylar/
WorkingDirectory=/opt/mylar
Restart=on-failure
TimeoutStopSec=300
[Install]
WantedBy=multi-user.target
EOS

systemctl enable -q --now mylar >> ${log} 2>&1
echo_progress_done "Mylar started"
echo_success "Mylar installed"
touch /install/.mylar.lock
