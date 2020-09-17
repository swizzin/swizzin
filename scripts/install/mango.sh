#! /bin/bash
# Mango installer by flying_sausages for Swizzin 2020

# shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

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
        echo "Failed to query github" | tee -a $log
        exit 1
    fi

    mkdir -p "$mangodir"
    mkdir -p "$mangodir"/library
    wget "${dlurl}" -O $mangodir/mango >> $log 2>&1
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to download binary" | tee -a $log
        exit 1
    fi

    chmod +x $mangodir/mango
    chmod o+rx -R $mangodir $mangodir/library

    useradd $mangousr --system -d "$mangodir" >> $log 2>&1
    sudo chown -R $mangousr:$mangousr $mangodir 

}

## Creating config
function _mkconf_mango () {
    mkdir -p $mangodir/.config/mango
cat > "$mangodir/.config/mango/config.yml" <<CONF
#Please do not edit as swizzin will be replacing this file as updates roll out. 
port: 9003
base_url: /
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
  chapter_rename_rule: '[Vol.{volume} ][Ch.{chapter} ]{title|id}'
  manga_rename_rule: '{title}'
CONF
    chown $mangousr:$mangousr -R $mangodir
    chmod o-rwx $mangodir/.config
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
ExecStart=$mangodir/mango
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
        pass=$(_get_user_password "$u")
        if [[ $u = "$master" ]]; then 
            su $mangousr -c "$mangodir/mango admin user add -u $master -p $pass --admin"
        else
            # pass=$(cut -d: -f2 < /root/"$u".info)
            passlen=${#pass}
            if [[ $passlen -ge 6 ]]; then 
                su $mangousr -c "$mangodir/mango admin user add -u $u -p $pass"
            else
                pass=$(openssl rand -base64 32)
                echo "WARNING: $u's password too short for mango, please change the password using 'box chpasswd $u'" | tee -a $log
                echo "Mango account temporarily set up with the password '$pass'"
                su $mangousr -c "$mangodir/mango admin user add -u $u -p $pass"
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
