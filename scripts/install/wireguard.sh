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

if [[ -f /tmp/.install.lock ]]; then
	log="/root/logs/install.log"
else
	log="/root/logs/swizzin.log"
fi

distribution=$(lsb_release -is)
codename=$(lsb_release -cs)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
IFACE=($(ip link show|grep -i broadcast|grep -m1 UP |cut -d: -f 2|cut -d@ -f 1|sed -e 's/ //g'))
MASTER=$(ip link show|grep -i broadcast|grep -e MASTER |cut -d: -f 2|cut -d@ -f 1|sed -e 's/ //g')

function _install_wg () {

	if [[ -n $MASTER ]]; then
		iface=$MASTER
	else
		iface=${IFACE[0]}
	fi

	echo "Setup has detected that $iface is your main interface, is this correct?"
	select yn in "yes" "no"; do
		case $yn in
			yes ) break;;
			no ) _selectiface; break;;
		esac
	done

	if [[ $distribution == "Debian" ]]; then
		echo "Adding Wireguard repoository"
		echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable.list
		printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n\nPackage: *\nPin: release a=stretch-backports\nPin-Priority: 250' > /etc/apt/preferences.d/limit-unstable
	elif [[ $codename =~ ("bionic"|"xenial") ]]; then
		echo "Adding Wireguard PPA"
		add-apt-repository -y ppa:wireguard/wireguard >> $log 2>&1
	fi

	echo "Fetching APT updates"
	apt_update
	echo "Installing Wireguard from APT"
	apt_install wireguard qrencode


	if [[ ! -d /etc/wireguard ]]; then
		mkdir /etc/wireguard
	fi

	chown -R root:root /etc/wireguard/
	chmod -R 700 /etc/wireguard
	# echo ""
	modprobe wireguard >> $log 2>&1

	if [[ $? != "0" ]]; then
		echo "Could not modprobe Wireguard, script will now terminate."
		echo "Please consult the swizzin log."
		exit 1
	fi
	
	systemctl daemon-reload >> $log 2>&1

	echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
	sysctl -p > /dev/null 2>&1

	touch /install/.wireguard.lock
}

function _selectiface () {
	echo "Please choose the correct interface from the following list:"
	select seliface in "${IFACE[@]}"; do
		case $seliface in
		*) iface=$seliface; break;;
		esac
	done
	echo "Your interface has been set as $iface"
	echo "Groovy. Please wait a few moments while wireguard is installed ..."
}


function _mkconf_wg () {
	echo -n "Configuring Wireguard for $u"

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
	cat > /etc/wireguard/wg$(id -u $u).conf <<EOWGS
[Interface]
Address = ${subnet}1
SaveConfig = true
PostUp = iptables -A FORWARD -i wg$(id -u $u) -j ACCEPT; iptables -A FORWARD -i wg$(id -u $u) -o $iface -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -A FORWARD -i $iface -o wg$(id -u $u) -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o $iface -s ${subnet}0/24 -j SNAT --to-source $ip
PostDown = iptables -D FORWARD -i wg$(id -u $u) -j ACCEPT; iptables -D FORWARD -i wg$(id -u $u) -o $iface -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -D FORWARD -i $iface -o wg$(id -u $u) -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o $iface -s ${subnet}0/24 -j SNAT --to-source $ip
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

	systemctl enable --now wg-quick@wg$(id -u $u) >> $log 2>&1
	if [[ $? == 0 ]]; then 
		echo "  |  Enabled for $u (wg$(id -u $u)). Config stored in /home/$u/.wireguard/$u.conf"
	else
		echo "  |  Configuration failed"
	fi
}


# shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

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
echo
echo "Configuration QR code can be generated with the following command:"
masteruser=$(_get_master_username)
echo "  qrencode -t ansiutf8 < /home/$masteruser/.wireguard/$masteruser.conf"
echo