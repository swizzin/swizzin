#! /bin/bash
# Mango installer by flying_sausages for Swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

## Downloading the binary

function _install_mango () {
    # Slow connection debugging necessities
    if [[ ! -f /tmp/mango.bin ]]; then 
        echo "Downloading binary" | tee -a $log
        dlurl=$(curl -s https://api.github.com/repos/hkalexling/Mango/releases/latest | grep "browser_download_url" | head -1 | cut -d\" -f 4)
        if [[ $? != 0 ]]; then
            echo "Failed to query github"
            exit 1
        fi
        wget "${dlurl}" -O /tmp/mango.bin >> $log 2>&1
    fi

    mangodir="/opt/mango"

    mkdir -p "$mangodir"
    cp /tmp/mango.bin $mangodir/mango.bin
    chmod +x "$mangodir"/mango.bin
}

## Creating config

function _mkconf_mango () {
cat > "$mangodir/config.yml" <<CONF
port: 9003
library_path: $mangodir/library
db_path: $mangodir/mango.db
scan_interval_minutes: 5
log_level: info
upload_path: $mangodir/uploads
disable_ellipsis_truncation: false
mangadex:
  base_url: https://mangadex.org
  api_url: https://mangadex.org/api
  download_wait_seconds: 5
  download_retries: 4
  download_queue_db_path: $mangodir/queue.db
CONF
}

##### Resucing the admin password

function _initialise_mango () {
    echo "Initialising Mango"
    $mangodir/mango.bin --config=$mangodir/config.yml > $mangodir/pass &
    sleep 5
    pkill mango.bin >> $log 2>&1

    mangouser=$(grep "password" $mangodir/pass | head -1 | cut -d\" -f 4)
    mangopass=$(grep "password" $mangodir/pass | head -1 | cut -d\" -f 8)
    rm $mangodir/pass

    echo "Please use the following credentials to log in to mango. You can find them saved into /root/mango.info"
    echo "  User: \"$mangouser\"" | tee -a /root/mango.info
    echo "  Pass: '$mangopass'" | tee -a /root/mango.info
}

##### Creating systemd unit

function _mkservice_mango(){
    useradd mango --system -d "$mangodir" >> $log 2>&1
    sudo chown -R mango:mango $mangodir 

cat > /etc/systemd/system/mango.service <<SYSD
# Service file example for Mango
[Unit]
Description=Mango - Manga Server and Web Reader
After=network.target

[Service]
User=mango
ExecStart=$mangodir/mango.bin --config=$mangodir/config.yml
Restart=on-abort
TimeoutSec=20

[Install]
WantedBy=multi-user.target
SYSD

    systemctl daemon-reload >> $log 2>&1
    systemctl enable --now mango >> $log 2>&1
}



########## MAIN


_install_mango
_mkconf_mango
_initialise_mango
_mkservice_mango



touch /install/.mango.lock
