#!/bin/bash
# Let's Encrypt Installa
# nginx flavor by liara

ip=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')

echo -e "Enter domain name to secure with LE"
read -e hostname


while true; do
    read -p "Is your DNS managed by CloudFlare?" yn
    case $yn in
        [Yy]* ) cf=yes;;
        [Nn]* ) cf=no;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [[ ${cf} == yes ]]; then
  while true; do
      read -p "Does the record for this subdomain already exist?" yn
      case $yn in
          [Yy]* ) record=yes;;
          [Nn]* ) record=no;;
          * ) echo "Please answer yes or no.";;
      esac
  done

  echo -e "Enter CF API key"
  read -e api

  echo -e "CF Email"
  read -e email

  export CF_Key="${api}"
  export CF_Email="${email}"
  if [[ ${record} == no ]]; then
    if [[ $hostname == *.*.* ]]; then
      zone=$(expr match "$hostname" '.*\.\(.*\..*\)')
    else
      zone=$hostname
    fi
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

if [[ ! -f /root/.acme.sh/acme.sh ]]; then
  curl https://get.acme.sh | sh
fi

mkdir -p /etc/nginx/ssl/${hostname}

if [[ ${cf} == yes ]]; then
  /root/.acme.sh/acme.sh --issue --dns dns_cf -d ${hostname}
else
  /root/.acme.sh/acme.sh --issue --nginx -d ${hostname}
fi
/root/.acme.sh/acme.sh --install-cert -d ${hostname} --key-file /etc/nginx/ssl/${hostname}/key.pem --fullchain-file /etc/nginx/ssl/${hostname}/fullchain.pem --ca-file /etc/nginx/ssl/${hostname}/chain.pem --reloadcmd "service nginx force-reload"

sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default

systemctl reload nginx
