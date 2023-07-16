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

distribution=$(lsb_release -is)
release=$(lsb_release -cs)
echo_info "Please note that both xfce4 and x2go are VERY heavy packages to install and will take quite some time. If you're concerned whether the install is still running or not, please inspect the swizzin log through another session by running \`tail -f /root/logs/swizzin.log\`"

apt_install xfce4
#disable lightdm because it causes suspend issues on Ubuntu
systemctl disable --now lightdm >> ${log} 2>&1

echo_progress_start "Installing x2go repositories ... "

if [[ $distribution == Ubuntu ]]; then
    apt_install software-properties-common
    apt-add-repository ppa:x2go/stable -y >> ${log} 2>&1
    echo_progress_done "Repos installed via PPA"
    apt_update
else
    cat > /etc/apt/sources.list.d/x2go.list << EOF
# X2Go Repository (release builds)
deb [signed-by=/usr/share/keyrings/x2go-archive-keyring.gpg] http://packages.x2go.org/debian ${release} main
# X2Go Repository (sources of release builds)
deb-src [signed-by=/usr/share/keyrings/x2go-archive-keyring.gpg] http://packages.x2go.org/debian ${release} main

# X2Go Repository (nightly builds)
#deb [signed-by=/usr/share/keyrings/x2go-archive-keyring.gpg] http://packages.x2go.org/debian ${release} heuler
# X2Go Repository (sources of nightly builds)
#deb-src [signed-by=/usr/share/keyrings/x2go-archive-keyring.gpg] http://packages.x2go.org/debian ${release} heuler
EOF
    echo_progress_done "Repo added"
    mkdir -m 700 /root/.gnupg
    gpg --no-default-keyring --keyring /usr/share/keyrings/x2go-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1F958385BFE2B6E >> ${log} 2>&1
    apt_update
    apt_install x2go-keyring
fi

apt_install x2goserver x2goserver-xsession pulseaudio

touch /install/.x2go.lock
