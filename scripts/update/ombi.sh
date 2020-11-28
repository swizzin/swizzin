#!/bin/bash
if [[ -f /install/.ombi.lock ]]; then
	if grep -q "\-\-storage" /etc/systemd/system/ombi.service; then
		:
	else
		sed -i '/^ExecStart=/ s/$/ --storage \/etc\/Ombi/' /etc/systemd/system/ombi.service
		systemctl daemon-reload
		for f in Ombi.db Ombi.db.backup Schedules.db; do
			if [[ -f /opt/Ombi/$f ]]; then
				if [[ /opt/Ombi/$f -nt /etc/Ombi/$f ]] || [[ ! -f /etc/Ombi/$f ]]; then
					cp -a /opt/Ombi/$f /etc/Ombi/$f
				fi
			fi
		done
		if [[ -f /etc/Ombi/Ombi.db ]] && [[ -f /etc/Ombi/Ombi.db.backup ]]; then
			if [[ /etc/Ombi/Ombi.db.backup -nt /etc/Ombi/Ombi.db ]]; then
				mv /etc/Ombi/Ombi.db /etc/Ombi/Ombi.db.backup.swizz
				cp -a /etc/Ombi/Ombi.db.backup /etc/Ombi/Ombi.db
			fi
		fi
		chown -R ombi:nogroup /etc/Ombi
		systemctl try-restart ombi
	fi
fi
