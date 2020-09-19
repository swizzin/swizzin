#!/bin/bash
#
# Install sabnzbd for swizzin
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

user=$(cut -d: -f1 < /root/.master.info)
password=$(cut -d: -f2 < /root/.master.info)
distribution=$(lsb_release -is)
codename=$(lsb_release -cs)
latest=$(curl -s https://sabnzbd.org/downloads | grep Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
. /etc/swizzin/sources/functions/pyenv
. /etc/swizzin/sources/functions/utils

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi


LIST='par2 p7zip-full python3-venv python3-pip libglib2.0-dev libdbus-1-dev'

apt_install $LIST

python3_venv ${user} sabnzbd

install_rar

cd /opt
mkdir -p /opt/sabnzbd
wget -q -O sabnzbd.tar.gz $latest
tar xzf sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd >> ${log} 2>&1
rm -rf sabnzbd.tar.gz
/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt >>"${log}" 2>&1
chown -R ${user}: /opt/.venv/sabnzbd
mkdir -p /home/${user}/.config/sabnzbd
mkdir -p /home/${user}/Downloads/{complete,incomplete}
chown -R ${user}: /opt/sabnzbd
chown ${user}: /home/${user}/.config
chown -R ${user}: /home/${user}/.config/sabnzbd
chown ${user}: /home/${user}/Downloads
chown ${user}: /home/${user}/Downloads/{complete,incomplete}

cat >/etc/systemd/system/sabnzbd.service<<SABSD
[Unit]
Description=Sabnzbd
Wants=network-online.target
After=network-online.target

[Service]
User=${user}
ExecStart=/opt/.venv/sabnzbd/bin/python /opt/sabnzbd/SABnzbd.py --config-file /home/${user}/.config/sabnzbd/sabnzbd.ini --logging 1
WorkingDirectory=/opt/sabnzbd
Restart=on-failure

[Install]
WantedBy=multi-user.target

SABSD

systemctl enable --now sabnzbd >> ${log} 2>&1
sleep 2
echo "Configuring SABnzbd ... "
systemctl stop sabnzbd
sed -i "s/host_whitelist = .*/host_whitelist = $(hostname -f), $(hostname)/g" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "s|^host = .*|host = 0.0.0.0|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "0,/^port = /s/^port = .*/port = 65080/" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "s|^download_dir = .*|download_dir = ~/Downloads/incomplete|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "s|^complete_dir = .*|complete_dir = ~/Downloads/complete|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
#sed -i "s|^ionice = .*|ionice = -c2 -n5|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
#sed -i "s|^par_option = .*|par_option = -t4|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
#sed -i "s|^nice = .*|nice = -n10|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
#sed -i "s|^pause_on_post_processing = .*|pause_on_post_processing = 1|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
#sed -i "s|^enable_all_par = .*|enable_all_par = 1|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
#sed -i "s|^direct_unpack_threads = .*|direct_unpack_threads = 1|g" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "0,/password = /s/password = .*/password = ${password}/" /home/${user}/.config/sabnzbd/sabnzbd.ini
sed -i "0,/username = /s/username = .*/username = ${user}/" /home/${user}/.config/sabnzbd/sabnzbd.ini
systemctl restart sabnzbd >> ${log} 2>&1


if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sabnzbd.sh
  systemctl reload nginx
fi

touch /install/.sabnzbd.lock
