#!/bin/bash
# ruTorrent installation and nginx configuration
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx does not appear to be installed, ruTorrent requires a webserver to function. Please install nginx first before installing this package."
    exit 1
fi

function rutorrent_install() {
    apt_install sox geoip-database

    mkdir -p /srv
    if [[ ! -d /srv/rutorrent ]]; then
        echo_progress_start "Cloning rutorrent"
        git clone --recurse-submodules https://github.com/Novik/ruTorrent.git /srv/rutorrent >> "$log" 2>&1 || {
            echo_error "Failed to clone rutorrent"
            exit 1
        }
        chown -R www-data:www-data /srv/rutorrent
        rm -rf /srv/rutorrent/plugins/throttle
        rm -rf /srv/rutorrent/plugins/_cloudflare
        rm -rf /srv/rutorrent/plugins/extratio
        rm -rf /srv/rutorrent/plugins/rpc
        rm -rf /srv/rutorrent/conf/config.php
        echo_progress_done "RuTorrent cloned"
    fi

    echo_progress_start "Cloning some essential themes and plugins"
    sed -i 's/useExternal = false;/useExternal = "mktorrent";/' /srv/rutorrent/plugins/create/conf.php
    sed -i 's/pathToCreatetorrent = '\'\''/pathToCreatetorrent = '\''\/usr\/bin\/mktorrent'\''/' /srv/rutorrent/plugins/create/conf.php
    sed -i "s/\$pathToExternals\['sox'\] = ''/\$pathToExternals\['sox'\] = '\/usr\/bin\/sox'/g" /srv/rutorrent/plugins/spectrogram/conf.php

    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    install_rar

    if [[ ! -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
        git clone https://github.com/QuickBox/club-QuickBox /srv/rutorrent/plugins/theme/themes/club-QuickBox >> "$log" 2>&1
        perl -pi -e "s/\$defaultTheme \= \"\"\;/\$defaultTheme \= \"club-QuickBox\"\;/g" /srv/rutorrent/plugins/theme/conf.php
    fi

    if [[ ! -d /srv/rutorrent/plugins/filemanager ]]; then
        cd /srv/rutorrent/plugins/
        svn co https://github.com/nelu/rutorrent-thirdparty-plugins/trunk/filemanager >> "$log" 2>&1
        chown -R www-data: /srv/rutorrent/plugins/filemanager
        chmod -R +x /srv/rutorrent/plugins/filemanager/scripts

        cat > /srv/rutorrent/plugins/filemanager/conf.php << FMCONF
<?php

\$fm['tempdir'] = '/tmp';
\$fm['mkdperm'] = 755;

// set with fullpath to binary or leave empty
\$pathToExternals['rar'] = '$(which rar)';
\$pathToExternals['zip'] = '$(which zip)';
\$pathToExternals['unzip'] = '$(which unzip)';
\$pathToExternals['tar'] = '$(which tar)';

// archive mangling, see archiver man page before editing
\$fm['archive']['types'] = array('rar', 'zip', 'tar', 'gzip', 'bzip2');
\$fm['archive']['compress'][0] = range(0, 5);
\$fm['archive']['compress'][1] = array('-0', '-1', '-9');
\$fm['archive']['compress'][2] = \$fm['archive']['compress'][3] = \$fm['archive']['compress'][4] = array(0);

?>
FMCONF
    fi

    if [[ ! -d /srv/rutorrent/plugins/ratiocolor ]]; then
        cd /srv/rutorrent/plugins
        svn co https://github.com/Gyran/rutorrent-ratiocolor.git/trunk ratiocolor >> "$log" 2>&1
        sed -i "s/changeWhat = \"cell-background\";/changeWhat = \"font\";/g" /srv/rutorrent/plugins/ratiocolor/init.js
    fi

    if [[ ! -d /srv/rutorrent/plugins/logoff ]]; then
        cd /srv/rutorrent/plugins
        wget -q https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz
        tar xf logoff-1.3.tar.gz
        rm -rf logoff-1.3.tar.gz
        chown -R www-data: logoff
    fi
    echo_progress_done "Plugins downloaded"

    if [[ -f /install/.quota.lock ]] && [[ -z $(grep quota /srv/rutorrent/plugins/diskspace/action.php) ]]; then
        cat > /srv/rutorrent/plugins/diskspace/action.php << 'DSKSP'
<?php
#################################################################################
##  [Quick Box - action.php modified for quota systems use]
#################################################################################
# QUICKLAB REPOS
# QuickLab _ packages:   https://github.com/QuickBox/quickbox_rutorrent-plugins
# LOCAL REPOS
# Local _ packages   :   ~/QuickBox/rtplugins
# Author             :   QuickBox.IO
# URL                :   https://plaza.quickbox.io
#
#################################################################################
  require_once( '../../php/util.php' );
  if (isset($quotaUser) && file_exists('/install/.quota.lock')) {
    $total = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $3*1024}'");
    $used = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $2*1024}'");
    $free = sprintf($total - $used);
    cachedEcho('{ "total": '.$total.', "free": '.$free.' }',"application/json");
  } else {
      cachedEcho('{ "total": '.disk_total_space($topDirectory).', "free": '.disk_free_space($topDirectory).' }',"application/json");
  }
