#!/bin/bash
#
# Quassel Installer
#
# Originally written for QuickBox.io. Ported to Swizzin
# Author: liara
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

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
else
  OUTTO="/root/logs/swizzin.log"
fi
distribution=$(lsb_release -is)
codename=$(lsb_release -cs)
IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
user=$(cut -d: -f1 < /root/.master.info)

echo "Installing Quassel PPA (Ubuntu) or grabbing latest backport (Debian) ... "

if [[ $distribution == Ubuntu ]]; then
  echo "Installing Quassel PPA"
  apt_install software-properties-common --skip-update
	apt-add-repository ppa:mamarley/quassel -y >/dev/null 2>&1
  apt_update
  apt_install quassel-core
else
  #shellcheck source=sources/functions/backports
  . /etc/swizzin/sources/functions/backports
  if [[ $codename == "buster" ]]; then
    echo "Grabbing latest release"
    apt_install quassel-core
  elif [[ $codename == "stretch" ]]; then
    check_debian_backports
    echo "Grabbing latest backport"
    set_packages_to_backports quassel-core
    apt_install quassel-core
  else
    echo "Grabbing latest backport"
    wget -r -l1 --no-parent --no-directories -A "quassel-core*.deb" https://iskrembilen.com/quassel-packages-debian/ >/dev/null 2>&1
    dpkg -i quassel-core* >/dev/null 2>&1
    rm quassel-core*
    #TODO make an option to pass flags to apt script?
    apt-get install -f -y -q >/dev/null 2>&1
  fi
fi

mv /etc/init.d/quasselcore /etc/init.d/quasselcore.BAK
systemctl enable --now quasselcore

echo "Quassel has now been installed! "
echo "Please install quassel-client on your personal computer "
echo "and connect to the newly created core at "
echo "${IP}:4242 to set up your account"

touch /install/.quassel.lock
