#! /bin/bash
if [[ -f /install/.wireguard.lock ]]; then

# Generate QR code png of user config for easy access
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
for u in $(_get_user_list); do
    qrpath="/home/$u/.wireguard/wgqr.png"
    if [[ ! -f $qrpath ]];then 
        echo "Generating $qrpath"
        qrencode -o "$qrpath" -s 10 -t png < /home/"$u"/.wireguard/"$u".conf
    fi
done

fi