?>
DSKSP
    fi

    cat > /srv/rutorrent/conf/config.php << RUC
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
//\$scgi_host = "127.0.0.1";

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
"bzip2" => '/bin/bzip2',
"pgrep" => '/usr/bin/pgrep',
"python" => '/usr/bin/python2',
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
}

function rutorrent_nginx_config() {
    if [[ ! -f /etc/nginx/apps/rutorrent.conf ]]; then
        cat > /etc/nginx/apps/rutorrent.conf << RUM
location /rutorrent {
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~ \.php$ {
    fastcgi_split_path_info ^(.+\.php)(/.+)\$;
    fastcgi_pass unix:/run/php/$sock.sock;
    fastcgi_param SCRIPT_FILENAME \$request_filename;
    include fastcgi_params;
    fastcgi_index index.php;
  }
}
RUM
    fi

    if [[ ! -f /etc/nginx/apps/rindex.conf ]]; then
        cat > /etc/nginx/apps/rindex.conf << RIN
location /rtorrent.downloads {
  alias /home/\$remote_user/torrents/rtorrent;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  
  location ~* \.php$ {

  } 
}
RIN
    fi
}

function rutorrent_user_config() {
    for u in "${users[@]}"; do
        if [[ ! -f /srv/rutorrent/conf/users/${u}/config.php ]]; then
            mkdir -p /srv/rutorrent/conf/users/${u}/
            cat > /srv/rutorrent/conf/users/${u}/config.php << RUU
<?php
\$topDirectory = '/home/${u}';
\$scgi_port = 0;
\$scgi_host = "unix:///var/run/${u}/.rtorrent.sock";
\$XMLRPCMountPoint = "/${u}";
\$quotaUser = "${u}";
?>
RUU
        fi

        if [[ ! -f /etc/nginx/apps/${u}.scgi.conf ]]; then
            cat > /etc/nginx/apps/${u}.scgi.conf << RUC
location /${u} {
include scgi_params;
scgi_pass unix:/var/run/${u}/.rtorrent.sock;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd.d/htpasswd.${u};
}
RUC
        fi
    done
}

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))
codename=$(lsb_release -cs)
phpversion=$(php_service_version)
sock="php${phpversion}-fpm"
if [[ ! -f /install/.rutorrent.lock ]]; then
    rutorrent_install
fi
rutorrent_nginx_config
rutorrent_user_config

restart_php_fpm
chown -R www-data.www-data /srv/rutorrent
echo_progress_start "Reloading nginx"
systemctl reload nginx >> $log 2>&1
echo_progress_done
touch /install/.rutorrent.lock
