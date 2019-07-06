#!/bin/bash
#################################################################################
# Installation script for swizzin
# Many credits to QuickBox for the package repo
# 
# Package installers copyright QuickBox.io (2017) where applicable.
# All other work copyright Swizzin (2017)
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

time=$(date +"%s")

if [[ $EUID -ne 0 ]]; then
  echo "Swizzin setup requires user to be root. su or sudo -s and run again ..."
  exit 1
fi

_os() {
  if [ ! -d /install ]; then mkdir /install ; fi
  if [ ! -d /root/logs ]; then mkdir /root/logs ; fi
  export log=/root/logs/install.log
  echo "Checking OS version and release ... "
  apt-get -y -qq update >> ${log} 2>&1
  apt-get -y -qq install lsb-release >> ${log} 2>&1
  distribution=$(lsb_release -is)
  release=$(lsb_release -rs)
  codename=$(lsb_release -cs)
    if [[ ! $distribution =~ ("Debian"|"Ubuntu") ]]; then
      echo "Your distribution ($distribution) is not supported. Swizzin requires Ubuntu or Debian." && exit 1
    fi
    if [[ ! $codename =~ ("xenial"|"bionic"|"jessie"|"stretch") ]]; then
      echo "Your release ($codename) of $distribution is not supported." && exit 1
    fi
  echo "I have determined you are using $distribution $release."
}

function _preparation() {
  echo "Updating system and grabbing core dependencies."
  if [[ $distribution = "Ubuntu" ]]; then
    echo "Checking enabled repos"
    if [[ -z $(which add-apt-repository) ]]; then
      apt-get install -y -q software-properties-common >> ${log} 2>&1
    fi
    add-apt-repository universe >> ${log} 2>&1
    add-apt-repository multiverse >> ${log} 2>&1
    add-apt-repository restricted -u >> ${log} 2>&1
  fi
  apt-get -q -y update >> ${log} 2>&1
  apt-get -q -y upgrade >> ${log} 2>&1
  apt-get -q -y install whiptail git sudo curl wget lsof fail2ban apache2-utils vnstat tcl tcl-dev build-essential dirmngr apt-transport-https python-pip >> ${log} 2>&1
  nofile=$(grep "DefaultLimitNOFILE=500000" /etc/systemd/system.conf)
  if [[ ! "$nofile" ]]; then echo "DefaultLimitNOFILE=500000" >> /etc/systemd/system.conf; fi
  echo "Cloning swizzin repo to localhost"
  git clone https://github.com/liaralabs/swizzin.git /etc/swizzin >> ${log} 2>&1
  ln -s /etc/swizzin/scripts/ /usr/local/bin/swizzin
  chmod -R 700 /etc/swizzin/scripts
}

function _nukeovh() {
  grsec=$(uname -a | grep -i grs)
  if [[ -n $grsec ]]; then
    echo
    echo -e "Your server is currently running with kernel version: $(uname -r)"
    echo -e "While not it is not required to switch, kernels with grsec are not recommend due to conflicts in the panel and other packages."
    echo
    echo -ne "Would you like swizzin to install the distribution kernel? (Default: Y) "; read input
      case $input in
        [yY] | [yY][Ee][Ss] | "" ) kernel=yes; echo "Your distribution's default kernel will be installed. A reboot will be required."  ;;
        [nN] | [nN][Oo] ) echo "Installer will continue as is. If you change your mind in the future run `box rmgrsec` after install." ;;
      *) kernel=yes; echo "Your distribution's default kernel will be installed. A reboot will be required."  ;;
      esac
      if [[ $kernel == yes ]]; then
        if [[ $DISTRO == Ubuntu ]]; then
          apt-get install -q -y linux-image-generic >>"${OUTTO}" 2>&1
        elif [[ $DISTRO == Debian ]]; then
          arch=$(uname -m)
          if [[ $arch =~ ("i686"|"i386") ]]; then
            apt-get install -q -y linux-image-686 >>"${OUTTO}" 2>&1
          elif [[ $arch == x86_64 ]]; then
            apt-get install -q -y linux-image-amd64 >>"${OUTTO}" 2>&1
          fi
        fi
        mv /etc/grub.d/06_OVHkernel /etc/grub.d/25_OVHkernel
        update-grub >>"${OUTTO}" 2>&1
      fi
  fi
}

function _skel() {
  rm -rf /etc/skel
  cp -R /etc/swizzin/sources/skel /etc/skel
}

function _intro() {
  whiptail --title "Swizzin seedbox installer" --msgbox "Yo, what's up? Let's install this swiz." 15 50
}

