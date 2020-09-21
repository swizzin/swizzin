#!/bin/bash

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

if [[ -d /opt/.venv/nzbhydra ]]; then
    echo "NZBHydra v1 detected. Do you want to migrate data?"
    echo 
    echo "WARN: This process is NOT automatic. You will be prompted for instructions"
    echo "If you select no, a migration will not be attempted but your old data will be left."
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) migrate=True; majorupgrade=True; break;;
            No ) migrate=False; majorupgrade=True; break;;
        esac
    done
fi

. /etc/swizzin/sources/functions/utils

username=$(_get_master_username)
active=$(systemctl is-active nzbhydra)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

echo "Checking depends ..."
LIST='default-jre-headless unzip'
apt_install $LIST

if [[ $migrate == True ]]; then
    version="2.10.2"
    cd /opt
    mkdir nzbhydra2
    cd nzbhydra2
    wget -O nzbhydra2.zip https://github.com/theotherp/nzbhydra2/releases/download/v${version}/nzbhydra2-${version}-linux.zip >> ${log} 2>&1
    unzip nzbhydra2.zip >> ${log} 2>&1
    chmod +x nzbhydra2
    rm -f nzbhydra2.zip
    chown -R ${username}: /opt/nzbhydra2
    sudo -u ${username} bash -c "cd /opt/nzbhydra2; /opt/nzbhydra2/nzbhydra2 --daemon --nobrowser --datafolder /home/${username}/.config/nzbhydra2 --nopidfile"
    if [[ -f /install/.nginx.lock ]]; then
        message="Go to nzbhydra2 (http://${ip}:5076) and follow the migration instructions. When prompted, your old NZBHydra install should be located at http://127.0.0.1:5075/nzbhydra. Press enter once migration is complete."
    else
        message="Go to nzbhydra2 (http://${ip}:5076) and follow the migration instructions. When prompted, your old NZBHydra install should be located at http://127.0.0.1:5075. Press enter once migration is complete."
    fi
    read -p "$message"
    killall nzbhydra2 >> ${log} 2>&1
    echo "Please wait while nzbhydra2 shuts down"
    sleep 10
fi

if [[ $majorupgrade == True ]]; then
    echo "Re-configuring the system for nzbhydra2"
    systemctl stop nzbhydra
    rm_if_exists /etc/nginx/apps/nzbhydra.conf
    rm_if_exists /opt/.venv/nzbhydra
    rm_if_exists /opt/nzbhydra
    cat > /etc/systemd/system/nzbhydra.service <<EOH2
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
ExecStart=/opt/nzbhydra2/nzbhydra2 --nobrowser --datafolder /home/${username}/.config/nzbhydra2 --nopidfile

Restart=always

[Install]
WantedBy=multi-user.target
EOH2
    systemctl daemon-reload
    if [[ -f /install/.nginx.lock ]]; then
        bash /etc/swizzin/scripts/nginx/nzbhydra.sh
        systemctl reload nginx
    fi
fi

localversion=$(/opt/nzbhydra2/nzbhydra2 --version 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+')
latest=$(curl -s https://api.github.com/repos/theotherp/nzbhydra2/releases/latest | grep -E "browser_download_url" | grep linux | head -1 | cut -d\" -f 4)
latestversion=$(echo $latest | grep -oP 'v\d+\.\d+\.\d+')
if [[ -z $localversion ]] || dpkg --compare-versions ${localversion#v} lt ${latestversion#v}; then
    echo "Upgrading NZBHydra to ${latestversion}"
    cd /opt
    rm_if_exists /opt/nzbhydra2
    mkdir nzbhydra2
    cd nzbhydra2
    wget -O nzbhydra2.zip ${latest} >> ${log} 2>&1
    unzip nzbhydra2.zip >> ${log} 2>&1
    rm -f nzbhydra2.zip

    chmod +x nzbhydra2
    chown -R ${username}: /opt/nzbhydra2

    if [[ $active == "active" ]]; then
        systemctl restart nzbhydra
    fi
else
    echo "Installed version (${localversion}) matches latest version (${latestversion})."
    exit 1
fi

if [[ $majorupgrade == True ]]; then
    echo "NZBHydra v1 config files have been left at /home/${username}/.config/nzbhydra"
    echo "Please remove them if they are no longer needed."
fi