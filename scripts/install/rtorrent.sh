#!/bin/bash

function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }

function _depends() {
	APT='subversion dos2unix bc screen zip unzip sysstat build-essential cfv comerr-dev
	dstat automake libtool libcppunit-dev libssl-dev pkg-config libcurl4-openssl-dev
	libsigc++-2.0-dev unzip curl libncurses5-dev yasm  fontconfig libfontconfig1
	libfontconfig1-dev mediainfo mktorrent'
	for depends in $APT; do
	apt-get -qq -y --yes --force-yes install "$depends" >/dev/null 2>&1 || (echo "APT-GET could not find a required package: ${depends}. Script Ending." && echo "${warning}" && exit 1)
	done
  if [[ $distribution == "Debian" ]]; then
    cd /tmp
  	wget -q http://www.rarlab.com/rar/rarlinux-x64-5.4.0.tar.gz
  	tar -xzf rarlinux-x64-5.4.0.tar.gz >/dev/null 2>&1
  	cp rar/*rar /bin >/dev/null 2>&1
  	rm -rf rarlinux*.tar.gz >/dev/null 2>&1
  	rm -rf /tmp/rar >/dev/null 2>&1
  else
    apt-get -y install unrar >>$log 2>&1
  fi
}

function _xmlrpc() {
				cd "/tmp"
				svn co https://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c >>$log 2>&1
				cd xmlrpc-c
				./configure --prefix=/usr --disable-cplusplus >>$log 2>&1
				make -j${nproc} >>$log 2>&1
				make install >>$log 2>&1
}

function _libtorrent() {
				cd "/tmp"
				rm -rf xmlrpc-c >>$log 2>&1
				mkdir libtorrent
				wget -q ${libtorrentloc}
				tar -xvf libtorrent-* -C /tmp/libtorrent --strip-components=1 >>$log 2>&1
				cd libtorrent >>$log 2>&1
				if [[ ${codename} =~ ("stretch") ]]; then
					patch -p1 < /etc/swizzin/sources/openssl.patch
				fi
				./autogen.sh >>$log 2>&1
				./configure --prefix=/usr >>$log 2>&1
				make -j${nproc} >>$log 2>&1
				make install >>$log 2>&1
}

function _rtorrent() {
				cd "/tmp"
				rm -rf libtorrent* >>$log 2>&1
				mkdir rtorrent
				wget -q ${rtorrentloc}
				tar -xzvf rtorrent-* -C /tmp/rtorrent --strip-components=1 >>$log 2>&1
				cd rtorrent
				./configure --prefix=/usr --with-xmlrpc-c >/dev/null 2>&1
				make -j${nproc} >/dev/null 2>&1
				make install >/dev/null 2>&1
				cd "/tmp"
				ldconfig >/dev/null 2>&1
				rm -rf rtorrent* >/dev/null 2>&1
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
network.scgi.open_port = localhost:$port
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

execute = {sh,-c,/usr/bin/php /var/www/rutorrent/php/initplugins.php ${user} &}

# -- END HERE --
EOF
chown ${user}.${user} -R /home/${user}/.rtorrent.rc
}


function _makedirs() {
	mkdir -p /home/${user}/torrents/rtorrent 2>> $log
	mkdir -p /home/${user}/.sessions
	mkdir -p /home/${user}/rwatch
	chown ${user}.${user} /home/${user}/{torrents,.sessions,rwatch} 2>> $log
	usermod -a -G www-data ${user} 2>> $log
	usermod -a -G ${user} www-data 2>> $log
}


function _perms() {
	chown -R ${user}.${user} /home/${user}/ 2>> $log
	sudo -u ${user} chmod 755 /home/${user}/ 2>> $log
	chsh -s /bin/bash ${user}
	if grep ${user} /etc/sudoers.d/swizzin >/dev/null 2>&1 ; then echo "No sudoers modification made ... " ; else	echo "${user}	ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/swizzin ; fi
}

function _ruconf() {
	bash /usr/local/bin/swizzin/nginx/rtorrent.sh
	systemctl force-reload nginx
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
ExecStop=/usr/bin/killall -w -s 2 /usr/bin/rtorrent
WorkingDirectory=/home/%I/

[Install]
WantedBy=multi-user.target
EOF
systemctl enable rtorrent@${user} 2>> $log
service rtorrent@${user} start
}

export DEBIAN_FRONTEND=noninteractive

begin=$(date +"%s")
distribution=$(lsb_release -is)
release=$(lsb_release -rs)
codename=$(lsb_release -cs)
if [[ -z $rtorrentver ]]; then
	if [[ ${codename} =~ ("stretch") ]]; then
		export rtorrentver='0.9.6'
		export libtorrentver='0.13.6'
	else
	function=$(whiptail --title "Install Software" --menu "Choose an rTorrent version:" --ok-button "Continue" --nocancel 12 50 3 \
							 0.9.6 "" \
							 0.9.4 "" \
							 0.9.2 "" 3>&1 1>&2 2>&3)

		if [[ $function == 0.9.6 ]]; then
			export rtorrentver='0.9.6'
			export libtorrentver='0.13.6'
		elif [[ $function == 0.9.4 ]]; then
			export rtorrentver='0.9.4'
			export libtorrentver='0.13.4'
		elif [[ $function == 0.9.2 ]]; then
			export rtorrentver='0.9.3'
			export libtorrentver='0.13.3'
		fi
fi
fi
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi
rtorrentloc='http://rtorrent.net/downloads/rtorrent-'$rtorrentver'.tar.gz'
libtorrentloc='http://rtorrent.net/downloads/libtorrent-'$libtorrentver'.tar.gz'
xmlrpc='https://svn.code.sf.net/p/xmlrpc-c/code/stable'
user=$(cat /root/.master.info | cut -d: -f1)
logdir="/root/logs"
rutorrent="/srv/rutorrent/"
port=$((RANDOM%64025+1024))
portend=$((${port} + 1500))
warning=$(echo -e "[ \e[1;91mWARNING\e[0m ]")
rdisk=$(free -m | grep "Mem" | awk '{printf "%.0f\n", $2/10}'); if [[ $rdisk -gt 500 ]];then installdir="/tmp/ramdisk";else installdir="/tmp"; fi

	  echo "Installing rTorrent Dependencies ... ";_depends
		echo "Building xmlrpc-c from source ... ";_xmlrpc
		echo "Building libtorrent from source ... ";_libtorrent
		echo "Building rtorrent from source ... ";_rtorrent
		echo "Making ${user} directory structure ... ";_makedirs
		echo "Setting permissions on ${user} ... ";_perms
		echo "setting up rtorrent.rc ... ";_rconf;_systemd
		if [[ -f /install/.nginx.lock ]]; then
			echo "Installing ruTorrent";_ruconf
		fi
		touch /install/.rtorrent.lock
termin=$(date +"%s")
difftimelps=$((termin-begin))
echo "rtorrent install took $((difftimelps / 60)) minutes and $((difftimelps % 60)) seconds"
