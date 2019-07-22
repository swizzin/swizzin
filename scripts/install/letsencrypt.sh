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
    echo "This script is meant to be used in conjunction with nginx and it has not been installed. Please install nginx first and restart this installer."
    exit 1
fi    

ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

echo -e "Enter domain name to secure with LE"
read -e hostname

read -p "Do you want to apply this certificate to your swizzin default conf? (y/n) " yn
case $yn in
  [Yy] )
      main=yes
      ;;
  [Nn] )
      main=no
      ;;
  * ) echo "Please answer (y)es or (n)o.";;
esac

if [[ $main == yes ]]; then
  sed -i "s/server_name .*;/server_name $hostname;/g" /etc/nginx/sites-enabled/default
fi

read -p "Is your DNS managed by CloudFlare? (y/n) " yn
case $yn in
  [Yy] )
      cf=yes
      ;;
  [Nn] )
      cf=no
      ;;
  * ) echo "Please answer (y)es or (n)o.";;
esac


if [[ ${cf} == yes ]]; then
  read -p "Does the record for this subdomain already exist? (y/n) " yn
  case $yn in
      [Yy] )
      record=yes
      ;;
      [Nn] )
      record=no
      ;;
      * )
      echo "Please answer (y)es or (n)o."
      ;;
  esac
  

  echo -e "Enter CF API key"
  read -e api

  echo -e "CF Email"
  read -e email

  export CF_Key="${api}"
  export CF_Email="${email}"

  valid=$(curl -X GET "https://api.cloudflare.com/client/v4/user" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json")
  if [[ $valid == *"\"success\":false"* ]]; then
    message="API CALL FAILED. DUMPING RESULTS:\n$valid"
    echo -e "$message"
    exit 1
  fi

  if [[ ${record} == no ]]; then
    echo -e "Zone Name (example.com)"
    read -e zone
    zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    addrecord=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" -H "X-Auth-Email: $email" -H "X-Auth-Key: $api" -H "Content-Type: application/json" --data "{\"id\":\"$zoneid\",\"type\":\"A\",\"name\":\"$hostname\",\"content\":\"$ip\",\"proxied\":true}")
    if [[ $addrecord == *"\"success\":false"* ]]; then
      message="API UPDATE FAILED. DUMPING RESULTS:\n$addrecord"
      echo -e "$message"
      exit 1
    else
      message="DNS record added for $hostname at $ip"
      echo "$message"
    fi
  fi
fi

apt-get -y -q install socat > /dev/null 2>&1

if [[ ! -f /root/.acme.sh/acme.sh ]]; then
  curl https://get.acme.sh | sh
fi

mkdir -p /etc/nginx/ssl/${hostname}
chmod 700 /etc/nginx/ssl

if [[ ${cf} == yes ]]; then
  /root/.acme.sh/acme.sh --issue --dns dns_cf -d ${hostname} || { echo "ERROR: Certificate could not be issued. Please check your info and try again"; exit 1; }
else
  if [[ $main = yes ]]; then
    /root/.acme.sh/acme.sh --issue --nginx -d ${hostname} || { echo "ERROR: Certificate could not be issued. Please check your info and try again"; exit 1; }
  else
    service nginx stop
    /root/.acme.sh/acme.sh --issue --standalone -d ${hostname} || { echo "ERROR: Certificate could not be issued. Please check your info and try again"; exit 1; }
    sleep 1
    systemctl start nginx
  fi
fi

/root/.acme.sh/acme.sh --install-cert -d ${hostname} --key-file /etc/nginx/ssl/${hostname}/key.pem --fullchain-file /etc/nginx/ssl/${hostname}/fullchain.pem --ca-file /etc/nginx/ssl/${hostname}/chain.pem --reloadcmd "service nginx force-reload"
if [[ $main == yes ]]; then
  sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
  sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default
fi

# Add LE certs to ZNC, if installed.
if [[ -f /install/.znc.lock ]]; then
    # Check for LE cert, and copy it if available.
    chkhost="$(find /etc/nginx/ssl/* -maxdepth 1 -type d | cut -f 5 -d '/')"
    if [[ -n $chkhost ]]; then
        defaulthost=$(cat /etc/nginx/sites-enabled/default | grep -m 1 server_name | awk '{print $2}' | sed 's/;//g')
        cat /etc/nginx/ssl/"$defaulthost"/{key,fullchain}.pem > /home/znc/.znc/znc.pem
        crontab -l > newcron.txt | sed -i  "s#cron#cron --post-hook \"cat /etc/nginx/ssl/"$defaulthost"/{key,fullchain}.pem > /home/znc/.znc/znc.pem\"#g" newcron.txt | crontab newcron.txt | rm newcron.txt
    fi
fi

# Add LE certs to VSFTPD, if installed.
if [[ -f /install/.vsftpd.lock ]]; then
    # Check for LE cert, and copy it if available.
    chkhost="$(find /etc/nginx/ssl/* -maxdepth 1 -type d | cut -f 5 -d '/')"
    if [[ -n $chkhost ]]; then
        defaulthost=$(cat /etc/nginx/sites-enabled/default | grep -m 1 server_name | awk '{print $2}' | sed 's/;//g')
        sed -i "s#rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem#rsa_cert_file=/etc/nginx/ssl/${defaulthost}/fullchain.pem#g" /etc/vsftpd.conf
        sed -i "s#rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key#rsa_private_key_file=/etc/nginx/ssl/${defaulthost}/key.pem#g" /etc/vsftpd.conf
        systemctl restart vsftpd
    fi
fi

systemctl reload nginx
