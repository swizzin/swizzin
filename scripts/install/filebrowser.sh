#!/usr/bin/env bash
#
# authors: liara userdocs
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
########
######## Global Variables Start
########
#
distribution="$(lsb_release -is)"
version="$(lsb_release -cs)"
#
username="$(cat /root/.master.info | cut -d: -f1)"
password="$(cat /root/.master.info | cut -d: -f2)"
userid="$(cat /proc/sys/kernel/random/uuid)"
dbpass="$(echo -n "$password" | sha256sum | awk '{print $1}')"
#
# This will generate a random port for the script between the range 10001 to 32001 to use with applications. You can ignore this unless needed.
app_port_http="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_http}"'')" -ge "1" ]]; do app_port_http="$(shuf -i 10001-32001 -n 1)"; done
app_port_https="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_https}"'')" -ge "1" ]]; do app_port_https="$(shuf -i 10001-32001 -n 1)"; done
#
########
######## Global Variables End
########
#
########
######## Custom Variables Start
########
#
# The name of the application used to configures various aspects of the script.
app_name="filebrowser"
#
# The wget url to download the current version.
app_name_url="$(curl -sNL https://git.io/fxQ38 | grep -Po 'ht(.*)linux-amd64(.*)gz')"
#
# The working directory for the service
working_dir="/home/${username}"
#
# The start up command set in the service.
startup_cmd="/home/${username}/bin/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db"
#
# Path to the directory where the config file will go if applicable.
config_path=""
#
# The path to the configuration file if applicable.
config_file_name=""
#
# Used with the install_application_download function to extract applications to a destination.
install_path="/home/${username}/bin"
#
# Used to remove top levels of directories from archives.
tar_strip_depth="0"
#
# Used to exclude files from extraction.
tar_exclude="--exclude LICENSE --exclude README.md"
#
# Does the app require a trailing slash. if yes then use a / here.
trailing=""
#
########
######## Custom Functions Start
########
#
function install_application () {
	mkdir -p "/home/${username}/bin" > /dev/null 2>&1
	#
	[[ -n "$install_path" ]] && mkdir -p "${install_path}" > /dev/null 2>&1
	#
	wget -qO "/home/${username}/${app_name}.tar.gz" "${app_name_url}" > /dev/null 2>&1
	#
	tar -xvzf "/home/${username}/${app_name}.tar.gz" ${tar_exclude} --strip-components="${tar_strip_depth}" -C "${install_path}" > /dev/null 2>&1
	#
	rm -f "/home/${username}/${app_name}.tar.gz" > /dev/null 2>&1
	#
	[[ -n "$config_path" ]] && mkdir -p "${config_path}" > /dev/null 2>&1
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Installing ${app_name^} files"
	fi
}

function build_application () {
	#
	# commands go here
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Compiling ${app_name^}"
	fi
}

function configure_service () {
	cat > "/etc/systemd/system/${app_name}@${username}.service" <<-SERVICE
	[Unit]
	Description=${app_name}
	After=network.target

	[Service]
	User=${username}
	Group=${username}
	UMask=002

	Type=simple
	WorkingDirectory=${working_dir}
	ExecStart=${startup_cmd}
	TimeoutStopSec=20
	KillMode=process
	Restart=always
	RestartSec=2

	[Install]
	WantedBy=multi-user.target
	SERVICE
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Configuring a service for ${app_name^}"
	fi
}

function configure_nginx () {
	if [[ -f /install/.nginx.lock ]]; then
	  bash "/usr/local/bin/swizzin/nginx/$1.sh" "${app_name}" "${app_port_http}" "${trailing}"
	  service nginx reload
	fi
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Configuring nginx for ${app_name^}"
	fi
}

function configure_application () {
	"/home/${username}/bin/filebrowser" config init -d "/home/${username}/.config/Filebrowser/filebrowser.db" > /dev/null 2>&1
	"/home/${username}/bin/filebrowser" config set -a 127.0.0.1 -p "${app_port_http}" -b /filebrowser -l "/home/${username}/.config/Filebrowser/filebrowser.log" -d "/home/${username}/.config/Filebrowser/filebrowser.db" > /dev/null 2>&1
	"/home/${username}/bin/filebrowser" users add "${username}" "${password}" --perm.admin -d "/home/${username}/.config/Filebrowser/filebrowser.db" > /dev/null 2>&1
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Configuring ${app_name^}"
	fi
}

function finalise () {
	chown "${username}.${username}" -R "/home/${username}/bin" >/dev/null 2>&1
	chown "${username}.${username}" -R "/home/${username}/include" >/dev/null 2>&1
	chown "${username}.${username}" -R "/home/${username}/lib" >/dev/null 2>&1
	chown "${username}.${username}" -R "/home/${username}/share" >/dev/null 2>&1
	chmod 700 /home/${username}/bin/* >/dev/null 2>&1
	chown "${username}.${username}" -R "/home/${username}/.config" >/dev/null 2>&1
	chown "${username}.${username}" -R "/home/${username}/.${app_name}" >/dev/null 2>&1
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Finalising the setup for ${app_name^}"
	fi
}

function startup () {
	systemctl daemon-reload >/dev/null 2>&1
	systemctl enable --now "${app_name}@${username}" >/dev/null 2>&1
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Starting the service for ${app_name^}"
	fi
}

function post_startup () {
	#
	# commands go here
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "Post startup operations for ${app_name^}"
	fi
}

function installed () {
	touch "/install/.${app_name}.lock"
	#
	if [[ "$1" = "quiet" ]]; then
		:
	else
		echo
		echo "${app_name^} Install Complete!"
		echo
	fi
	exit
}
#
########
######## Custom Functions End
########
#
########
######## Installation Start
########
#
install_application
#
build_application quiet
#
configure_application
#
configure_nginx "${app_name}"
#
configure_service
#
finalise
#
startup
#
post_startup quiet
#
installed
