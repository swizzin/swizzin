#!/bin/bash
if [[ -f /install/.btsync.lock ]]; then
  if [[ ! -f /etc/systemd/system/resilio-sync.service ]]; then
    systemctl stop resilo-sync
    MASTER=$(cut -d: -f1 < /root/.master.info)
    BTSYNCIP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
    cat > /etc/resilio-sync/config.json <<RSCONF
{
    "listening_port" : 0,
    "storage_path" : "/home/${MASTER}/.config/resilio-sync/",
    "pid_file" : "/var/run/resilio-sync/sync.pid",
    "agree_to_EULA": "yes",

    "webui" :
    {
        "listen" : "BTSGUIP:8888"
    }
}
RSCONF
    cp -a /lib/systemd/system/resilio-sync.service /etc/systemd/system/
      sed -i "s/=rslsync/=${MASTER}/g" /etc/systemd/system/resilio-sync.service
    sed -i "s/rslsync:rslsync/${MASTER}:${MASTER}/g" /etc/systemd/system/resilio-sync.service
    systemctl daemon-reload
    sed -i "s/BTSGUIP/$BTSYNCIP/g" /etc/resilio-sync/config.json
    systemctl restart resilio-sync
  fi
fi