#!/bin/bash

begin=$(date +"%s")
if [[ -z $rtorrentver ]]; then
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
rtorrentdl='http://rtorrent.net/downloads/rtorrent-'$rtorrentver'.tar.gz'
libtorrentloc='http://rtorrent.net/downloads/libtorrent-'$libtorrentver'.tar.gz'
xmlrpc='https://svn.code.sf.net/p/xmlrpc-c/code/stable'
log=/root/logs/install.log


distribution=$(lsb_release -is)
release=$(lsb_release -rs)
codename=$(lsb_release -cs)

if [[ $codename == "jessie" ]]; then
  echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" > /etc/apt/sources.list.d/dotdeb-php7-$(lsb_release -sc).list
  echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" >> /etc/apt/sources.list.d/dotdeb-php7-$(lsb_release -sc).list
  wget -q https://www.dotdeb.org/dotdeb.gpg
  sudo apt-key add dotdeb.gpg >> /dev/null 2>&1
  apt-get -y update
fi

function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }

function _depends() {
	APT='subversion dos2unix bc sudo screen zip unzip sysstat build-essential
	dstat automake libtool libcppunit-dev libssl-dev pkg-config libcurl4-openssl-dev
	libsigc++-2.0-dev unzip curl libncurses5-dev yasm  fontconfig libfontconfig1
	libfontconfig1-dev mediainfo libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl
	libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl mktorrent'
	for depends in $APT; do
	apt-get -qq -y --yes --force-yes install "$depends" >/dev/null 2>&1 || (echo "APT-GET could not find all the required sources. Script Ending." && echo "${warning}" && exit 1)
	done
  if [[ $distribution == "Debian" ]]; then
    cd /tmp
  	wget -q http://www.rarlab.com/rar/rarlinux-x64-5.4.0.tar.gz
  	tar -xzf rarlinux-x64-5.4.0.tar.gz >/dev/null 2>&1
  	cp rar/*rar /bin >/dev/null 2>&1
  	rm -rf rarlinux*.tar.gz >/dev/null 2>&1
  	rm -rf /tmp/rar >/dev/null 2>&1
  else
    apt-get -y install unrar
  fi
}

function _xmlrpc() {
				cd "/tmp"
				svn co https://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c
				cd xmlrpc-c
				./configure --prefix=/usr --disable-cplusplus >>$log 2>&1
				make -j${nproc} >>$log 2>&1
				make install >>$log 2>&1
}

function _libtorrent() {
				cd "/tmp"
				rm -rf xmlrpc-c >>$log 2>&1
				wget -q ${libtorrentdl}
				tar -xvf libtorrent-* >>$log 2>&1
				cd libtorrent-* >>$log 2>&1
				./autogen.sh >>$log 2>&1
				./configure --prefix=/usr >>$log 2>&1
				make -j${nproc} >>$log 2>&1
				make install >>$log 2>&1
}

function _rtorrent() {
				cd "/tmp"
				rm -rf libtorrent-* >>$log 2>&1
				wget -q ${rtorrentdl}
				tar -xzvf rtorrent-* >>$log 2>&1
				cd rtorrent-*
				./configure --prefix=/usr --with-xmlrpc-c >/dev/null 2>&1
				make -j${nproc} >/dev/null 2>&1
				make install >/dev/null 2>&1
				cd "/tmp"
				ldconfig >/dev/null 2>&1
				rm -rf rtorrent-* >/dev/null 2>&1
}

function _rutorrent() {
    cd /srv
    if [[ ! -d /srv/rutorrent ]]; then git clone https://github.com/Novik/ruTorrent.git >>$log 2>&1; fi
    chown -R www-data:www-data rutorrent
    rm -rf /srv/rutorrent/plugins/throttle
    rm -rf /srv/rutorrent/plugins/extratio
    rm -rf /srv/rutorrent/plugins/rpc
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
# -- END HERE --
EOF
echo ${ok}
chown ${user}.${user} -R /home/${user}/.rtorrent.rc
}


function _makedirs() {
	mkdir -p /home/${user}/torrents/rtorrent 2>> $log
	chown ${user}.${user} /home/${user}/{torrents,.sessions} 2>> $log
	usermod -a -G www-data ${user} 2>> $log
	usermod -a -G ${user} www-data 2>> $log
}


function _perms() {
	chown -R ${user}.${user} /home/${user}/ 2>> $log
	sudo -u ${user} chmod 755 /home/${user}/ 2>> $log
	mkdir /srv/rutorrent/conf/users/${user} 2>> $log
	chsh -s /bin/bash ${user}
	if grep ${user} /etc/sudoers.d/swizzin >/dev/null 2>&1 ; then echo "No sudoers modification made ... " ; else	echo "${user}	ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/swizzin ; fi
}

function _ruconf() {
cat >${rutorrent}conf/users/${user}/config.php<<EOF
<?php
	@define('HTTP_USER_AGENT', 'Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0', true);
	@define('HTTP_TIME_OUT', 30, true);
	@define('HTTP_USE_GZIP', true, true);
	\$httpIP = null;
	@define('RPC_TIME_OUT', 5, true);
	@define('LOG_RPC_CALLS', false, true);
	@define('LOG_RPC_FAULTS', true, true);
	@define('PHP_USE_GZIP', false, true);
	@define('PHP_GZIP_LEVEL', 2, true);
	\$schedule_rand = 10;
	\$do_diagnostic = true;
	\$log_file = '/tmp/errors.log';
	\$saveUploadedTorrents = true;
	\$overwriteUploadedTorrents = false;
	\$topDirectory = '/home/${user}/';
	\$forbidUserSettings = false;
	\$scgi_port = $port;
	\$scgi_host = "localhost";
	\$XMLRPCMountPoint = "/${user}";
	\$pathToExternals = array("php" => '',"curl" => '',"gzip" => '',"id" => '',"stat" => '',);
	\$localhosts = array("127.0.0.1", "localhost",);
	\$profilePath = '../share';
	\$profileMask = 0777;
	\$diskuser = "";
	\$quotaUser = "${user}";
EOF
chown -R www-data.www-data ${rutorrent}conf/users/ 2>> $log

cat > /etc/nginx/sites-enabled/rutorrent.conf <<RUC
location /${user} {
include scgi_params;
scgi_pass 127.0.0.1:$port;
}

location /rutorrent {
alias /srv/rutorrent;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd;
}
RUC
echo ${ok}
}

function _plugins() {
	sed -i 's/useExternal = false;/useExternal = "mktorrent";/' ${rutorrent}plugins/create/conf.php
	cd /srv/rutorrent/plugins/theme/themes
	git clone https://github.com/QuickBox/club-QuickBox club-QuickBox >/dev/null 2>&1
	perl -pi -e "s/\$defaultTheme \= \"\"\;/\$defaultTheme \= \"club-QuickBox\"\;/g" /srv/rutorrent/plugins/theme/conf.php
	cd /srv/rutorrent/plugins
	chown -R www-data.www-data ${rutorrent}
echo ${ok}
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
}
_startme() { service rtorrent@${user} start ; }

export DEBIAN_FRONTEND=noninteractive

user=$(cat /root/.master.info | cut -d: -f1)
ok=$(echo -e "[ \e[0;32mDONE\e[00m ]")
logdir="/root/logs"
rutorrent="/srv/rutorrent/"
port=$((RANDOM%64025+1024))
portend=$((${port} + 1500))
warning=$(echo -e "[ \e[1;91mWARNING\e[0m ]")
mkcores=$(nproc | awk '{print $1/2}')
#plugindir="plugins3.7"
rdisk=$(free -m | grep "Mem" | awk '{printf "%.0f\n", $2/10}'); if [[ $rdisk -gt 500 ]];then installdir="/tmp/ramdisk";else installdir="/tmp"; fi

	  echo -n "Building Dependencies ... ";_depends && echo ${ok}
		echo -n "Building xmlrpc-c from source ... ";_xmlrpc
		echo -n "Building libtorrent from source ... ";_libtorrent
		echo -n "Building rtorrent from source ... ";_rtorrent
		echo -n "Installing rutorrent into /srv ... ";_rutorrent
		echo -n "Making ${user} directory structure ... ";_makedirs
		echo -n "Setting permissions on ${user} ... ";_perms
    if [[ -f /install/.nginx.lock ]]; then
		echo -n "Writing ${user} rutorrent config.php file ... ";_ruconf
		echo -n "Installing plugins ... ";_plugins
    fi
		echo -n "setting up rtorrent.rc ... ";_rconf;_systemd
		touch /install/.rtorrent.lock
termin=$(date +"%s")
difftimelps=$((termin-begin))
echo "rtorrent install took $((difftimelps / 60)) minutes and $((difftimelps % 60)) seconds"
