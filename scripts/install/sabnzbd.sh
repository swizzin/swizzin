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
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv
#
user="$(_get_master_username)"
password="$(_get_user_password "$user")"
#
latestversion=$(git ls-remote -t --sort=-v:refname --refs https://github.com/sabnzbd/sabnzbd.git | awk '{sub("refs/tags/", "");sub("(.*)(RC|Alpha|Beta|Final)(.*)", ""); print $2 }' | awk '!/^$/' | head -n1)
latest="https://github.com/sabnzbd/sabnzbd/releases/download/${latestversion}/SABnzbd-${latestversion}-src.tar.gz"

apt_install par2 p7zip-full python3-dev python3-setuptools python3-pip python3-venv libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev

python3_venv "${user}" sabnzbd

[[ "$(_os_distro)" == 'ubuntu' ]] && install_rar
[[ "$(_os_distro)" == 'debian' ]] && _rar

echo_progress_start "Downloading and extracting sabnzbd"
cd /opt || exit 1
mkdir -p /opt/sabnzbd
_cmd_log wget -O sabnzbd.tar.gz "${latest}"
_cmd_log tar xzf sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd
rm -rf sabnzbd.tar.gz
echo_progress_done

echo_progress_start "Installing pip requirements"
if [[ "${latestversion}" =~ ^3\.0\.[1-2] ]]; then
    sed -i "s/feedparser.*/feedparser<6.0.0/g" /opt/sabnzbd/requirements.txt
fi

_cmd_log /opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt

echo_progress_done

chown -R "${user}:" /opt/.venv/sabnzbd
chown -R "${user}:" /opt/sabnzbd

mkdir -p "/home/${user}/.config/sabnzbd"
mkdir -p "/home/${user}/Downloads/"{complete,incomplete}

chown -R "${user}:" "/home/${user}/Downloads"

echo_progress_start "Configuring SABnzbd"
cat > "/home/${user}/.config/sabnzbd/sabnzbd.ini" << SAB_INI
[misc]
host_whitelist = $(hostname -f), $(hostname)
host = 0.0.0.0
port = 65080
download_dir = /home/${user}/Downloads/incomplete
complete_dir = /home/${user}/Downloads/complete
ionice = -c2 -n5
par_option = -t4
nice = -n10
pause_on_post_processing = 1
enable_all_par = 1
direct_unpack_threads = 1
password = "${password}"
username = "${user}"
SAB_INI

chown -R "${user}:" "/home/${user}/.config"
chmod 700 "/home/${user}/.config/sabnzbd/sabnzbd.ini"
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring Nginx"
    bash /usr/local/bin/swizzin/nginx/sabnzbd.sh
    _cmd_log systemctl reload nginx
    echo_progress_done
fi

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/sabnzbd.service << SAB_SERVICE
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
SAB_SERVICE
echo_progress_done

_cmd_log systemctl enable -q --now sabnzbd

echo_success "Sabnzbd installed"

touch "/install/.sabnzbd.lock"
