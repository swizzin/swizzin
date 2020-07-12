#!/bin/bash
distribution=$(lsb_release -is)
codename=$(lsb_release -cs)

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))
for u in ${users[@]}; do
    systemctl disable --now wg-quick@wg$(id -u $u)
    rm -rf /home/$u/.wireguard
done

rm -rf /etc/wireguard/

apt-get -y -q remove wireguard wireguard-tools wireguard-dkms qrencode >> /dev/null 2>&1
apt-get -y -q autoremove >> /dev/null 2>&1

echo "Removing unused repositories"

if [[ $distribution == "Debian" ]]; then
    rm -f /etc/apt/sources.list.d/unstable.list
    rm -f /etc/apt/preferences.d/limit-unstable
elif [[ $codename =~ ("bionic"|"xenial") ]]; then
    add-apt-repository -r -y ppa:wireguard/wireguard >> /dev/null 2>&1
fi

apt-get update -y -q >> /dev/null 2>&1

rm /install/.wireguard.lock
