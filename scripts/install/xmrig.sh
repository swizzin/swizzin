#!/bin/bash
# xmrig installer
# Author: liara
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
user=$(cut -d: -f1 < /root/.master.info)
noexec=$(grep "/tmp" /etc/fstab | grep noexec)
# GitHub's /releases/latest page is now a bodyless redirect, so scraping it returns an empty
# version and `git clone --branch v` fails, cascading into every later step. Resolve the tag
# via the redirect target instead (github_latest_version returns e.g. "v6.21.0").
latest=$(github_latest_version xmrig/xmrig)

while true; do
    echo_query "Please choose a dev donation amount. Minimum fee is 1%."
    read -r fee
    floatReg='^([0-9]*\.[0-9])$'
    if [[ ! $fee =~ $floatReg ]]; then
        if (($(echo "$fee < 1" | bc -l))); then
            echo_info "Minimum fee is 1"
        else
            echo_info "Configurable fee has been set to $fee"
            break
        fi
    else
        echo_warn "Must not be a decimal! E.g. 5"
    fi
done

password=$(hostname)

if [[ -z $address ]]; then
    address=pool.supportxmr.com:5555
    echo_query "Please enter your desired pool and port. Default: pool.supportxmr.com:5555"
    read 'custom'
    address="${custom:-$address}"

    echo_query "Enter wallet address for miner. If you do not enter an address, the installer will default to a 100% donation: "
    read 'wallet'
    if [[ -z $wallet ]]; then
        echo_info "Thank you for your donation!"
        fee=100
        address=diglett.swizzin.ltd:5555
        wallet=$(hostname)
    fi
fi

apt_install screen git build-essential cmake libuv1-dev libmicrohttpd-dev libssl-dev libhwloc-dev

cd /tmp
echo_progress_start "Cloning xmrig"
if [[ -z $latest ]]; then
    echo_error "Could not determine the latest xmrig release. Setup will exit."
    exit 1
fi
rm_if_exists /tmp/xmrig
git clone --depth 1 --single-branch --branch ${latest} https://github.com/xmrig/xmrig.git >> $log 2>&1 || {
    echo_error "Cloning xmrig ${latest} failed. Setup will exit."
    exit 1
}
echo_progress_done

cd xmrig || {
    echo_error "xmrig source directory missing after clone. Setup will exit."
    exit 1
}
sed -i "s/donate.ssl.xmrig.com/diglett.swizzin.ltd/g" src/net/strategies/DonateStrategy.cpp
sed -i "s/donate.v2.xmrig.com/diglett.swizzin.ltd/g" src/net/strategies/DonateStrategy.cpp
sed -i "s/kDefaultDonateLevel = 5/kDefaultDonateLevel = $fee/g" src/donate.h

if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
fi
echo_progress_start "Building xmrig"
mkdir build
cd build
cmake .. >> $log 2>&1
make -j$(nproc) >> $log 2>&1
if [[ ! -f xmrig ]]; then
    echo_error "xmrig build did not produce a binary. Check ${log}. Setup will exit."
    exit 1
fi
mv xmrig /usr/local/bin/
echo_progress_done

echo_progress_start "Configuring xmrig"
mkdir -p /home/${user}/.xmrig
cp ../src/config.json /home/${user}/.xmrig
chown -R ${user}: /home/${user}/.xmrig

sed -i 's/"coin":.*/"coin": "monero",/g' /home/${user}/.xmrig/config.json
sed -i 's/"nicehash":.*/"nicehash": true,/g' /home/${user}/.xmrig/config.json
sed -i "s/donate.v2.xmrig.com:3333/${address}/g" /home/${user}/.xmrig/config.json
sed -i "s/YOUR_WALLET_ADDRESS/${wallet}/g" /home/${user}/.xmrig/config.json
sed -i "s/YOUR_WALLET_ADDRESS/${wallet}/g" /home/${user}/.xmrig/config.json
cd /tmp
rm -rf xmrig

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi

# Trixie ships no /etc/sysctl.conf by default (settings live in /etc/sysctl.d/), so grepping
# it errors. Use a drop-in, which is the supported way to add sysctl settings.
if [[ ! -f /etc/sysctl.d/99-xmrig.conf ]]; then
    echo "vm.nr_hugepages=128" > /etc/sysctl.d/99-xmrig.conf
    sysctl -p /etc/sysctl.d/99-xmrig.conf >> $log 2>&1
fi

cat > /etc/systemd/system/xmrig.service << XMR
[Unit]
Description=xmrig miner
After=network.target

[Service]
Type=forking
User=$user
Group=$user
KillMode=none
ExecStart=/usr/bin/screen -d -m -fa -S xmrig /usr/local/bin/xmrig -c /home/${user}/.xmrig/config.json
ExecStop=/usr/bin/screen -X -S xmrig quit

[Install]
WantedBy=multi-user.target
XMR

echo_progress_done

echo_progress_start "Starting xmrig"
systemctl enable -q --now xmrig 2>&1 | tee -a $log
echo_progress_done
touch /install/.xmrig.lock
echo_success "Xmrig Installed"
