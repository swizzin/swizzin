#!/bin/bash
#
# x2go installer
#
# Author: liara
#
# swizzin Copyright (C) 2019
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

distribution=$(lsb_release -is)
release=$(lsb_release -cs)
echo "Installing Xfce4 (this may take a bit) ... "
apt_install xfce4
#disable lightdm because it causes suspend issues on Ubuntu
systemctl disable --now lightdm >> ${log} 2>&1

echo "Installing x2go repositories ... "

if [[ $distribution == Ubuntu ]]; then
	apt_install software-properties-common
	apt-add-repository ppa:x2go/stable -y >> ${log} 2>&1
	apt_update
else

cat >/etc/apt/sources.list.d/x2go.list<<EOF
# X2Go Repository (release builds)
deb http://packages.x2go.org/debian ${release} main
# X2Go Repository (sources of release builds)
deb-src http://packages.x2go.org/debian ${release} main

# X2Go Repository (nightly builds)
#deb http://packages.x2go.org/debian ${release} heuler
# X2Go Repository (sources of nightly builds)
#deb-src http://packages.x2go.org/debian ${release} heuler
EOF

apt_update
apt-key --keyring /etc/apt/trusted.gpg.d/x2go.gpg adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1F958385BFE2B6E >> ${log} 2>&1

apt_update
apt_install x2go-keyring
fi

echo "Installing X2go (this may take a bit) ... "
apt_update
apt_install x2goserver x2goserver-xsession pulseaudio

touch /install/.x2go.lock