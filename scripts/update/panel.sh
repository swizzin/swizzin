#! /bin/bash

if [[ -f /install/.panel.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    #shellcheck source=sources/functions/pyenv
    . /etc/swizzin/sources/functions/pyenv
    if [[ ! -d /opt/swizzin ]]; then
        echo_progress_start "swizzifying the panel"
        rm_if_exists "/srv/panel"
        rm_if_exists "/etc/cron.d/set_interface"
        rm_if_exists "/etc/nginx/apps/panel.conf"

        bash /usr/local/bin/swizzin/install/panel.sh

        echo_progress_done "Panel has been swizzified"
    else
        echo_progress_start "Updating panel to latest version"
        if [[ -d /opt/swizzin/venv ]]; then
            echo_progress_start "Moving swizzin venv to /opt/.venv"
            mkdir -p /opt/.venv
            python3 -m venv /opt/.venv/swizzin
            rm -rf /opt/swizzin/venv
            mv /opt/swizzin/swizzin/* /opt/swizzin/swizzin/.git /opt/swizzin
            rm_if_exists "/opt/swizzin/swizzin"
            sed -i 's|ExecStart=.*|ExecStart=/opt/.venv/swizzin/bin/python swizzin.py|g' /etc/systemd/system/panel.service
            sed -i 's|WorkingDirectory=.*|WorkingDirectory=/opt/swizzin|g' /etc/systemd/system/panel.service
            systemctl daemon-reload
            echo_progress_done "venv moved"
        fi
        pyminver=3.6.0
        pyenv_version=$(/opt/.venv/swizzin/bin/python3 --version | awk '{print $2}')

        if dpkg --compare-versions ${pyenv_version} lt ${pyminver}; then
            rm_if_exists "/opt/.venv/swizzin"
            pyenv_install
            pyenv_install_version 3.8.6
            pyenv_create_venv 3.8.6 /opt/.venv/swizzin
            chown -R swizzin: /opt/.venv/swizzin
        fi
        chown -R swizzin: /opt/swizzin
        chown -R swizzin: /opt/.venv/swizzin
        bash /usr/local/bin/swizzin/upgrade/panel.sh
        echo_progress_done
    fi
    if ! grep -q SYSDCMNDS /etc/sudoers.d/panel; then
        cat > /etc/sudoers.d/panel << EOSUD
#Defaults  env_keep -="HOME"
Defaults:swizzin !logfile
Defaults:swizzin !syslog
Defaults:swizzin !pam_session

Cmnd_Alias   CMNDS = /usr/bin/quota
Cmnd_Alias   SYSDCMNDS = /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *, /bin/systemctl disable *, /bin/systemctl enable *

swizzin     ALL = (ALL) NOPASSWD: CMNDS, SYSDCMNDS
EOSUD
    fi
    if grep -q -E "swizzin.*/bin/sh" /etc/passwd; then
        usermod swizzin -s /usr/sbin/nologin
    fi
fi
