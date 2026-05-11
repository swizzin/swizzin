#!/bin/bash
#
# [ swizzin :: Install plexmediaserver package]
# Originally authored by: JMSolo for QuickBox
# Modifications to QuickBox package by: liara / PastaGringo
# Maintained and updated for swizzin by: liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Modifications for/by swizzin copyright (C) 2019 swizzin.ltd
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

master=$(cut -d: -f1 < /root/.master.info)

echo_info "Please visit https://www.plex.tv/claim, login, copy your plex claim token to your clipboard and paste it here. This will automatically claim your server! Otherwise, you can leave this blank and to tunnel to the port instead."
echo_query "Insert your Plex claim token" "e.g. 'claim-...' or blank"
read 'claim'

#versions=https://plex.tv/api/downloads/1.json
#wgetresults="$(wget "${versions}" -O -)"
#releases=$(grep -ioe '"label"[^}]*' <<<"${wgetresults}" | grep -i "\"distro\":\"ubuntu\"" | grep -m1 -i "\"build\":\"linux-ubuntu-x86_64\"")
#latest=$(echo ${releases} | grep -m1 -ioe 'https://[^\"]*')

echo_progress_start "Installing plex keys and sources ... "
apt_install apt-transport-https
curl -sL https://downloads.plex.tv/plex-keys/PlexSign.v2.key | gpg --yes --dearmor -o /usr/share/keyrings/plexmediaserver.v2.gpg
# Clean up old/legacy Plex source files before writing our managed entry.
rm -f /etc/apt/sources.list.d/plexmediaserver.list /etc/apt/sources.list.d/plexmediaserver.sources
# repo.plex.tv is the signed Plex APT endpoint; downloads.plex.tv/repo/deb may be unsigned.
echo "deb [signed-by=/usr/share/keyrings/plexmediaserver.v2.gpg] https://repo.plex.tv/deb public main" > /etc/apt/sources.list.d/plex.list
echo

apt_update
echo_progress_done "Sources and keys retrieved and installed"

apt_install plexmediaserver

if [[ ! -d /var/lib/plexmediaserver ]]; then
    mkdir -p /var/lib/plexmediaserver
fi
perm=$(stat -c '%U' /var/lib/plexmediaserver/)
if [[ ! $perm == plex ]]; then
    chown -R plex:plex /var/lib/plexmediaserver
fi
usermod -a -G ${master} plex

if [[ -n $claim ]]; then
    sleep 5
    #shellcheck source=sources/functions/plex
    . /etc/swizzin/sources/functions/plex
    claimPlex ${claim}
fi

systemctl restart plexmediaserver >> $log 2>&1

touch /install/.plex.lock

echo_success "Plex installed"
