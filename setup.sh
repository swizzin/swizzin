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
    if [[ ! $codename =~ ("xenial"|"yakkety"|"zesty"|"jessie"|"stretch") ]]; then
      echo "Your release ($codename) of $distribution is not supported." && exit 1
    fi
  echo "I have determined you are using $distribution $release."
}

function _preparation() {
  echo "Updating system and grabbing core dependencies."
  apt-get -qq -y --force-yes update >> ${log} 2>&1
  apt-get -qq -y --force-yes upgrade >> ${log} 2>&1
  apt-get -qq -y --force-yes install whiptail git sudo fail2ban apache2-utils vnstat tcl tcl-dev build-essential dirmngr >> ${log} 2>&1
  nofile=$(grep "DefaultLimitNOFILE=3072" /etc/systemd/system.conf)
  if [[ ! "$nofile" ]]; then echo "DefaultLimitNOFILE=3072" >> /etc/systemd/system.conf; fi
  echo "Cloning swizzin repo to localhost"
  git clone https://github.com/liaralabs/swizzin.git /etc/swizzin >> ${log} 2>&1
  ln -s /etc/swizzin/scripts/ /usr/local/bin/swizzin
  chmod -R 700 /etc/swizzin/scripts
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
}

function _choices() {
  packages=()
  extras=()
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
  while IFS= read -r result
  do
    touch /tmp/.$result.lock
  done < "$results"
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
    if [[ ${codename} =~ ("stretch") ]]; then
      function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
                  0.9.6 "" 3>&1 1>&2 2>&3)
                #feature-bind "" \

        if [[ $function == 0.9.6 ]]; then
          export rtorrentver='0.9.6'
          export libtorrentver='0.13.6'
        #elif [[ $function == feature-bind ]]; then
        #	export rtorrentver='feature-bind'
        #	export libtorrentver='feature-bind'
        fi
      else
        function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
               0.9.6 "" \
               0.9.4 "" \
               0.9.3 "" 3>&1 1>&2 2>&3)
              #feature-bind "" \

        if [[ $function == 0.9.6 ]]; then
          export rtorrentver='0.9.6'
          export libtorrentver='0.13.6'
        elif [[ $function == 0.9.4 ]]; then
          export rtorrentver='0.9.4'
          export libtorrentver='0.13.4'
        elif [[ $function == 0.9.3 ]]; then
          export rtorrentver='0.9.3'
          export libtorrentver='0.13.3'
        #elif [[ $function == feature-bind ]]; then
        #	export rtorrentver='feature-bind'
        #	export libtorrentver='feature-bind'
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
  ip=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
  echo "export PATH=$PATH:/usr/local/bin/swizzin" >> /root/.bashrc
  echo "export PATH=$PATH:/usr/local/bin/swizzin" >> /home/$user/.bashrc
  chown ${user}: /home/$user/.bashrc
  echo "Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin" > /etc/sudoers.d/secure_path
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
  echo "Please note, certain functions may not be fully functional until your server is rebooted"
  echo "However you may issue the command 'source /root/.bashrc' to begin using box functions now"
}

_os
_preparation
_skel
_intro
_adduser
_choices
_install
_post
