#!/bin/bash
#
# [Quick Box :: Install Config Server Firewall package]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################
#Script Console Colors
black=$(tput setaf 0); red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3);
blue=$(tput setaf 4); magenta=$(tput setaf 5); cyan=$(tput setaf 6); white=$(tput setaf 7);
on_red=$(tput setab 1); on_green=$(tput setab 2); on_yellow=$(tput setab 3); on_blue=$(tput setab 4);
on_magenta=$(tput setab 5); on_cyan=$(tput setab 6); on_white=$(tput setab 7); bold=$(tput bold);
dim=$(tput dim); underline=$(tput smul); reset_underline=$(tput rmul); standout=$(tput smso);
reset_standout=$(tput rmso); normal=$(tput sgr0); alert=${white}${on_red}; title=${standout};
sub_title=${bold}${yellow}; repo_title=${black}${on_green};
#################################################################################

function _installCSF() {
  echo "${green}Installing and Adjusting CSF${normal} (this may take bit) ... "
  apt-get -y install e2fsprogs libio-socket-ssl-perl libcrypt-ssleay-perl \
  libnet-libidn-perl libio-socket-inet6-perl libsocket6-perl >/dev/null 2>&1;
  #wget http://www.configserver.com/free/csf.tgz >/dev/null 2>&1;
  wget https://download.configserver.com/csf.tgz >/dev/null 2>&1;
  tar -xzf csf.tgz >/dev/null 2>&1;
  ufw disable >>"${OUTTO}" 2>&1;
  service fail2ban stop >>"${OUTTO}" 2>&1;
  apt-get -y remove fail2ban >>"${OUTTO}" 2>&1;
  apt-get -y autoremove >>"${OUTTO}" 2>&1;
  cd csf
  sh install.sh >>"${OUTTO}" 2>&1;
  perl /usr/local/csf/bin/csftest.pl >>"${OUTTO}" 2>&1;
  # modify csf blocklists - essentially like CloudFlare, but on your machine
  sed -i.bak -e "s/#SPAMDROP|86400|0|/SPAMDROP|86400|100|/" \
             -e "s/#SPAMEDROP|86400|0|/SPAMEDROP|86400|100|/" \
             -e "s/#DSHIELD|86400|0|/DSHIELD|86400|100|/" \
             -e "s/#TOR|86400|0|/TOR|86400|100|/" \
             -e "s/#ALTTOR|86400|0|/ALTTOR|86400|100|/" \
             -e "s/#BOGON|86400|0|/BOGON|86400|100|/" \
             -e "s/#HONEYPOT|86400|0|/HONEYPOT|86400|100|/" \
             -e "s/#CIARMY|86400|0|/CIARMY|86400|100|/" \
             -e "s/#BFB|86400|0|/BFB|86400|100|/" \
             -e "s/#OPENBL|86400|0|/OPENBL|86400|100|/" \
             -e "s/#AUTOSHUN|86400|0|/AUTOSHUN|86400|100|/" \
             -e "s/#MAXMIND|86400|0|/MAXMIND|86400|100|/" \
             -e "s/#BDE|3600|0|/BDE|3600|100|/" \
             -e "s/#BDEALL|86400|0|/BDEALL|86400|100|/" /etc/csf/csf.blocklists;
  echo >> /etc/csf/csf.pignore;
  echo "[ QuickBox Additions - These are necessary to avoid noisy emails ]" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/rsyslogd" >> /etc/csf/csf.pignore;
  echo "exe:/lib/systemd/systemd-timesyncd" >> /etc/csf/csf.pignore;
  echo "exe:/lib/systemd/systemd-resolved" >> /etc/csf/csf.pignore;
  echo "exe:/lib/systemd/systemd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/apache2" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/vnstatd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/atd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/php-fpm7.0" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/memcached" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/uuidd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/plexmediaserver/Plex Media Server" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/plexmediaserver/Resources/Plex Script Host" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/plexmediaserver/Plex Script Host" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/gvfs/gvfsd-trash" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/dbus-launch" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/thunar" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/ssh-agent" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/python2.7" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/mysqld" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/znc" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/nx/bin/nxagent" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xfsettingsd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/x86_64-linux-gnu/xfce4/xfconf/xfconfd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xfdesktop" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xfce4-volumed" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/gvfs/gvfsd" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xfwm4" >> /etc/csf/csf.pignore;
  echo "exe:/usr/sbin/openvpn" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/gvfs/gvfs-udisks2-volume-monitor" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/quasselcore" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/gvfs/gvfsd-metadata" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xfce4-panel" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xfce4-session" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/x86_64-linux-gnu/xfce4/panel/wrapper-1.0" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/xscreensaver" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/syncthing" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/screen" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/irssi" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/mono-sgen" >> /etc/csf/csf.pignore;
  echo "exe:/usr/lib/openssh/sftp-server" >> /etc/csf/csf.pignore;
  echo "exe:/usr/bin/shellinaboxd" >> /etc/csf/csf.pignore;
  echo "[ QuickBox Additions - This is the QuickLab IP - needed for pulling updates ]" >> /etc/csf/csf.ignore;
  echo "45.79.179.250" >> /etc/csf/csf.ignore;
  # import csf conf template - made suitable for non-cpanel environments
  cp ${local_setup}templates/csf.conf.template /etc/csf/csf.conf
  sed -i "s/QBFIREWALLMASTER/${username}/" /etc/csf/csf.conf
  sed -i "s/QBFIREWALLPASSWD/${passwd}/" /etc/csf/csf.conf
  # install sendmail as it's binary is required by CSF
  echo "${green}Installing Sendmail${normal} (this may take bit) ... "
  apt-get -y install sendmail >>"${OUTTO}" 2>&1;
  export DEBIAN_FRONTEND=noninteractive | /usr/sbin/sendmailconfig >>"${OUTTO}" 2>&1;
  # add administrator email
  echo "${magenta}${bold}Add an Administrator Email Below for Aliases Inclusion${normal}"
  read -p "${bold}Email: ${normal}" admin_email
  echo
  echo "${bold}The email ${green}${bold}$admin_email${normal} ${bold}is now the forwarding address for root mail${normal}"
  echo "${green}finalizing sendmail installation${normal} (please hold) ... "
  # install aliases
  echo -e "mailer-daemon: postmaster
postmaster: root
nobody: root
hostmaster: root
usenet: root
news: root
webmaster: root
www: root
ftp: root
abuse: root
root: $admin_email" > /etc/aliases
  newaliases >>"${OUTTO}" 2>&1;

  echo "Installing and enabling service ... " >>"${OUTTO}" 2>&1;
  cp ${local_setup}templates/sysd/csf.template /etc/systemd/system/csf.service
  cp ${local_setup}templates/sysd/lfd.template /etc/systemd/system/lfd.service
  systemctl daemon-reload >/dev/null 2>&1
  service lfd stop >/dev/null 2>&1
  csf -x >/dev/null 2>&1
  systemctl enable csf >/dev/null 2>&1
  systemctl start csf >/dev/null 2>&1
  systemctl enable lfd >/dev/null 2>&1
  systemctl start lfd >/dev/null 2>&1
  csf -e >/dev/null 2>&1
  csf -r >/dev/null 2>&1
  echo
  echo
  touch /install/.csf.lock  >/dev/null 2>&1;
  echo "${green}ConfigServer Firewall Installation Complete${normal}"
  echo
  echo "You may now access the CSF UI on ${bold}https://$PUBLICIP:3443${normal}"
  echo "Username: $username"
  echo "Password: $passwd"
  echo

}

OUTTO=/etc/QuickBox.csf-install.log
HOSTNAME1=$(hostname -s)
PUBLICIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
#EMAIL=$(cat /srv/rutorrent/home/db/masteremail.txt)
local_setup=/etc/QuickBox/setup/
username=$(cat /srv/rutorrent/home/db/master.txt)
passwd=$(cat /root/${username}.info | cut -d ":" -f 3 | cut -d "@" -f 1)

_installCSF
