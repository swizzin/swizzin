#!/bin/bash
#
# [Quick Box :: Install User Quotas]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
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

function _installquota(){
  apt-get install -y -q quota >/dev/null 2>&1
  if [[ $DISTRO == Ubuntu ]]; then
    if [[ ${primaryroot} == "root" ]]; then
      sed -i 's/errors=remount-ro/usrjquota=aquota.user,jqfmt=vfsv1,errors=remount-ro/g' /etc/fstab
      apt-get install -y linux-image-extra-virtual quota >>"${OUTTO}" 2>&1
      mount -o remount / || mount -o remount /home >>"${OUTTO}" 2>&1
      quotacheck -auMF vfsv1 >>"${OUTTO}" 2>&1
      quotaon -uv / >>"${OUTTO}" 2>&1
      service quota start >>"${OUTTO}" 2>&1
    else
      sed -i 's/errors=remount-ro/usrjquota=aquota.user,jqfmt=vfsv1,errors=remount-ro/g' /etc/fstab
      apt-get install -y linux-image-extra-virtual quota >>"${OUTTO}" 2>&1
      mount -o remount /home >>"${OUTTO}" 2>&1
      quotacheck -auMF vfsv1 >>"${OUTTO}" 2>&1
      quotaon -uv /home >>"${OUTTO}" 2>&1
      service quota start >>"${OUTTO}" 2>&1
    fi
  elif [[ $DISTRO == Debian ]]; then
    if [[ ${primaryroot} == "root" ]]; then
      sed -i 's/errors=remount-ro/usrjquota=aquota.user,jqfmt=vfsv1,errors=remount-ro/g' /etc/fstab
      apt-get install -y quota >>"${OUTTO}" 2>&1
      mount -o remount / || mount -o remount /home >>"${OUTTO}" 2>&1
      quotacheck -auMF vfsv1 >>"${OUTTO}" 2>&1
      quotaon -uv / >>"${OUTTO}" 2>&1
      service quota start >>"${OUTTO}" 2>&1
    else
      sed -i 's/errors=remount-ro/usrjquota=aquota.user,jqfmt=vfsv1,errors=remount-ro/g' /etc/fstab
      apt-get install -y quota >>"${OUTTO}" 2>&1
      mount -o remount /home >>"${OUTTO}" 2>&1
      quotacheck -auMF vfsv1 >>"${OUTTO}" 2>&1
      quotaon -uv /home >>"${OUTTO}" 2>&1
      service quota start >>"${OUTTO}" 2>&1
    fi
  fi
  touch /install/.quota.lock
}


OUTTO=/srv/rutorrent/home/db/output.log
DISTRO=$(lsb_release -is)
primaryroot=root

function _installquota2(){
  echo "Quota Install Complete!" >>"${OUTTO}" 2>&1;
  sleep 5
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
  exit
}
echo "Installing quotas ... " >>"${OUTTO}" 2>&1;_installquota
_installquota2
