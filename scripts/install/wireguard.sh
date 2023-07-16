#!/bin/bash
# Guard yer wires with wireguard vpn
# Author: liara
# swizzin Copyright (C) 2018 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

function _defiface_confirm() {
    echo_query "Setup has detected that $defiface is your main interface, is this correct?" ""
    select yn in "yes" "no"; do
        case $yn in
            yes)
                wgiface=$defiface
                break
                ;;
            no)
                _selectiface
                break
                ;;
        esac
    done
}

function _selectiface() {
    echo_query "Please choose the correct interface from the following list:" ""
    select seliface in "${IFACES[@]}"; do
        case $seliface in
            *)
                wgiface=$seliface
                break
                ;;
        esac
    done
    # echo "Your interface has been set as $wgiface"
    # echo "Groovy. Please wait a few moments while wireguard is installed ..."
}

function _install_wg() {

    case ${codename} in
        buster)
            check_debian_backports
            PKGS+=(wireguard-dkms qrencode iptables)
            ;;
        *)
            PKGS=(wireguard qrencode iptables)
            ;;
    esac

    apt_update
    apt_install --recommends ${PKGS[@]}

    if [[ ! -d /etc/wireguard ]]; then
        mkdir /etc/wireguard
    fi

    chown -R root:root /etc/wireguard/
    chmod -R 700 /etc/wireguard

    if ! modprobe wireguard >> $log 2>&1; then
        echo_error "Could not modprobe Wireguard, script will now terminate."
        echo_info "Please ensure a kernel headers package is installed that matches the currently running kernel.
Currently running kernel:
$(uname -r)
Installed kernel headers: 
$(dpkg -l | awk '{print $2}' | grep headers | grep amd64 | grep -v linux-headers-amd64 | sed 's/^/  '/g)

You may be able to resolve this error with \`apt install linux-headers-$(uname -r)\` or a system reboot. If you are using a custom kernel, your package names may differ.
Please consult the swizzin log for further info if required."
        exit 1
    fi
    systemctl daemon-reload -q
    echo_progress_done

    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    echo "$wgiface" > /install/.wireguard.lock
    touch /install/.wireguard.lock
}

function _mkconf_wg() {
    echo_progress_start "Configuring Wireguard for $u"

    mkdir -p /home/$u/.wireguard/{server,client}

    cd /home/$u/.wireguard/server
    wg genkey | tee wg$(id -u $u).key | wg pubkey > wg$(id -u $u).pub

    cd /home/$u/.wireguard/client
    wg genkey | tee $u.key | wg pubkey > $u.pub

    chown $u: /home/$u/.wireguard
    chmod -R 700 /home/$u/.wireguard

    serverpriv=$(cat /home/$u/.wireguard/server/wg$(id -u $u).key)
    serverpub=$(cat /home/$u/.wireguard/server/wg$(id -u $u).pub)
    peerpriv=$(cat /home/$u/.wireguard/client/$u.key)
    peerpub=$(cat /home/$u/.wireguard/client/$u.pub)

    net=$(id -u $u | cut -c 1-3)
    sub=$(id -u $u | rev | cut -c 1 | rev)
    subnet=10.$net.$sub.
    cat > /etc/wireguard/wg$(id -u $u).conf << EOWGS
[Interface]
Address = ${subnet}1
SaveConfig = true
PostUp = iptables -A FORWARD -i wg$(id -u $u) -j ACCEPT; iptables -A FORWARD -i wg$(id -u $u) -o $wgiface -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -A FORWARD -i $wgiface -o wg$(id -u $u) -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o $wgiface -s ${subnet}0/24 -j SNAT --to-source $ip
PostDown = iptables -D FORWARD -i wg$(id -u $u) -j ACCEPT; iptables -D FORWARD -i wg$(id -u $u) -o $wgiface -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -D FORWARD -i $wgiface -o wg$(id -u $u) -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -o $wgiface -s ${subnet}0/24 -j SNAT --to-source $ip
ListenPort = 5$(id -u $u)
PrivateKey = $serverpriv

[Peer]
PublicKey = $peerpub
AllowedIPs = ${subnet}2/32
EOWGS

    #[Interface]
    #Address = ${subnet}1
    #PrivateKey = $serverpriv
    #ListenPort = 5$(id -u $u)

    #[Peer]
    #PublicKey = $peerpub
    #AllowedIPs = ${subnet}2/32

    cat > /home/$u/.wireguard/$u.conf << EOWGC
[Interface]
Address = ${subnet}2/24
PrivateKey = $peerpriv
ListenPort = 21841
# The DNS value may be changed if you have a personal preference
DNS = 1.1.1.1
# Uncomment this line if you are having issues with DNS leak
#BlockDNS = true


[Peer]
PublicKey = $serverpub
Endpoint = $ip:5$(id -u $u)
AllowedIPs = 0.0.0.0/0

# This is for if you're behind a NAT and
# want the connection to be kept alive.
#PersistentKeepalive = 25
EOWGC

    chown -R "$u": /home/"$u"/.wireguard

    systemctl enable -q --now wg-quick@wg$(id -u $u) 2>&1 | tee -a $log
    if [[ $? == 0 ]]; then
        echo_progress_done "Enabled for $u (wg$(id -u $u)). Config stored in /home/$u/.wireguard/$u.conf"
    else
        echo_error "Configuration for $u failed"
    fi
}

# shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/backports

distribution=$(_os_distro)
codename=$(_os_codename)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
if [[ -f /install/.wireguard.lock ]]; then
    wgiface=$(cat /install/.wireguard.lock)
fi
if [[ -z $wgiface ]]; then
    defiface=$(route | grep '^default' | grep -o '[^ ]*$')
    IFACES=($(ip link show | grep -i broadcast | grep UP | grep qlen | cut -d: -f 2 | cut -d@ -f 1 | sed -e 's/ //g'))
    #MASTER=$(ip link show | grep -i broadcast | grep -e MASTER | cut -d: -f 2| cut -d@ -f 1 | sed -e 's/ //g')
    _defiface_confirm
    if [[ -f /install/.wireguard.lock ]]; then echo $wgiface > /install/.wireguard.lock; fi
fi

#When a new user is being installed
if [[ -n $1 ]]; then
    u=$1
    _mkconf_wg
    exit 0
fi

_install_wg

users=($(_get_user_list))
for u in ${users[@]}; do
    _mkconf_wg
done
masteruser=$(_get_master_username)
echo_info "Configuration QR code can be generated with the following command:\n${bold}qrencode -t ansiutf8 < /home/$masteruser/.wireguard/$masteruser.conf"
