#!/bin/bash
# Flood for rtorrent installation script for swizzin
# Author: liara

if [[ ! -f /install/.rtorrent.lock ]]; then
    echo_error "Flood is a GUI for rTorrent, which doesn't appear to be installed. Exiting."
    exit 1
fi
#shellcheck source=sources/functions/npm
. /etc/swizzin/sources/functions/npm
npm_install

if [[ ! $(which node-gyp) ]]; then
    echo_progress_start "Installing node-gyp"
    npm install -g node-gyp >> $log 2>&1
    echo_progress_done
fi

cat > /etc/systemd/system/flood@.service << SYSDF
[Unit]
Description=Flood rTorrent Web UI
After=network.target

[Service]
User=%i
Group=%i
WorkingDirectory=/home/%i/.flood
ExecStart=/usr/bin/npm start --production /home/%i/.flood


[Install]
WantedBy=multi-user.target
SYSDF

users=($(cut -d: -f1 < /etc/htpasswd))
for u in "${users[@]}"; do
    if [[ ! -d /home/$u/.flood ]]; then
        echo_progress_start "Configuring flood for $u"
        salt=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
        port=$(shuf -i 3501-4500 -n 1)
        cd /home/$u
        echo_progress_start "Cloning source code"
        git clone https://github.com/jfurrow/flood.git .flood >> $log 2>&1
        echo_progress_done "Source cloned"
        chown -R $u: .flood
        cd .flood
        cp -a config.template.js config.js
        sed -i "s/floodServerPort: 3000/floodServerPort: $port/g" config.js
        sed -i "s/socket: false/socket: true/g" config.js
        sed -i "s/socketPath.*/socketPath: '\/var\/run\/${u}\/.rtorrent.sock'/g" config.js
        sed -i "s/secret: 'flood'/secret: '$salt'/g" config.js
        if [[ ! -f /install/.nginx.lock ]]; then
            sed -i "s/floodServerHost: '127.0.0.1'/floodServerHost: '0.0.0.0'/g" config.js
        fi
        echo_progress_start "Building Flood for $u. This might take some time..."
        su - $u -c "cd /home/$u/.flood; npm install" >> $log 2>&1
        echo_progress_done "Flood built for $u"
        if [[ ! -f /install/.nginx.lock ]]; then
            su - $u -c "cd /home/$u/.flood; npm run build" >> $log 2>&1
            systemctl start flood@$u
            echo_info "Flood port for $u is $port"
        elif [[ -f /install/.nginx.lock ]]; then
            bash /usr/local/bin/swizzin/nginx/flood.sh $u
            systemctl start flood@$u
            systemctl reload nginx
        fi
        systemctl enable -q flood@$u 2>&1 | tee -a $log
        echo_progress_done "Flood for $u configured"
    fi
done
echo_success "Flood installed"
touch /install/.flood.lock
