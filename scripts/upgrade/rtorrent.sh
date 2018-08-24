#!/bin/bash
# rtorrent upgrade/downgrade/reinstall script
# Author: liara

function _rar() {
	cd /tmp
  	wget -q http://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
  	tar -xzf rarlinux-x64-5.5.0.tar.gz >>$log 2>&1
  	cp rar/*rar /bin >/dev/null 2>&1
  	rm -rf rarlinux*.tar.gz >/dev/null 2>&1
  	rm -rf /tmp/rar >/dev/null 2>&1
}

function _removeold () {
  rm -rf /usr/bin/rtorrent
  cd /tmp
  git clone https://github.com/rakshasa/libtorrent.git libtorrent >>/dev/null 2>&1
  cd libtorrent
  ./autogen.sh >>$log 2>&1
  ./configure --prefix=/usr >>$log 2>&1
  make uninstall >>$log 2>&1
  cd -
  rm -rf /tmp/libtorrent
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
	wget -q -O mktorrent.zip https://github.com/Rudde/mktorrent/archive/v1.1.zip
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


if [[ ! -f /install/.rtorrent.lock ]]; then
  echo "rTorrent doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

distribution=$(lsb_release -is)
release=$(lsb_release -rs)
codename=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi
if [[ -z $rtorrentver ]] && [[ ${codename} =~ ("stretch"|"artful"|"bionic") ]]; then
	function=feature-bind
	#function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
							 #0.9.6 "" 3>&1 1>&2 2>&3)
							#feature-bind "" \
	 

		if [[ $function == 0.9.6 ]]; then
			export rtorrentver='0.9.6'
			export libtorrentver='0.13.6'
		elif [[ $function == feature-bind ]]; then
			export rtorrentver='feature-bind'
			export libtorrentver='feature-bind'
		fi
elif [[ -z ${rtorrentver} ]]; then
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
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in "${users[@]}"; do
  systemctl stop rtorrent@${u}
done

if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi
	  echo "Removing old rTorrent binaries and libraries ... ";_removeold
	  echo "Checking rTorrent Dependencies ... ";_depends
		echo "Building xmlrpc-c from source ... ";_xmlrpc
		echo "Building libtorrent from source ... ";_libtorrent
		echo "Building rtorrent from source ... ";_rtorrent
if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

for u in "${users[@]}"; do
	if grep -q localhost /home/$u/.rtorrent.rc; then sed -i 's/localhost/127.0.0.1/g' /home/$u/.rtorrent.rc; fi
  systemctl start rtorrent@${u}
done