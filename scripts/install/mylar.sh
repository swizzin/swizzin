#!/bin/bash
# Mylar Installer for Swizzin
# Author: Public920

if [[ -f /tmp/.install.lock ]]; then
    log="/root/logs/install.log"
else
    log="/root/logs/swizzin.log"
fi

user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)
. /etc/swizzin/sources/functions/pyenv

if [[ $codename =~ ("xenial"|"bionic"|"stretch") ]]; then
    LIST='git build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl libbz2-dev'
else
    LIST='git python3-dev python3-pip'
fi

apt-get -y update >>"$log" 2>&1
for depend in $LIST; do
    apt-get -qq -y install $depend >>"$log" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
done

if [[ $codename =~ ("xenial"|"bionic"|"stretch") ]]; then
    cd /tmp
    curl -O https://www.python.org/ftp/python/3.8.1/Python-3.8.1.tar.xz
    tar -xf Python-3.8.1.tar.xz
    cd Python-3.8.1
    make
    make install

    python3_getpip
fi

git clone https://github.com/mylar3/mylar3.git /opt/mylar >>"$log" 2>&1
pip install -r /opt/mylar/requirements.txt >>"$log" 2>&1

chown -R $user: /opt/mylar

cat > /etc/systemd/system/mylar.service <<MYLRSD
[Unit]
Description=Mylar
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=python3 /opt/mylar/Mylar.py -d --pidfile /run/${user}/mylar.pid --datadir /opt/mylar --nolaunch --config /opt/mylar/config.ini --port 8090
PIDFile=/run/${user}/mylar.pid


[Install]
WantedBy=multi-user.target
MYLRSD

systemctl enable --now mylar >>$log 2>&1
sleep 10

if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/mylar.sh
    systemctl reload nginx
    echo "Install complete! Please note Mylar access url is: https://$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')/mylar/home"
fi

touch /install/.mylar.lock
