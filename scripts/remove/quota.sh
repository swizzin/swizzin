#!/bin/bash
#
# [Quick Box :: Remove quotas]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | liara
# URL                :   https://quickbox.io
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
username=$(cut -d: -f1 < /root/.master.info)

sed -i 's/,usrjquota=aquota.user,jqfmt=vfsv1//g' /etc/fstab
apt_remove quota
rm /etc/sudoers.d/quota
rm /install/.quota.lock
