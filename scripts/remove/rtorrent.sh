#!/bin/bash
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in ${users}; do
    systemctl disable rtorrent@${u}
    systemctl stop rtorrent@{u}
    rm -f /home/${u}/.rtorrent.rc
done

rm -rf /usr/bin/rtorrent
cd /tmp
git clone https://github.com/rakshasa/libtorrent.git libtorrent >>/dev/null 2>&1
cd libtorrent
./autogen.sh
./configure --prefix=/usr
make uninstall
cd -
rm -rf /tmp/libtorrent

#apt-get -y remove mktorrent mediainfo

if [[ -f /install/.nginx.lock ]]; then
    rm -rf /srv/rutorrent
fi

rm /etc/systemd/system/rtorrent@.service
rm /install/.rtorrent.lock