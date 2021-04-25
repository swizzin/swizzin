#!/usr/bin/env bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
readarray -t users < <(_get_user_list)

echo_progress_start "Downloading autodl-irssi latest release"
wget -q "$(curl -sL http://git.io/vlcND | jq .assets[0].browser_download_url -r)" -O /tmp/autodl-irssi.zip >> $log 2>&1 || {
    echo_error "Autodl download failed, please check the log"
    exit 1
}
echo_progress_done "Release downloaded"

echo_progress_start "Extracting release for each user"
for u in "${users[@]}"; do
    echo_log_only "Extracting for user $u"
    irssipath="/home/${u}/.irssi/scripts"
    rm -rf "$irssipath"/{AutodlIrssi,autodl-irssi.pl,autorun/autodl-irssi.pl}
    unzip -o /tmp/autodl-irssi.zip -d "$irssipath" >> "${log}" 2>&1
    cp "$irssipath"/autodl-irssi.pl "$irssipath"/autorun/
    chown -R "$u": /home/"${u}"/.irssi/
done
echo_progress_done "Release installed for all users"

rm /tmp/autodl-irssi.zip
