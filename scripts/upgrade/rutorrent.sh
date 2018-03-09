#!/bin/bash
# ruTorrent upgrade wrapper
# Author: liara
# Does not update from git remote at this time...

if [[ -d /srv/rutorrent ]] && [[ ! -f /install/.rutorrent.lock ]]; then
  touch /install/.rutorrent.lock
fi

if [[ ! -f /install/.rutorrent.lock ]]; then
  echo "ruTorrent doesn't appear to be installed. Script exiting."
  exit 1
fi
PID=$$
cd /srv/rutorrent/plugins
plugs=($(echo */|sed 's/\///g'))
cp -a /srv/rutorrent /srv/rutorrent.${PID}
cd /srv/rutorrent
git reset > /dev/null 2>&1
git checkout -- php/settings.php > /dev/null 2>&1
git pull
if grep -q network.port php/settings.php; then
  :
else
  git apply /etc/swizzin/sources/network.port.patch > /dev/null 2>&1
fi
find . -user root -exec chown www-data: {} \;
cd /srv/rutorrent/plugins
newplugs=($(echo */|sed 's/\///g'))
for i in ${newplugs[@]}; do
  if [[ ! ${plugs[@]} =~ $i ]]; then
    echo "Removing git pull cruft of $i"
    rm -rf $i
  fi
done

echo "Previous ruTorrent directory has been backed up to /srv/rutorrent.${PID}. Please ensure ruTorrent is behaving as expected before you remove this backup!"

#bash /usr/local/bin/swizzin/nginx/rutorrent.sh
systemctl force-reload nginx
