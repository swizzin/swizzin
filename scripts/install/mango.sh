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
    mkdir -p "$mangodir"/library
    if [[ -f /tmp/mango.bin ]]; then 
        #testing hack, please remove
        cp /tmp/mango.bin $mangodir/mango.bin
    else 
        wget "${dlurl}" -O $mangodir/mango.bin >> $log 2>&1
    fi
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to download binary"
        exit 1
    fi

    chmod +x "$mangodir"/mango.bin
    chmod o+rx $mangodir $mangodir/library

    useradd $mangousr --system -d "$mangodir" >> $log 2>&1
    sudo chown -R $mangousr:$mangousr $mangodir 

}

## Creating config
function _mkconf_mango () {
    mkdir -p $mangodir/.config/mango
cat > "$mangodir/.config/mango/config.yml" <<CONF
#Please do not edit as swizzin will be replacing this file as updates roll out. 
port: 9003
base_url: /mango
library_path: $mangodir/library
db_path: $mangodir/.config/mango/mango.db
scan_interval_minutes: 5
log_level: info
upload_path: $mangodir/uploads
disable_ellipsis_truncation: false
mangadex:
  base_url: https://mangadex.org
  api_url: https://mangadex.org/api
  download_wait_seconds: 5
  download_retries: 4
  download_queue_db_path: $mangodir/.config/mango/queue.db
CONF
    sudo chown $mangousr:$mangousr -R $mangodir
}

# Creating systemd unit
function _mkservice_mango(){
    cat > /etc/systemd/system/mango.service <<SYSD
# Service file example for Mango
[Unit]
Description=Mango - Manga Server and Web Reader
After=network.target

[Service]
User=$mangousr
ExecStart=$mangodir/mango.bin
Restart=on-abort
TimeoutSec=20

[Install]
WantedBy=multi-user.target
SYSD
    systemctl daemon-reload >> $log 2>&1
    systemctl enable --now mango >> $log 2>&1
}

# Creating all users' accounts
_addusers_mango () {
    echo "Adding user(s)"
    for u in "${users[@]}"; do
     if [[ $u == $master ]]; then 
        pass=$(cut -d: -f2 < /root/.master.info)
        su $mangousr -c "$mangodir/mango.bin admin user add -u $master -p $pass --admin"
     else
        pass=$(cut -d: -f2 < /root/"$u".info)
        passlen=${#pass}
        if [[ $passlen -ge 6 ]]; then 
            su $mangousr -c "$mangodir/mango.bin admin user add -u $u -p $pass"
        else
            echo "$u's password too short for mango, please change the password using 'box chpasswd $u' (Setting up using random, discareded password)"
            pass=$(openssl rand -base64 10)
            su $mangousr -c "$mangodir/mango.bin admin user add -u $u -p $pass"
        fi
     fi
    done
}

########## MAIN

master=$(cut -d: -f1 < /root/.master.info)
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $1 ]]; then
  users=("$1")
  _addusers_mango
  exit 0
fi

_install_mango
_mkconf_mango
_addusers_mango
_mkservice_mango
    
if [[ -f /install/.nginx.lock ]]; then 
    bash /etc/swizzin/scripts/nginx/mango.sh
fi

echo "Please use your existing credentials when logging in."
echo "You can access your files in $mangodir/library" | tee -a /root/mango.info

touch /install/.mango.lock
