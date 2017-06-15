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
  log=/root/logs/install.log
  echo "Updating system and grabbing core dependencies."
  apt-get -qq -y --force-yes update >> ${log} 2>&1
  apt-get -qq -y --force-yes upgrade >> ${log} 2>&1
  apt-get -qq -y --force-yes install whiptail lsb-release git sudo nano fail2ban apache2-utils htop vnstat tcl tcl-dev build-essential >> ${log} 2>&1
  nofile=$(grep "DefaultLimitNOFILE=3072" /etc/systemd/system.conf)
  if [[ ! "$nofile" ]]; then echo "DefaultLimitNOFILE=3072" >> /etc/systemd/system.conf; fi
  echo "Cloning swizzin repo to localhost"
  git clone https://github.com/lizaSB/swizzin.git /etc/swizzin >> ${log} 2>&1
  ln -s /etc/swizzin/scripts/ /usr/local/bin/swizzin/
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
  if [[ -d /home/"$user" ]]; then
					echo "User directory already exists ... "
					_skel
					cd /etc/skel
					cp -R * /home/$user/
					echo "Changing password to new password"
					echo "${user}:${pass}" | chpasswd >/dev/null 2>&1
					htpasswd -cb /etc/.htpasswd $user $pass
					chown -R $user:$user /home/${user}
    else
      echo -en "Creating new user \e[1;95m$user\e[0m ... "
      _skel
      useradd "${user}" -m -G www-data
      echo "${user}:${pass}" | chpasswd >/dev/null 2>&1
      htpasswd -cb /etc/.htpasswd $user $pass
  fi
}

function _choices() {
  packages=()
	extras=()
  #locks=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "-" -f 2 | sort -d))
	locks=(rtorrent deluge autodl panel vsftpd ffmpeg quota)
  for i in "${locks[@]}"; do
    app=${i}
    if [[ ! -f /install/.$app.lock ]]; then
      packages+=("$i" '""')
    fi
  done
	whiptail --title "Install Software" --checklist --noitem --separate-output "Choose your clients and core features." 15 26 7 "${packages[@]}" 2>/root/results
	for i in "${packages[@]}"; do
	 touch /tmp/.$i.lock
	done
	locksextra=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "-" -f 2 | sort -d))
	for i in "${locksextra[@]}"; do
		app=${i}
		if [[ ! -f /tmp/.$app.lock ]]; then
			extras+=("$i" '""')
		fi
	done
	whiptail --title "Install Software" --checklist --noitem --separate-output "Make some more choices ^.^ Or don't. idgaf" 15 26 7 "${extras[@]}" 2>/root/results2
}

function _install() {
	readarray packages < /root/results
	readarray extras < /root/results2

	echo -e "Installing nginx & php"

	APT='nginx-full php7.0 php7.0-cli php7.0-fpm php7.0-dev php7.0-curl php7.0-xmlrpc php7.0-json php7.0-mcrypt php7.0-opcache php-geoip'
	for depends in $APT; do
	apt-get -qq -y --yes --force-yes install "$depends" >/dev/null 2>&1 || (echo "APT-GET could not find all the required sources. Script Ending." && echo "${warning}" && exit 1)
	done

	sed -i -e "s/post_max_size = 8M/post_max_size = 64M/" \
					 -e "s/upload_max_filesize = 2M/upload_max_filesize = 92M/" \
					 -e "s/expose_php = On/expose_php = Off/" \
					 -e "s/128M/768M/" \
					 -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" \
					 -e "s/;opcache.enable=0/opcache.enable=1/" \
					 -e "s/;opcache.memory_consumption=64/opcache.memory_consumption=128/" \
					 -e "s/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" \
					 -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=240/" /etc/php/7.0/fpm/php.ini
phpenmod -v 7.0 opcache

	rm -rf /etc/nginx/sites-enabled/default
	cat > /etc/nginx/sites-enabled/default <<NGC
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name serverbabe.io;
	return 301 https://$server_name$request_uri;
}

	# SSL configuration
server {
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;
	ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
	ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
	include snippets/ssl-params.conf;
	client_max_body_size 20M;
	server_tokens off;
	root /srv/;

	index off;



	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		#try_files $uri $uri/ =404;
		try_files $uri $uri/ /index.php$is_args$args;
	}

	location = /favicon.ico { log_not_found off; access_log off; }
	location = /robots.txt { log_not_found off; access_log off; allow all; }
	location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
		expires max;
		log_not_found off;
	}
	# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
	#
	location ~ \.php$ {
		include snippets/fastcgi-php.conf;

		# With php7.0-cgi alone:
	#	fastcgi_pass 127.0.0.1:9000;
	#	# With php7.0-fpm:
		fastcgi_pass unix:/run/php/php7.0-fpm.sock;
	}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	location ~ /\.ht {
		deny all;
	}


}
NGC

mkdir -p /etc/nginx/ssl/
mkdir -p /etc/nginx/snippets/

cd /etc/nginx/ssl
openssl dhparam -out dhparam.pem 2048

cat > /etc/nginx/snippets/ssl-params.conf <<SSC
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 127.0.0.1 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
#add_header X-Frame-Options DENY;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/nginx/ssl/dhparam.pem;
SSC

	for i in "${packages[@]}"; do
		echo -e "Installing $i ";
		bash /usr/local/bin/swizzin/install/$i.sh
	done
	rm /root/results
	for i in "${extras[@]}"; do
		echo -e "Installing $i ";
		bash /usr/local/bin/swizzin/install/$i.sh
	done
	rm /root/results2
}
