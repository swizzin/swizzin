#!/bin/bash
# Flood for rtorrent installation script for swizzin
# Author: liara

if [[ ! -f /install/.rtorrent.lock ]]; then
  echo "Flood is a GUI for rTorrent, which doesn't appear to be installed. Exiting."
  exit 1
fi

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

if [[ ! $(which npm) ]] || [[ $(node --version) =~ "v6" ]]; then
  bash <(curl -sL https://deb.nodesource.com/setup_8.x) >> $log 2>&1
  apt-get -y -q install nodejs build-essential >> $log 2>&1
fi

cat > /etc/systemd/system/flood@.service <<SYSDF
[Unit]
Description=Flood rTorrent Web UI
After=network.target

[Service]
User=%I
Group=%I
WorkingDirectory=/home/%I/.flood
ExecStart=/usr/bin/npm start --production /home/%I/.flood


[Install]
WantedBy=multi-user.target
SYSDF

users=($(cat /etc/htpasswd | cut -d ":" -f 1))
for u in "${users[@]}"; do
  if [[ ! -d /home/$u/.flood ]]; then
    salt=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    port=$(shuf -i 3501-4500 -n 1)
    scgi=$(cat /home/$u/.rtorrent.rc | grep scgi | cut -d: -f2)
    cd /home/$u
    git clone https://github.com/jfurrow/flood.git .flood >> $log 2>&1
    chown -R $u: .flood
    cd .flood
    cp -a config.template.js config.js
    sed -i "s/floodServerPort: 3000/floodServerPort: $port/g" config.js
    sed -i "s/port: 5000/port: $scgi/g" config.js
    sed -i "s/secret: 'flood'/secret: '$salt'/g" config.js
    if [[ ! -f /install/.nginx.lock ]]; then
      sed -i "s/floodServerHost: '127.0.0.1'/floodServerHost: '0.0.0.0'/g" config.js
    fi
    echo "Building Flood for $u. This might take some time..."
    echo ""
    sudo -H -u $u npm install >> $log 2>&1
    sudo -H -u $u npm run build >> $log 2>&1
    systemctl enable flood@$u > /dev/null 2>&1
    systemctl start flood@$u
    if [[ ! -f /install/.nginx.lock ]]; then
      echo "Flood port for $u is $port"
    fi
  fi
done

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/flood.sh
fi

touch /install/.flood.lock