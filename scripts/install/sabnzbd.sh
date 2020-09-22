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
#latest=$(curl -s https://sabnzbd.org/downloads | grep -m1 Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
latest=$(curl -sL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | grep -Po '(?<="browser_download_url":).*?[^\\].tar.gz"' | sed 's/"//g')
latestversion=$(echo $latest | awk -F "/" '{print $NF}' | cut -d- -f2)

. /etc/swizzin/sources/functions/pyenv
. /etc/swizzin/sources/functions/utils

LIST='par2 p7zip-full python3-dev python3-setuptools python3-pip python3-venv libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'

apt_install $LIST

python3_venv ${user} sabnzbd

install_rar

echo_progress_start "Downloading and extracting sabnzbd"
cd /opt
mkdir -p /opt/sabnzbd
wget -O sabnzbd.tar.gz $latest >> $log 2>&1
tar xzf sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd >> ${log} 2>&1
rm -rf sabnzbd.tar.gz
echo_progress_done

echo_progress_start "Installing pip requirements"
if [[ $latestversion =~ ^3\.0\.[1-2] ]]; then
    sed -i "s/feedparser.*/feedparser<6.0.0/g" /opt/sabnzbd/requirements.txt
fi
/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt >>"${log}" 2>&1
echo_progress_done

chown -R ${user}: /opt/.venv/sabnzbd
mkdir -p /home/${user}/.config/sabnzbd
mkdir -p /home/${user}/Downloads/{complete,incomplete}
chown -R ${user}: /opt/sabnzbd
chown ${user}: /home/${user}/.config
chown -R ${user}: /home/${user}/.config/sabnzbd
chown ${user}: /home/${user}/Downloads
chown ${user}: /home/${user}/Downloads/{complete,incomplete}

echo_progress_start "Installing systemd service"
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

systemctl enable -q --now sabnzbd 2>&1  | tee -a $log
sleep 2
echo_progress_done "SABnzbd started"

echo_progress_start "Configuring SABnzbd"
systemctl stop sabnzbd >> ${log} 2>&1
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
echo_progress_done


if [[ -f /install/.nginx.lock ]]; then
echo_progress_start "Configuring Nginx"
  bash /usr/local/bin/swizzin/nginx/sabnzbd.sh
  systemctl reload nginx
  echo_progress_done
fi

echo_success "Sabnzbd installed"
touch /install/.sabnzbd.lock
