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