function _adduser() {
  while [[ -z $user ]]; do
    user=$(whiptail --inputbox "Enter Username" 9 30 3>&1 1>&2 2>&3); exitstatus=$?; if [ "$exitstatus" = 1 ]; then exit 0; fi
    if [[ $user =~ [A-Z] ]]; then
      read -n 1 -s -r -p "Usernames must not contain capital letters. Press enter to try again."
      printf "\n"
      user=
    fi
  done
  while [[ -z "${pass}" ]]; do
    pass=$(whiptail --inputbox "Enter User password. Leave empty to generate." 9 30 3>&1 1>&2 2>&3); exitstatus=$?; if [ "$exitstatus" = 1 ]; then exit 0; fi
    if [[ -z "${pass}" ]]; then
      pass="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"
    fi
    if [[ -n $(which cracklib-check) ]]; then 
      echo "Cracklib detected. Checking password strength."
      sleep 1
      str="$(cracklib-check <<<"$pass")"
      check=$(grep OK <<<"$str")
      if [[ -z $check ]]; then
        read -n 1 -s -r -p "Password did not pass cracklib check. Press any key to enter a new password"
        printf "\n"
        pass=
      else
        echo "OK."
      fi
    fi
  done
  echo "$user:$pass" > /root/.master.info
  if [[ -d /home/"$user" ]]; then
    echo "User directory already exists ... "
    #_skel
    #cd /etc/skel
    #cp -R * /home/$user/
    echo "Changing password to new password"
    chpasswd<<<"${user}:${pass}"
    htpasswd -b -c /etc/htpasswd $user $pass
    mkdir -p /etc/htpasswd.d/
    htpasswd -b -c /etc/htpasswd.d/htpasswd.${user} $user $pass
    chown -R $user:$user /home/${user}
  else
    echo -e "Creating new user \e[1;95m$user\e[0m ... "
    #_skel
    useradd "${user}" -m -G www-data -s /bin/bash
    chpasswd<<<"${user}:${pass}"
    htpasswd -b -c /etc/htpasswd $user $pass
    mkdir -p /etc/htpasswd.d/
    htpasswd -b -c /etc/htpasswd.d/htpasswd.${user} $user $pass
  fi
  chmod 750 /home/${user}
  if grep ${user} /etc/sudoers.d/swizzin >/dev/null 2>&1 ; then echo "No sudoers modification made ... " ; else	echo "${user}	ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/swizzin ; fi
  echo "D /var/run/${user} 0750 ${user} ${user} -" >> /etc/tmpfiles.d/${user}.conf
  systemd-tmpfiles /etc/tmpfiles.d/${user}.conf --create
}

