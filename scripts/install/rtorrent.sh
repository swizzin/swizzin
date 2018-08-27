#!/bin/bash
# rTorrent installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }

function _rar() {
	cd /tmp
  	wget -q http://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
  	tar -xzf rarlinux-x64-5.5.0.tar.gz >/dev/null 2>&1
  	cp rar/*rar /bin >/dev/null 2>&1
  	rm -rf rarlinux*.tar.gz >/dev/null 2>&1
  	rm -rf /tmp/rar >/dev/null 2>&1
}

function _depends() {
	APT='subversion dos2unix bc screen zip unzip sysstat build-essential cfv comerr-dev
	dstat automake libtool libcppunit-dev libssl-dev pkg-config libcurl4-openssl-dev
	libsigc++-2.0-dev unzip curl libncurses5-dev yasm  fontconfig libfontconfig1
	libfontconfig1-dev mediainfo'
	for depends in $APT; do
	apt-get -q -y install "$depends"  >> $log 2>&1 || { echo "ERROR: APT-GET could not install required package: ${depends}. That's probably not good..."; }
	done

	# (un)rar
  if [[ $distribution == "Debian" ]]; then
	_rar
  else
    apt-get -y install rar unrar >>$log 2>&1 || { echo "INFO: Could not find rar/unrar in the repositories. It is likely you do not have the multiverse repo enabled. Installing directly."; _rar; }
  fi

	# mktorrent from source
	cd /tmp
	wget -q -O mktorrent.zip https://github.com/Rudde/mktorrent/archive/v1.1.zip >>$log 2>&1
	unzip -d mktorrent -j mktorrent.zip >>$log 2>&1
	cd mktorrent
	make >>$log 2>&1
	make install PREFIX=/usr >>$log 2>&1
	cd /tmp
	rm -rf mktorrent*
}

function _xmlrpc() {
		
	cd "/tmp"
	svn co https://svn.code.sf.net/p/xmlrpc-c/code/advanced xmlrpc-c >>$log 2>&1 || { svn co https://github.com/mirror/xmlrpc-c/trunk/advanced xmlrpc-c >>$log 2>&1; }
	cd xmlrpc-c
	./configure --prefix=/usr --disable-cplusplus >>$log 2>&1
	make -j$(nproc) >>$log 2>&1
	make install >>$log 2>&1
}

function _libtorrent() {
	cd "/tmp"
	rm -rf xmlrpc-c >>$log 2>&1
	if [[ ${libtorrentver} == feature-bind ]]; then
		git clone -b ${libtorrentver} https://github.com/rakshasa/libtorrent.git libtorrent >>$log 2>&1
		cd libtorrent
	else
		mkdir libtorrent
		wget -q ${libtorrentloc}
		tar -xvf libtorrent-${libtorrentver}.tar.gz -C /tmp/libtorrent --strip-components=1 >>$log 2>&1
		cd libtorrent >>$log 2>&1
		#if [[ ${codename} =~ ("stretch") ]]; then
		#	patch -p1 < /etc/swizzin/sources/openssl.patch >>"$log" 2>&1
		#fi
	fi
	./autogen.sh >>$log 2>&1
	./configure --prefix=/usr >>$log 2>&1
	make -j$(nproc) >>$log 2>&1
	make install >>$log 2>&1
}

function _rtorrent() {
	cd "/tmp"
	rm -rf libtorrent* >>$log 2>&1
	if [[ ${rtorrentver} == feature-bind ]]; then
		git clone -b ${rtorrentver} https://github.com/rakshasa/rtorrent.git rtorrent >>$log 2>&1
	else
		mkdir rtorrent
		wget -q ${rtorrentloc}
		tar -xzvf rtorrent-${rtorrentver}.tar.gz -C /tmp/rtorrent --strip-components=1 >>$log 2>&1
	fi
	cd rtorrent
	if [[ ${rtorrentver} == feature-bind ]]; then
		./autogen.sh >>$log 2>&1
	fi
	./configure --prefix=/usr --with-xmlrpc-c >>$log 2>&1
	make -j$(nproc) >>$log 2>&1
	make install >>$log 2>&1
	cd "/tmp"
	ldconfig >>$log 2>&1
	rm -rf rtorrent* >>$log 2>&1		
}

function _rconf() {
cat >/home/${user}/.rtorrent.rc<<EOF
# -- START HERE --
directory.default.set = /home/${user}/torrents/rtorrent
encoding.add = UTF-8
encryption = allow_incoming,try_outgoing,enable_retry
execute.nothrow = chmod,777,/home/${user}/.config/rpc.socket
execute.nothrow = chmod,777,/home/${user}/.sessions
network.port_random.set = yes
network.port_range.set = $port-$portend
network.scgi.open_local = /var/run/${user}/.rtorrent.sock
schedule2 = chmod_scgi_socket, 0, 0, "execute2=chmod,\"g+w,o=\",/var/run/${user}/.rtorrent.sock"
network.tos.set = throughput
pieces.hash.on_completion.set = no
protocol.pex.set = no
schedule = watch_directory,5,5,load.start=/home/${user}/rwatch/*.torrent
session.path.set = /home/${user}/.sessions/
throttle.global_down.max_rate.set = 0
throttle.global_up.max_rate.set = 0
throttle.max_peers.normal.set = 100
throttle.max_peers.seed.set = -1
throttle.max_uploads.global.set = 100
throttle.min_peers.normal.set = 1
throttle.min_peers.seed.set = -1
trackers.use_udp.set = yes

execute = {sh,-c,/usr/bin/php /srv/rutorrent/php/initplugins.php ${user} &}

# -- END HERE --
EOF
chown ${user}.${user} -R /home/${user}/.rtorrent.rc
}


function _makedirs() {
	mkdir -p /home/${user}/torrents/rtorrent 2>> $log
	mkdir -p /home/${user}/.sessions
	mkdir -p /home/${user}/rwatch
	chown -R ${user}.${user} /home/${user}/{torrents,.sessions,rwatch} 2>> $log
	usermod -a -G www-data ${user} 2>> $log
	usermod -a -G ${user} www-data 2>> $log
}


function _perms() {
	chown -R ${user}.${user} /home/${user}/ 2>> $log
}



_systemd() {
cat >/etc/systemd/system/rtorrent@.service<<EOF
[Unit]
Description=rTorrent
After=network.target

[Service]
Type=forking
KillMode=none
User=%I
ExecStartPre=-/bin/rm -f /home/%I/.sessions/rtorrent.lock
ExecStart=/usr/bin/screen -d -m -fa -S rtorrent /usr/bin/rtorrent
ExecStop=/usr/bin/screen -X -S rtorrent quit
WorkingDirectory=/home/%I/

[Install]
WantedBy=multi-user.target
EOF
systemctl enable rtorrent@${user} 2>> $log
service rtorrent@${user} start
}

export DEBIAN_FRONTEND=noninteractive

distribution=$(lsb_release -is)
release=$(lsb_release -rs)
codename=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi
if [[ -z $rtorrentver ]] && [[ ${codename} =~ ("stretch"|"artful"|"bionic") ]] && [[ -z $1 ]]; then
	function=feature-bind
	#function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
							# 0.9.6 "" 3>&1 1>&2 2>&3)
							#feature-bind "" \
	 

		if [[ $function == 0.9.6 ]]; then
			export rtorrentver='0.9.6'
			export libtorrentver='0.13.6'
		elif [[ $function == feature-bind ]]; then
			export rtorrentver='feature-bind'
			export libtorrentver='feature-bind'
		fi
elif [[ -z ${rtorrentver} ]] && [[ -z $1 ]]; then
	function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
							 feature-bind "" \
							 0.9.6 "" \
							 0.9.4 "" \
							 0.9.3 "" 3>&1 1>&2 2>&3)



		if [[ $function == 0.9.6 ]]; then
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

noexec=$(cat /etc/fstab | grep "/tmp" | grep noexec)
rtorrentloc="http://rtorrent.net/downloads/rtorrent-${rtorrentver}.tar.gz"
libtorrentloc="http://rtorrent.net/downloads/libtorrent-${libtorrentver}.tar.gz"
xmlrpc="https://svn.code.sf.net/p/xmlrpc-c/code/advanced"
user=$(cat /root/.master.info | cut -d: -f1)
rutorrent="/srv/rutorrent/"
port=$((RANDOM%64025+1024))
portend=$((${port} + 1500))

if [[ -n $1 ]]; then
	user=$1
	_makedirs
	_rconf
	exit 0
fi

if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi
	  echo "Installing rTorrent Dependencies ... ";_depends
		echo "Building xmlrpc-c from source ... ";_xmlrpc
		echo "Building libtorrent from source ... ";_libtorrent
		echo "Building rtorrent from source ... ";_rtorrent
		echo "Making ${user} directory structure ... ";_makedirs
		echo "Setting permissions on ${user} ... ";_perms
		echo "setting up rtorrent.rc ... ";_rconf;_systemd

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi
		touch /install/.rtorrent.lock
