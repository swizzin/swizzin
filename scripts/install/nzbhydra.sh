#!/bin/bash
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

. /etc/swizzin/sources/functions/utils

case "$(_os_arch)" in
    amd64)
        arch='amd64'
        ;;
    arm64)
        arch="arm64"
        ;;
    *)
        echo_error "Arch not supported for nzbhydra"
        ;;
esac

username=$(_get_master_username)

case $(_os_codename) in
    bullseye)
        java=openjdk-17-jdk-headless
        ;;
    *)
        java=default-jre-headless
        ;;
esac
LIST="unzip $java"
apt_install $LIST

echo_progress_start "Installing NZBHydra ${latestversion}"
latest=$(curl -s https://api.github.com/repos/theotherp/nzbhydra2/releases/latest | grep -E "browser_download_url" | grep linux | grep "$arch" | head -1 | cut -d\" -f 4)
latestversion=$(echo $latest | grep -oP 'v\d+\.\d+\.\d+')
cd /opt
mkdir nzbhydra2
cd nzbhydra2
wget -O nzbhydra2.zip ${latest} >> ${log} 2>&1
unzip nzbhydra2.zip >> ${log} 2>&1
rm -f nzbhydra2.zip

chmod +x nzbhydra2 nzbhydra2wrapperPy3.py
chown -R ${username}: /opt/nzbhydra2
echo_progress_done

if [[ $active == "active" ]]; then
    echo_progress_start "Restarting nzbhydra"
    systemctl restart nzbhydra
    echo_progress_done
fi

mkdir -p /home/${username}/.config/nzbhydra2

chown ${username}: /home/${username}/.config
chown ${username}: /home/${username}/.config/nzbhydra2

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/nzbhydra.service << EOH2
[Unit]
Description=NZBHydra2 Daemon
Documentation=https://github.com/theotherp/nzbhydra2
After=network.target

[Service]
User=${username}
Type=simple
# Set to the folder where you extracted the ZIP
WorkingDirectory=/opt/nzbhydra2


# NZBHydra stores its data in a "data" subfolder of its installation path
# To change that set the --datafolder parameter:
# --datafolder /path-to/datafolder
ExecStart=/opt/nzbhydra2/nzbhydra2wrapperPy3.py --nobrowser --datafolder /home/${username}/.config/nzbhydra2 --nopidfile

Restart=always

[Install]
WantedBy=multi-user.target
EOH2

systemctl enable -q --now nzbhydra 2>&1 | tee -a $log
echo_progress_done "Service installed and nzbhydra started"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    sleep 15
    bash /usr/local/bin/swizzin/nginx/nzbhydra.sh
    systemctl reload nginx
    echo_progress_done "Nginx configured"
else
    echo_info "Nzbhydra will run on port 5076"
fi

echo_success "Nzbhydra installed"
touch /install/.nzbhydra.lock
