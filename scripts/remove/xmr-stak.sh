#!/bin/bash
# xmr-stak(-cpu) removal

user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now -q xmr
su - ${user} -c "screen -X -S xmr quit" > /dev/null 2>&1
rm -rf /home/${user}/.xmr
rm -rf /etc/systemd/system/xmr.service
rm -rf /usr/local/bin/xmr-stak-cpu
rm -rf /usr/local/bin/xmr-stak
rm -rf /install/.xmr-stak.lock
rm -rf /install/.xmr-stak-cpu.lock
