#! /bin/bash
# Mango installer by flying_sausages for Swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

mangodir="/opt/mango"
mangousr="mango"


# Downloading the latest binary
function _install_mango () {
    echo "Downloading binary" | tee -a $log
    dlurl=$(curl -s https://api.github.com/repos/hkalexling/Mango/releases/latest | grep "browser_download_url" | head -1 | cut -d\" -f 4)
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to query github"
        exit 1
    fi

    mkdir -p "$mangodir"

    wget "${dlurl}" -O $mangodir/mango.bin >> $log 2>&1
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to download binary"
        exit 1
    fi

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

# Retrieving the admin password
function _initialise_mango () {
    echo "Initialising Mango"
    $mangodir/mango.bin --config=$mangodir/config.yml > $mangodir/pass &
    sleep 5
    pkill mango.bin >> $log 2>&1

    mangoacc=$(grep "password" $mangodir/pass | head -1 | cut -d\" -f 4)
    mangopass=$(grep "password" $mangodir/pass | head -1 | cut -d\" -f 8)
    rm $mangodir/pass

    echo "Please use the following credentials to log in to mango. You can find them saved into /root/mango.info"
    echo "  User: \"$mangoacc\"" | tee -a /root/mango.info
    echo "  Pass: '$mangopass'" | tee -a /root/mango.info
    chmod o+rx $mangodir $mangodir/library
}

# Creating systemd unit
function _mkservice_mango(){
    useradd $mangousr --system -d "$mangodir" >> $log 2>&1
    sudo chown -R $mangousr:$mangousr $mangodir 

cat > /etc/systemd/system/mango.service <<SYSD
# Service file example for Mango
[Unit]
Description=Mango - Manga Server and Web Reader
After=network.target

[Service]
User=$mangousr
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

if [[ -f /install/.nginx.lock ]]; then 
    bash /etc/swizzin/scripts/nginx/mango.sh
fi


touch /install/.mango.lock
