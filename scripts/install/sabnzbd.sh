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

. /etc/swizzin/sources/functions/pyenv
. /etc/swizzin/sources/functions/utils

user=$(_get_master_username)
password="$(_get_user_password ${user})"
latestversion=$(github_latest_version sabnzbd/sabnzbd) || {
    echo_error "Failed to query GitHub for latest sabnzbd version"
    exit 1
}
latest="https://github.com/sabnzbd/sabnzbd/archive/refs/tags/${latestversion}.tar.gz"

systempy3_ver=$(get_candidate_version python3)

#Version 3.5 is going to raise the min python version to 3.7 so we have to differentiate whether or not to build a pyenv
if dpkg --compare-versions ${systempy3_ver} lt 3.7.0 && dpkg --compare-versions ${latestversion} ge 3.5.0; then
    LIST='par2 p7zip-full libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'
    PYENV=True
else
    LIST='par2 p7zip-full python3-dev python3-setuptools python3-pip python3-venv libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'
fi

apt_install $LIST
install_rar

case ${PYENV} in
    True)
        pyenv_install
        pyenv_install_version 3.10.2 # As shipping on Windows/macOS.
        pyenv_create_venv 3.10.2 /opt/.venv/sabnzbd
        chown -R ${user}: /opt/.venv/sabnzbd
        ;;
    *)
        python3_venv ${user} sabnzbd
        ;;
esac

echo_progress_start "Downloading and extracting sabnzbd"
mkdir -p /opt/sabnzbd
wget -O /tmp/sabnzbd.tar.gz "$latest" >> "${log}" 2>&1 || {
    echo_error "Failed to download archive"
    exit 1
}
tar xzf /tmp/sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd >> "${log}" 2>&1
rm -rf /tmp/sabnzbd.tar.gz
echo_progress_done

echo_progress_start "Installing pip requirements"
if [[ $latestversion =~ ^3\.0\.[1-2] ]]; then
    sed -i "s/feedparser.*/feedparser<6.0.0/g" /opt/sabnzbd/requirements.txt
fi

/opt/.venv/sabnzbd/bin/pip install --upgrade pip wheel >> "${log}" 2>&1
/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt >> "${log}" 2>&1
echo_progress_done

chown -R ${user}: /opt/.venv/sabnzbd
mkdir -p /home/${user}/.config/sabnzbd
mkdir -p /home/${user}/Downloads/{complete,incomplete}

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/sabnzbd.service << SABSD
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

echo_progress_start "Configuring SABnzbd"
cat > /home/${user}/.config/sabnzbd/sabnzbd.ini << SAB_INI
[misc]
host_whitelist = $(hostname -f), $(hostname)
host = 0.0.0.0
port = 65080
download_dir = ~/Downloads/incomplete
complete_dir = ~/Downloads/complete
ionice = -c2 -n5
par_option = -t4
nice = -n10
pause_on_post_processing = 1
enable_all_par = 1
direct_unpack_threads = 1
password = "${password}"
username = "${user}"
SAB_INI
chown -R ${user}: /opt/sabnzbd
chown ${user}: /home/${user}/.config
chown -R ${user}: /home/${user}/.config/sabnzbd
chown ${user}: /home/${user}/Downloads
chown ${user}: /home/${user}/Downloads/{complete,incomplete}
echo_progress_done

echo_progress_start "Starting SABnzbd"
systemctl enable -q --now sabnzbd 2>&1 | tee -a "${log}"
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring Nginx"
    bash /usr/local/bin/swizzin/nginx/sabnzbd.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "SabNzbd will run on port 65080"
fi

echo_success "Sabnzbd installed"
touch /install/.sabnzbd.lock
