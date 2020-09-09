#!/bin/bash

if [[ ! -f /install/.filebrowser.lock ]]; then
    echo "Filebrowser does not appear to be installed!"
    exit 1
fi

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  export log="/root/logs/swizzin.log"
fi

. /etc/swizzin/sources/functions/utils
username=$(_get_master_username)

mv /home/${username}/bin/filebrowser /home/${username}/bin/filebrowser.bak
wget -qO "/home/${username}/filebrowser.tar.gz" "$(curl -sNL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -Po 'ht(.*)linux-amd64(.*)gz')" >> ${log} 2>&1
tar -xvzf "/home/${username}/filebrowser.tar.gz" --exclude LICENSE --exclude README.md -C "/home/${username}/bin" >> ${log} 2>&1
rm -f "/home/${username}/filebrowser.tar.gz"
chown $username: "/home/${username}/bin/filebrowser"
chmod 700 "/home/${username}/bin/filebrowser"
if [[ -f /home/${username}/bin/filebrowser ]]; then
    rm /home/${username}/bin/filebrowser.bak
else
    echo "Something went wrong during the upgrade, reverting changes"
    mv /home/${username}/bin/filebrowser.bak /home/${username}/bin/filebrowser
fi
systemctl try-restart filebrowser