username="$(cat /root/.master.info | cut -d: -f1)"

function remove_filebrowser() {
	systemctl stop "filebrowser@${username}.service"
	#
	systemctl disable "filebrowser@${username}.service"
	#
	rm -f "/etc/systemd/system/filebrowser@${username}.service"
	#
	kill -9 $(ps xU ${username} | grep "/home/${username}/bin/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db$" | awk '{print $1}') >/dev/null 2>&1
	#
	rm -f "/home/${username}/bin/filebrowser"
	rm -rf "/home/${username}/.config/Filebrowser"
	rm -f "/etc/nginx/apps/filebrowser.conf"
	rm -f "/install/.filebrowser.lock"
	#
	service nginx reload
}

remove_filebrowser