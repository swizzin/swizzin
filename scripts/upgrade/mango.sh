#! /bin/bash
# Mango upgrader
# flying_sausages for swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
    log="/root/logs/install.log"
else
    log="/root/logs/swizzin.log"
fi

if [[ ! -f /install/.mango.lock ]]; then
    echo "Mango not installed "
    exit 1
fi

mangodir="/opt/mango"

if [[ $(systemctl is-active mango) == "active" ]]; then
    wasActive="true"
    echo "Shutting down Mango ($($mangodir/mango --version))"
    systemctl stop mango
fi

rm -rf /tmp/mangobak
mkdir /tmp/mangobak
cp -rt /tmp/mangobak $mangodir/mango $mangodir/.config/

echo "Downloading binary" | tee -a $log
dlurl=$(curl -s https://api.github.com/repos/hkalexling/Mango/releases/latest | grep "browser_download_url" | head -1 | cut -d\" -f 4)
# shellcheck disable=SC2181
if [[ $? != 0 ]]; then
    echo "Failed to query github"
    exit 1
fi

wget "${dlurl}" -O $mangodir/mango >> $log 2>&1
chmod +x "$mangodir"/mango

if [[ $wasActive = "true" ]]; then
    echo "Restarting Mango ($($mangodir/mango --version))"
    systemctl start mango
fi