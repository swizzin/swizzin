#! /bin/bash
# shellcheck disable=SC2024
# Webmin installer
# flying_sausages for swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

_install_webmin () {
    echo "Installing Webmin repo"
    echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
    wget http://www.webmin.com/jcameron-key.asc >> $log 2>&1
    sudo apt-key add jcameron-key.asc >> $log 2>&1
    rm jcameron-key.asc
    echo "Fetching updates"
    apt_update
    echo "Installing Webmin from apt"
    apt_install webmin
}

_install_webmin
if [[ -f /install/.nginx.lock ]]; then
  bash /etc/swizzin/scripts/nginx/webmin.sh
fi

echo 
echo "Webmin has been installed, please use any account with sudo permissions to log in"

touch /install/.webmin.lock