#!/bin/bash
#
# Tautulli installer
#
# Author             :   QuickBox.IO | liara
# Ported to swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

. /etc/swizzin/sources/functions/pyenv

user=$(cut -d: -f1 < /root/.master.info)

systempy3_ver=$(get_candidate_version python3)

if dpkg --compare-versions ${systempy3_ver} lt 3.8.0; then
    PYENV=True
else
    LIST='python3-dev python3-setuptools python3-pip python3-venv'
    apt_install $LIST
fi

case ${PYENV} in
    True)
        pyenv_install
        pyenv_install_version 3.11.3
        pyenv_create_venv 3.11.3 /opt/.venv/tautulli
        chown -R tautulli: /opt/.venv/tautulli
        ;;
    *)
        python3_venv tautulli tautulli
        ;;
esac

cd /opt
echo_progress_start "Cloning latest Tautulli repo"
git clone https://github.com/Tautulli/Tautulli.git tautulli >> "${log}" 2>&1
echo_progress_done

echo_progress_start "Adding user and setting up Tautulli"
adduser --system --no-create-home tautulli >> "${log}" 2>&1
chown tautulli:nogroup -R /opt/tautulli
echo_progress_done

echo_progress_start "Enabling Tautulli Systemd configuration"
cat > /etc/systemd/system/tautulli.service << PPY
[Unit]
Description=Tautulli - Stats for Plex Media Server usage
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/.venv/tautulli/bin/python3 /opt/tautulli/Tautulli.py --quiet --daemon --nolaunch --config /opt/tautulli/config.ini --datadir /opt/tautulli
GuessMainPID=no
Type=forking
User=tautulli
Group=nogroup

[Install]
WantedBy=multi-user.target
PPY

systemctl enable -q --now tautulli 2>&1 | tee -a $log

echo_progress_done "Tautulli started"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    while [ ! -f /opt/tautulli/config.ini ]; do
        sleep 2
    done
    bash /usr/local/bin/swizzin/nginx/tautulli.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Tautulli will run on port 8181"
fi
touch /install/.tautulli.lock

echo_success "Tautulli installed"
