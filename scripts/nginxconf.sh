#!/bin/bash
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

if [[ -f /install/.rtorrent.lock ]]; then
  cd /srv
  if [[ ! -d /srv/rutorrent ]]; then git clone https://github.com/Novik/ruTorrent.git rutorrent >>$log 2>&1; fi
  chown -R www-data:www-data rutorrent
  rm -rf /srv/rutorrent/plugins/throttle
  rm -rf /srv/rutorrent/plugins/extratio
  rm -rf /srv/rutorrent/plugins/rpc
  rm -rf /srv/rutorrent/conf/config.php
  cat >/srv/rutorrentconf/config.php<<RUC
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
fi

if [[ -f /install/.syncthing.lock ]]; then
cat > /etc/nginx/apps/syncthing.conf <<SYNC
location /syncthing/ {
  include /etc/nginx/conf.d/proxy.conf;
  proxy_pass              http://localhost:8384/;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SYNC
fi

if [[ -f /install/.subsonic.lock ]]; then
cat > /etc/nginx/apps/subsonic.conf <<SUB
location /subsonic/ {
  proxy_set_header        Host \$host;
  proxy_set_header        X-Real-IP \$remote_addr;
  proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header        X-Forwarded-Proto \$scheme;

  proxy_pass              http://localhost:4040/subsonic;

  proxy_read_timeout      600s;
  proxy_send_timeout      600s;

  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SUB
fi

if [[ -f /install/.sabnzbd.lock ]]; then
  cat > /etc/nginx/apps/sabnzbd.conf <<SAB
location /sabnzbd {
    include /etc/nginx/conf.d/proxy.conf;
    proxy_pass        http://127.0.0.1:65080/sabnzbd;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SAB

if [[ -f /install/.sickrage.lock ]]; then
  cat > /etc/nginx/apps/sickrage.conf <<SRC
location /sickrage {
    include /etc/nginx/conf.d/proxy.conf;
    proxy_pass        http://127.0.0.1:8081/sickrage;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SRC
fi

if [[ -f /install/.sonarr.lock ]]; then
  cat > /etc/nginx/apps/sonarr.conf <<SONARR
location /sonarr {
    include /etc/nginx/conf.d/proxy.conf;
    proxy_pass        http://127.0.0.1:8989/sonarr;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
SONARR
fi

for u in "${users[@]}"; do

  if [[ -f /install/.rtorrent.lock ]]; then
    port=$(cat /home/${u}/.rtorrent.rc | grep scgi | cut -d: -f2)
    mkdir -p /srv/rutorrent/conf/users/${u}/

    cat >/srv/rutorrent/conf/users/${u}/config.php<<RUU
<?php
\$topDirectory = '/home/${u}';
\$scgi_port = $port;
\$XMLRPCMountPoint = "/${u}";
\$quotaUser = "${u}";
?>
RUU
    chown -R www-data.www-data /srv/rutorrent

    cat > /etc/nginx/apps/rutorrent.${u}.conf <<RUC
location /${u} {
include scgi_params;
scgi_pass 127.0.0.1:$port;
}

location /rutorrent {
alias /srv/rutorrent;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd;
}
RUC
  fi

  if [[ -f /install/.autodl.lock ]]; then
    IRSSI_PORT=$(cat /home/${u}/.autodl2.cfg | grep port | cut -d= -f2 | sed 's/ //g' )
    IRSSI_PASS=$(cat /home/${u}/.autodl2.cfg | grep password | cut -d= -f2 | sed 's/ //g' )
    sed -i '/?>/d' /srv/rutorrent/conf/users/${u}/config.php
    echo "\$autodlPort = \"$IRSSI_PORT\";" >> /srv/rutorrent/conf/users/${u}/config.php
    echo "\$autodlPassword = $IRSSI_PASS;" >> /srv/rutorrent/conf/users/${u}/config.php
    echo "?>" >> /srv/rutorrent/conf/users/${u}/config.php
  fi


done
