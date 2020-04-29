#! /bin/bash
# Webmin installer
# flying_sausages for swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

_install_webmin () {
    echo "Installing Webmin repo"
    echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
    wget http://www.webmin.com/jcameron-key.asc >> $log 2>&1
    sudo apt-key add jcameron-key.asc >> $log 2>&1
    rm jcameron-key.asc
    echo "Fetching updates"
    apt-get update >> $log 2>&1
    echo "Installing Webmin from apt"
    apt-get install webmin -yq >> $log 2>&1
}

_get_domain_for_webmin () {
    if [[ -z $webmin_referers ]]; then
        if [[ -f /install/.letsencrypt.lock ]]; then 
            webmin_referers=$(grep "server_name" /etc/nginx/sites-enabled/default |head -1|sed 's/^\s*//g'|cut -d ' ' -f2 | cut -d\; -f1)
        else
            guess=$(grep "server_name" /etc/nginx/sites-enabled/default |head -1|sed 's/^\s*//g'|cut -d ' ' -f2 | cut -d\; -f1)
            if [[ $guess = '_' ]]; then 
                guess=''
            fi

            if [[ -n $guess ]]; then
                guesstext="\nBelow is a possible match from your nginx configuration."
            fi
            webmin_referers=$(whiptail --inputbox "Enter your host's domain or IP address, which you expect to find webmind under.\ne.g. \"sub.domain.com\", \"123.234.32.21\", etc.${guesstext}" 10 50 "${guess}" 3>&1 1>&2 2>&3); exitstatus=$?; if [ "$exitstatus" = 1 ]; then return 1; fi
        fi
    fi
    echo $webmin_referers
}

_webmin_conf () {
    if [[ -f /install/.nginx.lock ]]; then
        
        bash /etc/swizzin/scripts/nginx/webmin.sh
        #TODO figure out if there's a cleaner way to get this from nginx or something
        referers=$(_get_domain_for_webmin)
        echo "If you change domain/IP in the future, please edit /etc/webmin/config"
        cat >> /etc/webmin/config << EOF
webprefix=/webmin
webprefixnoredir=1
referers=${referers}
EOF
        cat >> /etc/webmin/miniserv.conf << EOF
bind=127.0.0.1
sockets=
EOF
    fi
    systemctl reload webmin
}




_install_webmin
_webmin_conf

touch /install/.webmin.lock