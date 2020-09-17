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
            Yes ) migrate=True; break;;
            No ) migrate=False; break;;
        esac
    done
fi

. /etc/swizzin/sources/functions/utils

username=$(_get_master_username)

echo "Checking depends ..."
LIST='default-jre-headless unzip'

apt-get -y update >>"${log}" 2>&1
for depend in $LIST; do
  apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
done

if [[ $migrate == True ]]; then
    version="2.10.2"
    cd /opt
    mkdir nzbhydra2
    cd nzbhydra2
    wget -qO nzbhydra2.zip https://github.com/theotherp/nzbhydra2/releases/download/v${version}/nzbhydra2-${version}-linux.zip
    unzip nzbhydra2.zip
    chmod +x nzbhydra2
    chown -R ${username}: /opt/nzbhydra2
    ./nzbhydra2 --daemon --datadir /home/${username}/.config/nzbhydra2