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
echo "Pulling down some magic..."
source <(curl -s https://raw.githubusercontent.com/liaralabs/swizzin/master/sources/functions/color_echo)
source <(curl -s https://raw.githubusercontent.com/liaralabs/swizzin/master/sources/functions/apt)
source <(curl -s https://raw.githubusercontent.com/liaralabs/swizzin/master/sources/functions/ask)

if [[ $EUID -ne 0 ]]; then
  echo_error "Swizzin setup requires user to be root. su or sudo -s and run again ..."
	exit 1
fi

if [[ ! $(uname -m) == "x86_64" ]]; then
  echo_error -e "Unsupported architecture ($(uname -m)) detected!\nSetup will not be blocked; however, none of the scripts have been written with alternative archtectures in mind, nor will they be. Things may work, things may not work. Do not open issues on github if they do not."
  ask "Agree with the above and continue?" N || exit 1
fi

_os() {
	if [ ! -d /install ]; then mkdir /install; fi
	if [ ! -d /root/logs ]; then mkdir /root/logs; fi
	export log=/root/logs/install.log
	if ! which lsb_release > /dev/null; then
    apt_install lsb-release
	fi
	distribution=$(lsb_release -is)
	codename=$(lsb_release -cs)
	if [[ ! $distribution =~ ("Debian"|"Ubuntu") ]]; then
      echo_error "Your distribution ($distribution) is not supported. Swizzin requires Ubuntu or Debian." && exit 1
	fi
	if [[ ! $codename =~ ("xenial"|"bionic"|"stretch"|"buster"|"focal") ]]; then
      echo_error "Your release ($codename) of $distribution is not supported." && exit 1
	fi
}

function _preparation() {
	if [[ $distribution = "Ubuntu" ]]; then
    echo_progress_start "Enabling required repos"
		if ! which add-apt-repository > /dev/null; then
      apt_install software-properties-common
		fi
		add-apt-repository universe >> ${log} 2>&1
		add-apt-repository multiverse >> ${log} 2>&1
		add-apt-repository restricted -u >> ${log} 2>&1
    echo_progress_done
	fi
  apt_upgrade
  # bash <(curl -s https://raw.githubusercontent.com/liaralabs/swizzin/master/scripts/update/0-dependencies.sh)
  bash <(curl -s https://raw.githubusercontent.com/flying-sausages/swizzin/setup-trimdown/scripts/update/0-dependencies.sh)
	nofile=$(grep "DefaultLimitNOFILE=500000" /etc/systemd/system.conf)
	if [[ ! "$nofile" ]]; then echo "DefaultLimitNOFILE=500000" >> /etc/systemd/system.conf; fi
	if [[ $dev != "true" ]]; then
    echo_progress_start "Cloning swizzin repo to localhost"
		git clone https://github.com/liaralabs/swizzin.git /etc/swizzin >> ${log} 2>&1
		#shellcheck source=sources/functions/color_echo
		. /etc/swizzin/sources/functions/color_echo
    echo_progress_done
	else
		RelativeScriptPath=$(dirname "$0")
		ln -sr "$RelativeScriptPath" /etc/swizzin
		#shellcheck source=sources/functions/color_echo
		. /etc/swizzin/sources/functions/color_echo
    echo
		echo_info "WELCOME TO THE WORLD OF THE SWIZ YOUNG PADAWAN\nInstead of cloning from upstream, the directory where the setup script is located is symlinked to /etc/swizzin"
		echo_info "That directory is relative to your pwd  = $(pwd)/$RelativeScriptPath"
		echo_warn "Best of luck and please follow the contribution guidelines cheerio"
	fi
	ln -s /etc/swizzin/scripts/ /usr/local/bin/swizzin
	chmod -R 700 /etc/swizzin/scripts
	#shellcheck source=sources/functions/apt
	. /etc/swizzin/sources/functions/apt
	#shellcheck source=sources/functions/ask
	. /etc/swizzin/sources/functions/ask
}

function _nukeovh() {
  bash /etc/swizzin/scripts/nukeovh
}

function _intro() {
	whiptail --title "Swizzin seedbox installer" --msgbox "Yo, what's up? Let's install this swiz." 7 43
}

function _adduser() {
  #shellcheck source=sources/functions/utils
  . /etc/swizzin/sources/functions/utils
  username_check whiptail
  password_check whiptail
	echo "$user:$pass" > /root/.master.info
  bash /etc/swizzin/scripts/box adduser "$user" "$pass" # TODO make it so that the password does not hit the logs
  #TODO this should match word exactly, because amking user test, cancaelling, and making test1 will make no sudo modifications
  if grep ${user} /etc/sudoers.d/swizzin >/dev/null 2>&1 ; then echo_warn "No sudoers modification made" ; else	echo "${user}	ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/swizzin ; fi
  pass=
  unset pass
}

function _choices() {
	packages=()
	extras=()
	guis=()
	#locks=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "-" -f 2 | sort -d))
	locks=(nginx rtorrent deluge qbittorrent autodl panel vsftpd ffmpeg quota)
	for i in "${locks[@]}"; do
		app=${i}
		if [[ ! -f /install/.$app.lock ]]; then
			packages+=("$i" '""')
		fi
	done
	whiptail --title "Install Software" --checklist --noitem --separate-output "Choose your clients and core features." 15 26 7 "${packages[@]}" 2> /root/results
	exitstatus=$?
	if [ "$exitstatus" = 1 ]; then exit 0; fi
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
		whiptail --title "rTorrent GUI" --checklist --noitem --separate-output "Optional: Select a GUI for rtorrent" 15 26 7 "${guis[@]}" 2> /root/guis
		exitstatus=$?
		if [ "$exitstatus" = 1 ]; then exit 0; fi
		readarray guis < /root/guis
		for g in "${guis[@]}"; do
			g=$(echo $g)
			sed -i "/rtorrent/a $g" /root/results
		done
		rm -f /root/guis
		. /etc/swizzin/sources/functions/rtorrent
		whiptail_rtorrent
	fi
	if grep -q deluge "$results"; then
		. /etc/swizzin/sources/functions/deluge
		whiptail_deluge
	fi
	if grep -q qbittorrent "$results"; then
		. /etc/swizzin/sources/functions/qbittorrent
		whiptail_qbittorrent
	fi
	if grep -q qbittorrent "$results" || grep -q deluge "$results"; then
		. /etc/swizzin/sources/functions/libtorrent
		check_client_compatibility setup
		whiptail_libtorrent_rasterbar
		export SKIP_LT=True
	fi
  # TODO this should check for anything that requires nginx instead of just rutorrent...
  # A specific comment should be added to these installers, and if they are amongst results, should be grepped if they contain the comment or not
	if [[ $(grep -s rutorrent "$gui") ]] && [[ ! $(grep -s nginx "$results") ]]; then
		if (whiptail --title "nginx conflict" --yesno --yes-button "Install nginx" --no-button "Remove ruTorrent" "WARNING: The installer has detected that ruTorrent is to be installed without nginx. To continue, the installer must either install nginx or remove ruTorrent from the packages to be installed." 8 78); then
			sed -i '1s/^/nginx\n/' /root/results
			touch /tmp/.nginx.lock
		else
			sed -i '/rutorrent/d' /root/results
		fi
	fi

	while IFS= read -r result; do
		touch /tmp/.$result.lock
	done < "$results"

	locksextra=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "." -f 1 | sort -d))
	for i in "${locksextra[@]}"; do
		app=${i}
		if [[ ! -f /tmp/.$app.lock ]]; then
			extras+=("$i" '""')
		fi
	done
	whiptail --title "Install Software" --checklist --noitem --separate-output "Make some more choices ^.^ Or don't. idgaf" 15 26 7 "${extras[@]}" 2> /root/results2
	exitstatus=$?
	if [ "$exitstatus" = 1 ]; then exit 0; fi
	# results2=/root/results2
}

function _install() {
	begin=$(date +"%s")
  [[ -s /root/results ]] && bash /etc/swizzin/scripts/box install $( < /root/results ) && rm /root/results && showTimer=true
  [[ -s /root/results2 ]] && bash /etc/swizzin/scripts/box install $( < /root/results2 ) && rm /root/results2 && showTimer=true
	termin=$(date +"%s")
  difftimelps=$((termin-begin))
  [[ $showTimer = true ]] && echo_info "Package install took $((difftimelps / 60)) minutes and $((difftimelps % 60)) seconds"
}

function _post() {
	ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
	echo "export PATH=\$PATH:/usr/local/bin/swizzin" >> /root/.bashrc
	#echo "export PATH=\$PATH:/usr/local/bin/swizzin" >> /home/$user/.bashrc
	#chown ${user}: /home/$user/.profile
	echo "Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin" > /etc/sudoers.d/secure_path
	if [[ $distribution = "Ubuntu" ]]; then
		echo 'Defaults  env_keep -="HOME"' > /etc/sudoers.d/env_keep
	fi
  echo_success "Swizzin installation complete!"
	if [[ -f /install/.nginx.lock ]]; then
    echo_info "Seedbox can be accessed at https://${user}@${ip}"
	fi
	if [[ -f /install/.deluge.lock ]]; then
    echo_info "Your deluge daemon port is$(grep daemon_port /home/${user}/.config/deluge/core.conf | cut -d: -f2 | cut -d"," -f1)\nYour deluge web port is$(grep port /home/${user}/.config/deluge/web.conf | cut -d: -f2 | cut -d"," -f1)"
	fi
  echo_warn "Certain functions may not be fully functional until your server is rebooted or you log out and back in.\nYou may issue the command 'source /root/.bashrc' to begin using box and related functions now"
}

_os
_preparation
_nukeovh
_intro
_adduser
_choices
_install
_post