function _choices() {
  packages=()
  extras=()
  guis=()
  #locks=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "-" -f 2 | sort -d))
  locks=(nginx rtorrent deluge autodl panel vsftpd ffmpeg quota)
  for i in "${locks[@]}"; do
    app=${i}
    if [[ ! -f /install/.$app.lock ]]; then
      packages+=("$i" '""')
    fi
  done
  whiptail --title "Install Software" --checklist --noitem --separate-output "Choose your clients and core features." 15 26 7 "${packages[@]}" 2>/root/results; exitstatus=$?; if [ "$exitstatus" = 1 ]; then exit 0; fi
  #readarray packages < /root/results
  results=/root/results

  if grep -q nginx "$results"; then
    if [[ -n $(pidof apache2) ]]; then
      if (whiptail --title "apache2 conflict" --yesno --yes-button "Purge it!" --no-button "Disable it" "WARNING: The installer has detected that apache2 is already installed. To continue, the installer must either purge apache2 or disable it." 8 78); then
        export apache2=purge
      else
        export apache2=disable
      fi
    fi
  fi
  if grep -q rtorrent "$results"; then
    gui=(rutorrent flood)
    for i in "${gui[@]}"; do
      app=${i}
      if [[ ! -f /install/.$app.lock ]]; then
        guis+=("$i" '""')
      fi
    done
    whiptail --title "rTorrent GUI" --checklist --noitem --separate-output "Optional: Select a GUI for rtorrent" 15 26 7 "${guis[@]}" 2>/root/guis; exitstatus=$?; if [ "$exitstatus" = 1 ]; then exit 0; fi
    readarray guis < /root/guis
    for g in "${guis[@]}"; do
      g=$(echo $g)
      sed -i "/rtorrent/a $g" /root/results
    done
    rm -f /root/guis

    if [[ ! ${codename} =~ ("xenial"|"jessie") ]]; then
      #function=feature-bind
      function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
                  feature-bind "" \
                  0.9.7 "" \
                  0.9.6 "" 3>&1 1>&2 2>&3)
      

        if [[ $function == 0.9.7 ]]; then
          export rtorrentver='0.9.7'
          export libtorrentver='0.13.7'
        elif [[ $function == 0.9.6 ]]; then
          export rtorrentver='0.9.6'
          export libtorrentver='0.13.6'
        elif [[ $function == feature-bind ]]; then
          export rtorrentver='feature-bind'
          export libtorrentver='feature-bind'
        fi

    else
      function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
                  feature-bind "" \
                  0.9.7 "" \
                  0.9.6 "" \
                  0.9.4 "" \
                  0.9.3 "" 3>&1 1>&2 2>&3)



        if [[ $function == 0.9.7 ]]; then
          export rtorrentver='0.9.7'
          export libtorrentver='0.13.7'
        elif [[ $function == 0.9.6 ]]; then
          export rtorrentver='0.9.6'
          export libtorrentver='0.13.6'
        elif [[ $function == 0.9.4 ]]; then
          export rtorrentver='0.9.4'
          export libtorrentver='0.13.4'
        elif [[ $function == 0.9.3 ]]; then
          export rtorrentver='0.9.3'
          export libtorrentver='0.13.3'
        elif [[ $function == feature-bind ]]; then
          export rtorrentver='feature-bind'
          export libtorrentver='feature-bind'
        fi
    fi
  fi
  if grep -q deluge "$results"; then
    function=$(whiptail --title "Install Software" --menu "Choose a Deluge version:" --ok-button "Continue" --nocancel 12 50 3 \
                Repo "" \
                Stable "" \
                Dev "" 3>&1 1>&2 2>&3)

      if [[ $function == Repo ]]; then
        export deluge=repo
      elif [[ $function == Stable ]]; then
        export deluge=stable
      elif [[ $function == Dev ]]; then
        export deluge=dev
      fi
  fi
  if [[ $(grep -s rutorrent "$gui") ]] && [[ ! $(grep -s nginx "$results") ]]; then
      if (whiptail --title "nginx conflict" --yesno --yes-button "Install nginx" --no-button "Remove ruTorrent" "WARNING: The installer has detected that ruTorrent is to be installed without nginx. To continue, the installer must either install nginx or remove ruTorrent from the packages to be installed." 8 78); then
        sed -i '1s/^/nginx\n/' /root/results
        touch /tmp/.nginx.lock
      else
        sed -i '/rutorrent/d' /root/results
      fi
  fi

  while IFS= read -r result
  do
    touch /tmp/.$result.lock
  done < "$results"

  locksextra=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "." -f 1 | sort -d))
  for i in "${locksextra[@]}"; do
    app=${i}
    if [[ ! -f /tmp/.$app.lock ]]; then
      extras+=("$i" '""')
    fi
  done
  whiptail --title "Install Software" --checklist --noitem --separate-output "Make some more choices ^.^ Or don't. idgaf" 15 26 7 "${extras[@]}" 2>/root/results2; exitstatus=$?; if [ "$exitstatus" = 1 ]; then exit 0; fi
  results2=/root/results2
}

function _install() {
  touch /tmp/.install.lock
  begin=$(date +"%s")
  readarray result < /root/results
  for i in "${result[@]}"; do
    result=$(echo $i)
    echo -e "Installing ${result}"
    bash /usr/local/bin/swizzin/install/${result}.sh
    rm /tmp/.$result.lock
  done
  rm /root/results
  readarray result < /root/results2
  for i in "${result[@]}"; do
    result=$(echo $i)
    echo -e "Installing ${result}"
    bash /usr/local/bin/swizzin/install/${result}.sh
  done
  rm /root/results2
  rm /tmp/.install.lock
  termin=$(date +"%s")
  difftimelps=$((termin-begin))
  echo "Package install took $((difftimelps / 60)) minutes and $((difftimelps % 60)) seconds"
}

function _post {
  ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
  echo "export PATH=\$PATH:/usr/local/bin/swizzin" >> /root/.bashrc
  #echo "export PATH=\$PATH:/usr/local/bin/swizzin" >> /home/$user/.bashrc
  #chown ${user}: /home/$user/.profile
  echo "Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin" > /etc/sudoers.d/secure_path
  if [[ $distribution = "Ubuntu" ]]; then
    echo 'Defaults  env_keep -="HOME"' > /etc/sudoers.d/env_keep
  fi
  echo "Installation complete!"
  echo ""
  echo "You may now login with the following info: ${user}:${pass}"
  echo ""
  if [[ -f /install/.nginx.lock ]]; then
    echo "Seedbox can be accessed at https://${user}:${pass}@${ip}"
    echo ""
  fi
  if [[ -f /install/.deluge.lock ]]; then
    echo "Your deluge daemon port is$(cat /home/${user}/.config/deluge/core.conf | grep daemon_port | cut -d: -f2 | cut -d"," -f1)"
    echo "Your deluge web port is$(cat /home/${user}/.config/deluge/web.conf | grep port | cut -d: -f2 | cut -d"," -f1)"
    echo ""
  fi
  echo -e "\e[1m\e[31mPlease note, certain functions may not be fully functional until your server is rebooted or you log out and back in. However you may issue the command 'source /root/.bashrc' to begin using box and related functions now\e[0m"
}

_os
_preparation
_nukeovh
_skel
_intro
_adduser
_choices
_install
_post
