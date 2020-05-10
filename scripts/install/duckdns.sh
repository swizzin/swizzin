#! /bin/bash
# Duck DNS installer
# Flying_sausages 2020 swizzin gplv3

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

duckPath="/opt/duckdns"
duckLog="$duckPath/duck.log"
duckScript="$duckPath/duck.sh"

if [[ -z $duck_subdomain ]] || [[ -z $duck_token ]]; then
    echo "This script requires an account at duckdns.org."
    echo "You can always refer to the swizzin documentation for guidance."
    echo "https://docs.swizzin.ltd/applications/duckdns"
    echo

    read -p "Would you like to continue? (y/N)" yn
    case $yn in
        [Yy]* ) : ;;
        * ) exit 0;;
    esac
fi


if [[ -z $duck_subdomain ]]; then
    echo -ne "Enter your full Duck DNS domain (e.g mydomain.duckdns.org): "
    read -r fulldomain
    subdomain="${fulldomain%%.*}"
    domain="${fulldomain#*.}"
    if [ "$domain" != "duckdns.org" ] && [ "$domain" != "$subdomain" ] || [ "$subdomain" = "" ]; then 
        echo "[Error] Invalid domain name. Program will now quit."
        exit 0
    fi
else
    subdomain=$duck_subdomain
    echo "Domain set to $subdomain.duckdns.org"
fi


if [[ -z $duck_token ]]; then 
    echo -ne "Enter your Duck DNS Token value: "
    read -r token
    token=$(echo "$token" | tr -d '\040\011\012\015')
    echo
else
    token=$duck_token
fi

if [[ ! -d $duckPath ]]; then
    mkdir -p $duckPath
fi

echo "echo url=\"https://www.duckdns.org/update?domains=$subdomain&token=$token&ip=\" | curl -k -o $duckLog -K -" > $duckScript
chmod 700 $duckScript

checkCron=$( crontab -l | grep -c $duckScript )
if [ "$checkCron" -eq 0 ] 
then
    # Add cronjob
    echo "Adding Cron job for Duck DNS"
    crontab -l | { cat; echo "*/5 * * * * bash $duckScript"; } | crontab - > $log 2>&1
fi

if [[ -f $duckLog ]]; then
    rm $duckLog
    touch $duckLog
fi
echo "Registering domain with Duck DNS"
bash $duckScript > $log 2>&1
duckResponse=$( cat $duckLog )
echo "Duck DNS server response : $duckResponse"
if [ "$duckResponse" != "OK" ]
then
    echo "[Error] Duck DNS did not update correctly. Please check your settings or run the setup again."
else
    echo "Duck DNS setup complete."
    if [[ -f /install/.nginx.lock ]]; then
        echo
        echo "Please install LetsEncrypt using the domain \"$subdomain.duckdns.org\""
        echo "Consult https://docs.swizzin.org/guides/troubleshooting in case you need help setting up your port forwarding."
    fi
fi

touch /install/.duckdns.lock