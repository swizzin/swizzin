#!/bin/bash
#
# x2go installer
#
# Originally written for QuickBox.io by liara
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################
function _x2gorepo() {
if [[ $distribution == Ubuntu ]]; then
	apt-get install -q -y software-properties-common > /dev/null 2>&1
	apt-add-repository ppa:x2go/stable -y >/dev/null 2>&1
	apt-get -y update >/dev/null 2>&1
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

apt-get -y update >/dev/null 2>&1
if [[ $release == "jessie" ]]; then
	gpg --keyserver keys.gnupg.net --recv E1F958385BFE2B6E >/dev/null 2>&1
	gpg --export E1F958385BFE2B6E > /etc/apt/trusted.gpg.d/x2go.gpg
else
  apt-key --keyring /etc/apt/trusted.gpg.d/x2go.gpg adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1F958385BFE2B6E > /dev/null 2>&1
fi

apt-get -y update >/dev/null 2>&1
apt-get -y install x2go-keyring >/dev/null 2>&1 && apt-get update >/dev/null 2>&1
fi
}
function _x2go() {
		_x2gorepo
			apt-get -y install x2goserver x2goserver-xsession >/dev/null 2>&1
			apt-get -y install pulseaudio >/dev/null 2>&1
			apt-get -y install iceweasel >/dev/null 2>&1
		echo ${ok}
}

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
distribution=$(lsb_release -is)
release=$(lsb_release -cs)
ok=$(echo -e "[ \e[0;32mDONE\e[00m ]")
echo -n "Installing Xfce4 (this may take a bit) ... " >>"${OUTTO}" 2>&1;apt-get install -y xfce4 >/dev/null 2>&1
echo >>"${OUTTO}" 2>&1;
echo -n "Installing x2go repositories ... " >>"${OUTTO}" 2>&1; _x2gorepo
echo >>"${OUTTO}" 2>&1;
echo -n "Installing X2go (this may take a bit) ... " >>"${OUTTO}" 2>&1; _x2go
touch /install/.x2go.lock
echo >>"${OUTTO}" 2>&1;
echo "X2go Install Complete!" >>"${OUTTO}" 2>&1;
sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
