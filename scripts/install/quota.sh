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

green=$(tput setaf 2); yellow=$(tput setaf 3);
bold=$(tput bold); normal=$(tput sgr0); alert=${white}${on_red}; title=${standout};

  echo
  echo "##################################################################################"
  echo "#${bold} By default the quota script will use ${green}/${normal} ${bold}as the${normal}"
  echo "#${bold} primary partition for mounting quotas.${normal}"
  echo "#"
  echo "#${bold} Some providers, such as OVH and SYS force ${green}/home${normal} ${bold}as the primary mount ${normal}"
  echo "#${bold} on their server setups. So if you have an OVH or SYS server and have not"
  echo "#${bold} modified your partitions, it is safe to choose option ${yellow}2)${normal} ${bold}below.${normal}"
  echo "#"
  echo "#${bold} If you are not sure:${normal}"
  echo "#${bold} I have listed out your current partitions below. Your mountpoint will be"
  echo "#${bold} listed as ${green}/home${normal} ${bold}or ${green}/${normal}${bold}. ${normal}"
  echo "#"
  echo "#${bold} Typically, the partition with the most space assigned is your default.${normal}"
  echo "##################################################################################"
  echo
  lsblk
  echo
  echo -e "${bold}${yellow}1)${normal} / - ${green}root mount${normal}"
  echo -e "${bold}${yellow}2)${normal} /home - ${green}home mount${normal}"
  echo -ne "${bold}${yellow}What is your mount point for user quotas?${normal} (Default ${green}1${normal}): "; read version
  case $version in
    1 | "") primaryroot=root  ;;
    2) primaryroot=home  ;;
    *) primaryroot=root ;;
  esac
  echo "Using ${green}$primaryroot mount${normal} for quotas"
  echo

function _installquota(){
  apt-get install -y -q quota >/dev/null 2>&1
  if [[ ${primaryroot} == "root" ]]; then   
    loc=$(echo -e "/\t")
    loc2="/ "
  elif [[ ${primaryroot} == "home" ]]; then
    loc=$(echo -e "/home\t")
    loc2="/home "
  fi
  hook=$(grep "${loc}" /etc/fstab)
  hook2=$(grep "${loc2}" /etc/fstab)

  if [[ -z $hook ]]; then
    if [[ -z $hook2 ]]; then
      echo "ERROR: Cannot determine $primaryroot mount point. Installer cannot continue."
      exit 1
    fi
    hook=$hook2
    loc=$loc2
  fi

  if [[ -n $(echo $hook | grep defaults) ]]; then
    hook=defaults
  elif [[ -n $(echo $hook | grep errors=remount-ro) ]]; then
    hook=errors=remount-ro
  else
    echo "ERROR: Could not find a hook in /etc/fstab for quotas to install to. Quota requires either defaults or errors=remount-ro to be present as a mount option for the intended quota partition."
    exit 1
  fi

  if [[ $DISTRO == Ubuntu ]]; then
    sed -ie '/\'"${loc}"'/ s/'${hook}'/'${hook}',usrjquota=aquota.user,jqfmt=vfsv1/' /etc/fstab
    apt-get install -y linux-image-extra-virtual quota >>"${OUTTO}" 2>&1
    mount -o remount ${loc} >>"${OUTTO}" 2>&1
    quotacheck -auMF vfsv1 >>"${OUTTO}" 2>&1
    quotaon -uv / >>"${OUTTO}" 2>&1
    service quota start >>"${OUTTO}" 2>&1
  elif [[ $DISTRO == Debian ]]; then
    sed -ie '/\'"${loc}"'/ s/'${hook}'/'${hook}',usrjquota=aquota.user,jqfmt=vfsv1/' /etc/fstab
    apt-get install -y quota >>"${OUTTO}" 2>&1
    mount -o remount ${loc} >>"${OUTTO}" 2>&1
    quotacheck -auMF vfsv1 >>"${OUTTO}" 2>&1
    quotaon -uv / >>"${OUTTO}" 2>&1
    service quota start >>"${OUTTO}" 2>&1
  fi

  if [[ -d /srv/rutorrent ]]; then
    cat > /srv/rutorrent/plugins/diskspace/action.php <<'DSKSP'
<?php
#################################################################################
##  [Quick Box - action.php modified for quota systems use]
#################################################################################
# QUICKLAB REPOS
# QuickLab _ packages:   https://github.com/QuickBox/quickbox_rutorrent-plugins
# LOCAL REPOS
# Local _ packages   :   ~/QuickBox/rtplugins
# Author             :   QuickBox.IO
# URL                :   https://plaza.quickbox.io
#
#################################################################################
  require_once( '../../php/util.php' );
  if (isset($quotaUser) && file_exists('/install/.quota.lock')) {
    $total = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $3*1024}'");
    $used = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $2*1024}'");
    $free = sprintf($total - $used);
    cachedEcho('{ "total": '.$total.', "free": '.$free.' }',"application/json");
  } else {
      cachedEcho('{ "total": '.disk_total_space($topDirectory).', "free": '.disk_free_space($topDirectory).' }',"application/json");
  }
?>
DSKSP
if [[ $primaryroot == "root" ]]; then
    sed -i 's/MOUNT/\//g' /srv/rutorrent/plugins/diskspace/action.php
elif [[ $primaryroot == "home" ]]; then
    sed -i 's/MOUNT/\/home/g' /srv/rutorrent/plugins/diskspace/action.php
fi

fi
}


if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
DISTRO=$(lsb_release -is)


_installquota

touch /install/.quota.lock
echo "${primaryroot}" > /install/.quota.lock

echo "Quotas have been installed. Use the command setdisk to set quotas per user."