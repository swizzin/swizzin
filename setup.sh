#!/bin/bash
#################################################################################
# Installation script for swizzin
# Credits to QuickBox for the package repo
# Modified for nginx
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
	echo "Checking OS version and release ... "
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
  if [ ! -d /install ]; then mkdir /install ; fi
  if [ ! -d /root/logs ]; then mkdir /root/logs ; fi
  export log=/root/logs/install.log
  echo "Updating system and grabbing core dependencies."
  apt-get -qq -y --force-yes update >> ${log} 2>&1
  apt-get -qq -y --force-yes upgrade >> ${log} 2>&1
  apt-get -qq -y --force-yes install whiptail lsb-release git sudo fail2ban apache2-utils vnstat tcl tcl-dev build-essential >> ${log} 2>&1
  nofile=$(grep "DefaultLimitNOFILE=3072" /etc/systemd/system.conf)
  if [[ ! "$nofile" ]]; then echo "DefaultLimitNOFILE=3072" >> /etc/systemd/system.conf; fi
  echo "Cloning swizzin repo to localhost"
	export GIT_SSL_NO_VERIFY=true
  git clone https://gitlab.swizzin.ltd/liara/swizzin.git /etc/swizzin >> ${log} 2>&1
  ln -s /etc/swizzin/scripts/ /usr/local/bin/swizzin
}

function _skel() {
  rm -rf /etc/skel
  cp -R /etc/swizzin/sources/skel /etc/skel
}

function _intro() {
  whiptail --title "Swizzin seedbox installer" --msgbox "Yo, what's up? Let's install this swiz." 15 50
}

function _adduser() {
  user=$(whiptail --inputbox "Enter Username" 9 30 3>&1 1>&2 2>&3); exitstatus=$?; if [ ! "$exitstatus" = 0 ]; then _exit; fi
  if [[ $user =~ [A-Z] ]]; then
    echo "Usernames must not contain capital letters. Please try again."
    _adduser
  fi
  pass=$(whiptail --inputbox "Enter User password. Leave empty to generate." 9 30 3>&1 1>&2 2>&3); exitstatus=$?; if [ ! "$exitstatus" = 0 ]; then _exit; fi
  if [[ -z "${pass}" ]]; then
    pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;)
  fi
	echo "$user:$pass" > /root/.master.info
  if [[ -d /home/"$user" ]]; then
					echo "User directory already exists ... "
					#_skel
					#cd /etc/skel
					#cp -R * /home/$user/
					echo "Changing password to new password"
					echo "${user}:${pass}" | chpasswd >/dev/null 2>&1
					htpasswd -b -c /etc/htpasswd $user $pass
					mkdir -p /etc/htpasswd.d/
					htpasswd -b -c /etc/htpasswd.d/htpasswd.${user} $user $pass
					chown -R $user:$user /home/${user}
    else
      echo -e "Creating new user \e[1;95m$user\e[0m ... "
      #_skel
      useradd "${user}" -m -G www-data
      echo "${user}:${pass}" | chpasswd >/dev/null 2>&1
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
	whiptail --title "Install Software" --checklist --noitem --separate-output "Choose your clients and core features." 15 26 7 "${packages[@]}" 2>/root/results
	#readarray packages < /root/results
	results=/root/results
	while IFS= read -r result
 	do
	 touch /tmp/.$result.lock
 done < "$results"
	if grep -q rtorrent "$results"; then
		function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
								0.9.6 "" \
								feature-bind "" 3>&1 1>&2 2>&3)

			if [[ $function == 0.9.6 ]]; then
				export rtorrentver='0.9.6'
				export libtorrentver='0.13.6'
			elif [[ $function == feature-bind ]]; then
				export rtorrentver='feature-bind'
				export libtorrentver='feature-bind'
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
	whiptail --title "Install Software" --checklist --noitem --separate-output "Make some more choices ^.^ Or don't. idgaf" 15 26 7 "${extras[@]}" 2>/root/results2
	results2=/root/results2

}

function _install() {
	touch /tmp/.install.lock
	while IFS= read -r result
 	do
		echo -e "Installing ${result}"
		bash /usr/local/bin/swizzin/install/${result}.sh
		rm /tmp/.$result.lock
 done < "$results"
 	rm /root/results
 while IFS= read -r result
 do
	 echo -e "Installing ${result}"
	 bash /usr/local/bin/swizzin/install/${result}.sh
done < "$results2"
	rm /root/results2
	rm /tmp/.install.lock
}

function _post {
	echo "export PATH=$PATH:/usr/local/bin/swizzin" >> /root/.bashrc
}

_os
_preparation
_skel
_intro
_adduser
_choices
_install
_post
