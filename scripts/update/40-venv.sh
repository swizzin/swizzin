#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)
if [[ -d /home/${user}/.venv ]]; then
    mv /home/${user}/.venv /opt
    envs=($(ls /opt/.venv))
    for app in ${envs[@]}; do
        mv /home/${user}/${app} /opt
        sed -i "s|/home/${user}|/opt|g" /etc/systemd/system/${app}.service
        sed -i "s|/opt/.config|/home/${user}/.config|g" /etc/systemd/system/${app}.service
        if [[ $app == "pyload" ]]; then
            echo "/opt/pyload" > /opt/pyload/module/config/configdir
        fi
        systemctl daemon-reload
        systemctl try-restart $app
    done
fi

if [[ -d /opt/.venv ]]; then
    envs=($(find /opt/.venv/* -maxdepth 0 -type d))
    for venvpath in ${envs[@]}; do
        if ! grep -q "#\!${venvpath}/bin/python" ${venvpath}/bin/*; then
            echo_log_only "Replacing venv path in $venvpath"
            sed -i "s|#\!/.*/bin/python|#\!${venvpath}/bin/python|g" ${venvpath}/bin/*
        fi
    done
fi
