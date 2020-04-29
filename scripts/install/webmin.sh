#! /bin/bash
# Webmin installer
# flying_sausages for swizzin 2020

_install_webmin () {
    echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
    wget http://www.webmin.com/jcameron-key.asc
    sudo apt-key add jcameron-key.asc
    rm jcameron-key.asc
    apt-get update
    apt-get install webmin -yq
}

_get_refers () {
    if [[ -z $webmin_referers ]]; then
        referers=$(whiptail --inputbox "Enter your host's domain or IP address, which you expect to find webmind under.\ne.g. \"sub.domain.com\", \"123.234.32.21\", etc." 10 50 3>&1 1>&2 2>&3); exitstatus=$?; if [ "$exitstatus" = 1 ]; then exit 0; fi
    fi
    echo $webmin_referers
}

_webmin_conf () {
    referers=${_get_refers}
    # /etc/webmin/config
    #TODO get nginx domain name
    cat >> /etc/webmin/config << EOF
webprefix=/webmin
webprefixnoredir=1
referers=${webmin_referers}
EOF
    cat >> /etc/webmin/miniserv.conf << EOF
bind=127.0.0.1
sockets=
EOF
    echo "If you change domain/IP in the future, please edit /etc/webmin/config"
    systemctl reload webmin
}



bash /etc/swizzin/scripts/nginx/webmin.sh

_install_webmin
_webmin_conf

touch /install/.webmin.lock