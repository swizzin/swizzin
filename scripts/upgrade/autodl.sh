#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
readarray -t users < <(_get_user_list)

wget -q "$(curl -sL http://git.io/vlcND | jq .assets[0].browser_download_url -r)" -O /tmp/autodl-irssi.zip >> $log 2>&1 || {
    echo_error "Autodl download failed, please check the log"
    exit 1
}

for u in "${users[@]}"; do
    cd "/home/${u}/.irssi/scripts/"
    rm -rf AutodlIrssi
    rm -f autodl-irssi.pl
    rm -f autorun/autodl-irssi.pl
    cp /tmp/autodl-irssi.zip .
    unzip -o autodl-irssi.zip >> "${log}" 2>&1
    rm autodl-irssi.zip
    cp autodl-irssi.pl autorun/
    chown -R $u: /home/${u}/.irssi/
done

rm /tmp/autodl-irssi.zip
