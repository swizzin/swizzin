#!/bin/bash

function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }

function _depends() {
	APT='subversion dos2unix bc screen zip unzip sysstat build-essential
	dstat automake libtool libcppunit-dev libssl-dev pkg-config libcurl4-openssl-dev
	libsigc++-2.0-dev unzip curl libncurses5-dev yasm  fontconfig libfontconfig1
	libfontconfig1-dev mediainfo mktorrent'
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
				wget -q ${libtorrentloc}
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
				wget -q ${rtorrentloc}
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
    if [[ ! -d /srv/rutorrent ]]; then git clone https://github.com/Novik/ruTorrent.git rutorrent >>$log 2>&1; fi
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

execute = {sh,-c,/usr/bin/php /var/www/rutorrent/php/initplugins.php ${user} &}

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
rm -rf /srv/rutorrent/conf/config.php
mkdir -p ${rutorrent}conf/users/${user}/
cat >${rutorrent}conf/config.php<<RUC
<?php
// configuration parameters

// for snoopy client
@define('HTTP_USER_AGENT', 'Mozilla/5.0 (Windows; U; Windows NT 5.1; pl; rv:1.9) Gecko/2008052906 Firefox/3.0', true);
@define('HTTP_TIME_OUT', 30, true); // in seconds
@define('HTTP_USE_GZIP', true, true);
\$httpIP = null; // IP string. Or null for any.

@define('RPC_TIME_OUT', 5, true); // in seconds

@define('LOG_RPC_CALLS', false, true);
@define('LOG_RPC_FAULTS', true, true);

// for php
@define('PHP_USE_GZIP', false, true);
@define('PHP_GZIP_LEVEL', 2, true);

\$do_diagnostic = true;
\$log_file = '/tmp/rutorrent_errors.log'; // path to log file (comment or leave blank to disable logging)

\$saveUploadedTorrents = true; // Save uploaded torrents to profile/torrents directory or not
\$overwriteUploadedTorrents = false; // Overwrite existing uploaded torrents in profile/torrents directory or make unique name

// \$topDirectory = '/home'; // Upper available directory. Absolute path with trail slash.
\$forbidUserSettings = false;

//\$scgi_port = 5000;
\$scgi_host = "127.0.0.1";

// For web->rtorrent link through unix domain socket
// (scgi_local in rtorrent conf file), change variables
// above to something like this:
//
//\$scgi_port = 0;
//\$scgi_host = "unix:///tmp/rtorrent.sock";

//\$XMLRPCMountPoint = "/RPC2"; // DO NOT DELETE THIS LINE!!! DO NOT COMMENT THIS LINE!!!

\$pathToExternals = array(
"php" => '/usr/bin/php', // Something like /usr/bin/php. If empty, will be found in PATH.
"curl" => '/usr/bin/curl', // Something like /usr/bin/curl. If empty, will be found in PATH.
"gzip" => '/bin/gzip', // Something like /usr/bin/gzip. If empty, will be found in PATH.
"id" => '/usr/bin/id', // Something like /usr/bin/id. If empty, will be found in PATH.
"stat" => '/usr/bin/stat', // Something like /usr/bin/stat. If empty, will be found in PATH.
);

\$localhosts = array( // list of local interfaces
"127.0.0.1",
"localhost",
);

\$profilePath = '../share'; // Path to user profiles
\$profileMask = 0777; // Mask for files and directory creation in user profiles.
// Both Webserver and rtorrent users must have read-write access to it.
// For example, if Webserver and rtorrent users are in the same group then the value may be 0770.

?>
RUC

cat >${rutorrent}conf/users/${user}/config.php<<RUU
<?php
\$topDirectory = '/home/${user}';
\$scgi_port = $port;
\$XMLRPCMountPoint = "/${user}";
\$quotaUser = "${user}";
?>
RUU
chown -R www-data.www-data ${rutorrent}conf/users/ 2>> $log

cat > /etc/nginx/apps/rutorrent.conf <<RUC
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
systemctl force-reload nginx
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
service rtorrent@${user} start
}

export DEBIAN_FRONTEND=noninteractive

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
rtorrentloc='http://rtorrent.net/downloads/rtorrent-'$rtorrentver'.tar.gz'
libtorrentloc='http://rtorrent.net/downloads/libtorrent-'$libtorrentver'.tar.gz'
xmlrpc='https://svn.code.sf.net/p/xmlrpc-c/code/stable'
log=/root/logs/install.log
distribution=$(lsb_release -is)
release=$(lsb_release -rs)
codename=$(lsb_release -cs)
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

	  echo "Install rTorrent Dependencies ... ";_depends && echo ${ok}
		echo "Building xmlrpc-c from source ... ";_xmlrpc
		echo "Building libtorrent from source ... ";_libtorrent
		echo "Building rtorrent from source ... ";_rtorrent
		echo "Making ${user} directory structure ... ";_makedirs
		echo "Setting permissions on ${user} ... ";_perms
    if [[ -f /install/.nginx.lock ]]; then
    echo "Installing rutorrent into /srv ... ";_rutorrent
		echo "Writing ${user} rutorrent config.php file ... ";_ruconf
		echo "Installing plugins ... ";_plugins
    fi
		echo "setting up rtorrent.rc ... ";_rconf;_systemd
		touch /install/.rtorrent.lock
termin=$(date +"%s")
difftimelps=$((termin-begin))
echo "rtorrent install took $((difftimelps / 60)) minutes and $((difftimelps % 60)) seconds"
