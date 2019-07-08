#!/usr/bin/env bash
#
# authors: liara userdocs
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
########
######## Variables Start
########
#
distribution="$(lsb_release -is)"
version="$(lsb_release -cs)"
#
username="$(cat /root/.master.info | cut -d: -f1)"
password="$(cat /root/.master.info | cut -d: -f2)"
#
# This will generate a random port for the script between the range 10001 to 32001 to use with applications. You can ignore this unless needed.
app_port_http="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_http}"'')" -ge "1" ]]; do app_port_http="$(shuf -i 10001-32001 -n 1)"; done
#
########
######## Variables End
########
#
########
######## Application script starts.
########
#
# Create the required directories for this application.
mkdir -p "/home/${username}/bin"
mkdir -p "/home/${username}/.config/Filebrowser"
#
# Download and extract the files to the desired location.
wget -qO "/home/${username}/filebrowser.tar.gz" "$(curl -sNL https://git.io/fxQ38 | grep -Po 'ht(.*)linux-amd64(.*)gz')" > /dev/null 2>&1
tar -xvzf "/home/${username}/filebrowser.tar.gz" --exclude LICENSE --exclude README.md -C "/home/${username}/bin" > /dev/null 2>&1
#
# Removes the archive as we no longer need it.
rm -f "/home/${username}/filebrowser.tar.gz" > /dev/null 2>&1
#
# Perform some bootstrapping commands on filebrowser to create the database settings we desire.
"/home/${username}/bin/filebrowser" config init -d "/home/${username}/.config/Filebrowser/filebrowser.db" > /dev/null 2>&1
"/home/${username}/bin/filebrowser" config set -a 127.0.0.1 -p "${app_port_http}" -b /filebrowser -l "/home/${username}/.config/Filebrowser/filebrowser.log" -d "/home/${username}/.config/Filebrowser/filebrowser.db" > /dev/null 2>&1
"/home/${username}/bin/filebrowser" users add "${username}" "${password}" --perm.admin -d "/home/${username}/.config/Filebrowser/filebrowser.db" > /dev/null 2>&1
#
# Set the permissions now we are finsished settings filebrowser up.
chown "${username}.${username}" -R "/home/${username}/bin" >/dev/null 2>&1
chown "${username}.${username}" -R "/home/${username}/.config" >/dev/null 2>&1
chmod 700 "/home/${username}/bin/filebrowser" >/dev/null 2>&1
#
# Create the service file that will start and stop filebrowser.
cat > "/etc/systemd/system/filebrowser@${username}.service" <<-SERVICE
[Unit]
Description=filebrowser
After=network.target

[Service]
User=${username}
Group=${username}
UMask=002

Type=simple
WorkingDirectory=/home/${username}
ExecStart=/home/${username}/bin/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db
TimeoutStopSec=20
KillMode=process
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
SERVICE
#
# Configure the nginx proxypass
if [[ -f /install/.nginx.lock ]]; then
  bash "/usr/local/bin/swizzin/nginx/filebrowser.sh" "filebrowser" "${app_port_http}"
  service nginx reload
fi
#
# Start the filebrowser service.
systemctl daemon-reload >/dev/null 2>&1
systemctl enable --now "filebrowser@${username}" >/dev/null 2>&1
#
# This file is created after installtion to prevent reinstalling. You will need to remove the app first which deletes this file.
touch "/install/.filebrowser.lock"
#
# A helpful echo to the terminal.
echo -e "\nThe Filebrowser installation has completed\n"
#
exit
