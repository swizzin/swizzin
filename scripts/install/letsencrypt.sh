#!/bin/bash
# Let's Encrypt Installa
# nginx flavor by liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ ! -f /install/.nginx.lock ]]; then
	echo_error "This script is meant to be used in conjunction with nginx and it has not been installed. Please install nginx first and restart this installer."
	exit 1
fi

. /etc/swizzin/sources/functions/letsencrypt
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

if [[ -z $LE_hostname ]]; then 
	echo -e "Enter domain name to secure with LE"
	read -e hostname
else 
	hostname=$LE_hostname
fi

if [[ -z $LE_defaultconf ]]; then 
    read -p "Do you want to apply this certificate to your swizzin default conf? (y/n) " yn
    case $yn in
        [Yy] )
		main=yes
		;;
	[Nn])
		main=no
		;;
        * ) echo "Please answer (y)es or (n)o.";;
    esac
else
    main=$LE_defaultconf
fi

if [[ $main == yes ]]; then
	sed -i "s/server_name .*;/server_name $hostname;/g" /etc/nginx/sites-enabled/default
fi

if [ -n $LE_cf_api ] || [ -n $LE_cf_email ] || [ -n $LE_cf_zone ]; then
    LE_bool_cf=yes
fi

if [[ -z $LE_bool_cf ]]; then 
    read -p "Is your DNS managed by CloudFlare? (y/n) " yn
    case $yn in
        [Yy] )
		cf=yes
		;;
	[Nn])
		cf=no
		;;
        * ) echo "Please answer (y)es or (n)o.";;
    esac
else
    [[ $LE_bool_cf = "yes" ]] && cf=yes
    [[ $LE_bool_cf = "no" ]] && cf=no
fi

if [[ ${cf} == yes ]]; then

	if [[ $hostname =~ (\.cf$|\.ga$|\.gq$|\.ml$|\.tk$) ]]; then
		echo_error "Cloudflare does not support API calls for the following TLDs: cf, .ga, .gq, .ml, or .tk"
		exit 1
	fi

    if [[ -n $LE_cf_zone ]]; then
        LE_cf_zoneexists=no
    fi

    if [[ -z $LE_cf_zoneexists ]]; then
        read -p "Does the record for this subdomain already exist? (y/n) " yn
	case $yn in
		[Yy])
			record=yes
			;;
		[Nn])
			record=no
			;;
		*)
			echo_warn "Please answer (y)es or (n)o."
			;;
	esac
    else
        [[ $LE_cf_zoneexists = "yes" ]] && zone=yes
        [[ $LE_cf_zoneexists = "no" ]] && zone=no
    fi

    if [[ -z $LE_cf_api ]]; then 
        echo -e "Enter CF API key"
	read -e api
    else 
        api=$LE_cf_api
    fi

    if [[ -z $LE_cf_email ]]; then 
        echo -e "CF Email"
	read -e email
    else 
        api=$LE_cf_email
    fi

	export CF_Key="${api}"
	export CF_Email="${email}"

	valid=$(curl -X GET "https://api.cloudflare.com/client/v4/user" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json")
	if [[ $valid == *"\"success\":false"* ]]; then
		message="API CALL FAILED. DUMPING RESULTS:\n$valid"
		echo_error "$message"
		exit 1
	fi

	if [[ ${record} == no ]]; then

        if [[ -z $LE_cf_zone ]]; then 
            echo -e "Zone Name (example.com)"
            read -e zone
        else
            zone=$LE_cf_zone
        fi

		zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
		addrecord=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json" --data "{\"id\":\"$zoneid\",\"type\":\"A\",\"name\":\"$hostname\",\"content\":\"$ip\",\"proxied\":true}")
		if [[ $addrecord == *"\"success\":false"* ]]; then
			message="API UPDATE FAILED. DUMPING RESULTS:\n$addrecord"
			echo_error "$message"
			exit 1
		else
			message="DNS record added for $hostname at $ip"
			echo_info "$message"
		fi
	fi
fi

apt_install socat

if [[ ! -f /root/.acme.sh/acme.sh ]]; then
	echo_progress_start "Installing ACME script"
	curl https://get.acme.sh | sh >> $log 2>&1
	echo_progress_done
fi

mkdir -p /etc/nginx/ssl/${hostname}
chmod 700 /etc/nginx/ssl

echo_progress_start "Registering certificates"
if [[ ${cf} == yes ]]; then
	/root/.acme.sh/acme.sh --force --issue --dns dns_cf -d ${hostname} >> $log 2>&1 || {
		echo_error "Certificate could not be issued."
		exit 1
	}
else
	if [[ $main = yes ]]; then
		/root/.acme.sh/acme.sh --force --issue --nginx -d ${hostname} >> $log 2>&1 || {
			echo_error "Certificate could not be issued."
			exit 1
		}
	else
		systemctl stop nginx
		/root/.acme.sh/acme.sh --force --issue --standalone -d ${hostname} --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" >> $log 2>&1 || {
			echo_error "Certificate could not be issued. Please check your info and try again"
			exit 1
		}
		sleep 1
		systemctl start nginx
	fi
fi
echo_progress_done "Certificate acquired"

echo_progress_start "Installing certificate"
/root/.acme.sh/acme.sh --force --install-cert -d ${hostname} --key-file /etc/nginx/ssl/${hostname}/key.pem --fullchain-file /etc/nginx/ssl/${hostname}/fullchain.pem --ca-file /etc/nginx/ssl/${hostname}/chain.pem --reloadcmd "systemctl reload nginx"
if [[ $main == yes ]]; then
	sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
	sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default
fi
echo_progress_done "Certificate installed"

# Add LE certs to ZNC, if installed.
if [[ -f /install/.znc.lock ]]; then
	le_znc_hook
fi

# Add LE certs to VSFTPD, if installed.
if [[ -f /install/.vsftpd.lock ]]; then
	le_vsftpd_hook
	systemctl restart vsftpd
fi

systemctl reload nginx

echo_success "Letsencrypt installed"
