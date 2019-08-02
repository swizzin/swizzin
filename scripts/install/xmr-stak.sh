#!/bin/bash
# Automated installer script for xmr-stak
# Written by liara for swizzin
user=$(cut -d: -f1 < /root/.master.info)
noexec=$(grep "/tmp" /etc/fstab | grep noexec)

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

su - ${user} -c "screen -X -S xmr quit" >> $log 2>&1

apt-get install -y -q bc screen >> $log 2>&1

while true; do
echo "Please choose a dev donation amount. Must be a decimal! Minimum fee is 1.0. You must recompile to change this value."
read -r fee
floatReg='^([0-9]*\.[0-9])$'
    if [[ $fee =~ $floatReg ]]; then
        if (( $(echo "$fee < 1.0" | bc -l) )); then
            echo
            echo "Minimum fee is 1.0"
            echo
        else
            echo "Configurable fee has been set to $fee"
            echo
            break
        fi
    else
        echo "Must be a decimal! E.g. 2.0"
        echo
    fi
done

password=$(hostname)

if [[ $fee = "100.0" ]]; then
    fee=99.9
    address=diglett.swizzin.ltd:5555
    wallet=$(hostname)
fi

if [[ -z $address ]]; then
    address=pool.supportxmr.com:5555
    echo "Please enter your desired pool and port. Default: pool.supportxmr.com:5555"
    read -r custom
    address="${custom:-$address}"

    read -p "Enter wallet address for miner. If you do not enter an address, the installer will default to a 100% donation: " 'wallet'
    if [[ -z $wallet ]]; then
        fee=99.9
        address=diglett.swizzin.ltd:5555
        wallet=$(hostname)
    fi
fi

echo "Installing dependencies and compiling xmr-stak"
apt-get -y -qq update >> $log 2>&1
apt-get -y -qq install libmicrohttpd-dev libssl-dev cmake build-essential libhwloc-dev >> $log 2>&1

if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
fi	

cd /tmp
git clone https://github.com/fireice-uk/xmr-stak.git >> $log 2>&1
cd xmr-stak
sed -i "s/= 2.0/= $fee/g" xmrstak/donate-level.hpp
#sed -i 's/donate.xmr-stak.net:6666/diglett.swizzin.ltd:5556/g' xmrstak/misc/executor.cpp
#sed -i 's/donate.xmr-stak.net:3333/diglett.swizzin.ltd:5555/g' xmrstak/misc/executor.cpp
#sed -i 's/donate.xmr-stak.net:8800/diglett.swizzin.ltd:5556/g' xmrstak/misc/executor.cpp
#sed -i 's/donate.xmr-stak.net:5500/diglett.swizzin.ltd:5555/g' xmrstak/misc/executor.cpp
sed -i 's/donate.xmr-stak.net:8822/diglett.swizzin.ltd:5556/g' xmrstak/misc/executor.cpp
sed -i 's/donate.xmr-stak.net:5522/diglett.swizzin.ltd:5555/g' xmrstak/misc/executor.cpp

mkdir build
cd build

if [[ $(lsb_release -sc) == "jessie" ]]; then
    cmake -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF -DCMAKE_LINK_STATIC=ON .. >> $log 2>&1
else
    cmake -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF .. >> $log 2>&1
fi
    make install >> $log 2>&1
    mv bin/xmr-stak /usr/local/bin
    mkdir /home/${user}/.xmr

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi

if [[ -z $(grep vm.nr_hugepages=128 /etc/sysctl.conf) ]]; then
    echo "vm.nr_hugepages=128" >> /etc/sysctl.conf
    sysctl -p
fi

cat > /etc/systemd/system/xmr.service <<XMR
[Unit]
Description=xmr miner
After=network.target

[Service]
Type=forking
User=$user
Group=$user
KillMode=none
ExecStart=/usr/bin/screen -d -m -fa -S xmr /usr/local/bin/xmr-stak -c /home/${user}/.xmr/config.txt -C /home/${user}/.xmr/pools.txt --cpu /home/${user}/.xmr/cpu.txt
ExecStop=/usr/bin/screen -X -S xmr quit

[Install]
WantedBy=multi-user.target
XMR

cat > /home/${user}/.xmr/config.txt <<EOC
/*
 * Network timeouts.
 * Because of the way this client is written it doesn't need to constantly talk (keep-alive) to the server to make 
 * sure it is there. We detect a buggy / overloaded server by the call timeout. The default values will be ok for 
 * nearly all cases. If they aren't the pool has most likely overload issues. Low call timeout values are preferable -
 * long timeouts mean that we waste hashes on potentially stale jobs. Connection report will tell you how long the
 * server usually takes to process our calls.
 *
 * call_timeout - How long should we wait for a response from the server before we assume it is dead and drop the connection.
 * retry_time	- How long should we wait before another connection attempt.
 *                Both values are in seconds.
 * giveup_limit - Limit how many times we try to reconnect to the pool. Zero means no limit. Note that stak miners
 *                don't mine while the connection is lost, so your computer's power usage goes down to idle.
 */
"call_timeout" : 10,
"retry_time" : 30,
"giveup_limit" : 0,

/*
 * Output control.
 * Since most people are used to miners printing all the time, that's what we do by default too. This is suboptimal
 * really, since you cannot see errors under pages and pages of text and performance stats. Given that we have internal
 * performance monitors, there is very little reason to spew out pages of text instead of concise reports.
 * Press 'h' (hashrate), 'r' (results) or 'c' (connection) to print reports.
 *
 * verbose_level - 0 - Don't print anything.
 *                 1 - Print intro, connection event, disconnect event
 *                 2 - All of level 1, and new job (block) event if the difficulty is different from the last job
 *                 3 - All of level 1, and new job (block) event in all cases, result submission event.
 *                 4 - All of level 3, and automatic hashrate report printing
 *
 * print_motd    - Display messages from your pool operator in the hashrate result.
 */
"verbose_level" : 3,
"print_motd" : true,

/*
 * Automatic hashrate report
 *
 * h_print_time - How often, in seconds, should we print a hashrate report if verbose_level is set to 4.
 *                This option has no effect if verbose_level is not 4.
 */
"h_print_time" : 60,

/*
 * Manual hardware AES override
 *
 * Some VMs don't report AES capability correctly. You can set this value to true to enforce hardware AES or
 * to false to force disable AES or null to let the miner decide if AES is used.
 *
 * WARNING: setting this to true on a CPU that doesn't support hardware AES will crash the miner.
 */
"aes_override" : null,

/*
 * LARGE PAGE SUPPORT
 * Large pages need a properly set up OS. It can be difficult if you are not used to systems administration,
 * but the performance results are worth the trouble - you will get around 20% boost. Slow memory mode is
 * meant as a backup, you won't get stellar results there. If you are running into trouble, especially
 * on Windows, please read the common issues in the README.
 *
 * By default we will try to allocate large pages. This means you need to "Run As Administrator" on Windows.
 * You need to edit your system's group policies to enable locking large pages. Here are the steps from MSDN
 *
 * 1. On the Start menu, click Run. In the Open box, type gpedit.msc.
 * 2. On the Local Group Policy Editor console, expand Computer Configuration, and then expand Windows Settings.
 * 3. Expand Security Settings, and then expand Local Policies.
 * 4. Select the User Rights Assignment folder.
 * 5. The policies will be displayed in the details pane.
 * 6. In the pane, double-click Lock pages in memory.
 * 7. In the Local Security Setting – Lock pages in memory dialog box, click Add User or Group.
 * 8. In the Select Users, Service Accounts, or Groups dialog box, add an account that you will run the miner on
 * 9. Reboot for change to take effect.
 *
 * Windows also tends to fragment memory a lot. If you are running on a system with 4-8GB of RAM you might need
 * to switch off all the auto-start applications and reboot to have a large enough chunk of contiguous memory.
 *
 * On Linux you will need to configure large page support "sudo sysctl -w vm.nr_hugepages=128" and increase your
 * ulimit -l. To do do this you need to add following lines to /etc/security/limits.conf - "* soft memlock 262144"
 * and "* hard memlock 262144". You can also do it Windows-style and simply run-as-root, but this is NOT
 * recommended for security reasons.
 *
 * Memory locking means that the kernel can't swap out the page to disk - something that is unlikely to happen on a
 * command line system that isn't starved of memory. I haven't observed any difference on a CLI Linux system between
 * locked and unlocked memory. If that is your setup see option "no_mlck".
 */

/*
 * use_slow_memory defines our behaviour with regards to large pages. There are three possible options here:
 * always  - Don't even try to use large pages. Always use slow memory.
 * warn    - We will try to use large pages, but fall back to slow memory if that fails.
 * no_mlck - This option is only relevant on Linux, where we can use large pages without locking memory.
 *           It will never use slow memory, but it won't attempt to mlock
 * never   - If we fail to allocate large pages we will print an error and exit.
 */
"use_slow_memory" : "no_mlck",

/*
 * TLS Settings
 * If you need real security, make sure tls_secure_algo is enabled (otherwise MITM attack can downgrade encryption
 * to trivially breakable stuff like DES and MD5), and verify the server's fingerprint through a trusted channel.
 *
 * tls_secure_algo - Use only secure algorithms. This will make us quit with an error if we can't negotiate a secure algo.
 */
"tls_secure_algo" : true,

/*
 * Daemon mode
 *
 * If you are running the process in the background and you don't need the keyboard reports, set this to true.
 * This should solve the hashrate problems on some emulated terminals.
 */
"daemon_mode" : false,

/*
 * Output file
 *
 * output_file  - This option will log all output to a file.
 *
 */
"output_file" : "",

/*
 * Built-in web server
 * I like checking my hashrate on my phone. Don't you?
 * Keep in mind that you will need to set up port forwarding on your router if you want to access it from
 * outside of your home network. Ports lower than 1024 on Linux systems will require root.
 *
 * httpd_port - Port we should listen on. Default, 0, will switch off the server.
 */
"httpd_port" : 0,

/*
 * HTTP Authentication
 *
 * This allows you to set a password to keep people on the Internet from snooping on your hashrate.
 * Keep in mind that this is based on HTTP Digest, which is based on MD5. To a determined attacker
 * who is able to read your traffic it is as easy to break a bog door latch.
 *
 * http_login - Login. Empty login disables authentication.
 * http_pass  - Password.
 */ 
"http_login" : "",
"http_pass" : "",
 
/*
 * prefer_ipv4 - IPv6 preference. If the host is available on both IPv4 and IPv6 net, which one should be choose?
 *               This setting will only be needed in 2020's. No need to worry about it now.
 */
"prefer_ipv4" : true,
EOC

cat > /home/${user}/.xmr/pools.txt <<EOP
/*
 * pool_address    - Pool address should be in the form "pool.supportxmr.com:3333". Only stratum pools are supported.
 * wallet_address  - Your wallet, or pool login.
 * rig_id          - Rig identifier for pool-side statistics (needs pool support).
 * pool_password   - Can be empty in most cases or "x".
 * use_nicehash    - Limit the nonce to 3 bytes as required by nicehash.
 * use_tls         - This option will make us connect using Transport Layer Security.
 * tls_fingerprint - Server's SHA256 fingerprint. If this string is non-empty then we will check the server's cert against it.
 * pool_weight     - Pool weight is a number telling the miner how important the pool is. Miner will mine mostly at the pool 
 *                   with the highest weight, unless the pool fails. Weight must be an integer larger than 0.
 *
 * We feature pools up to 1MH/s. For a more complete list see M5M400's pool list at www.moneropools.com
 */
 
"pool_list" :
[
	{"pool_address" : "$address", "wallet_address" : "$wallet", "rig_id" : "", "pool_password" : "${password}", "use_nicehash" : false, "use_tls" : false, "tls_fingerprint" : "", "pool_weight" : 1 },
],

/*
 * Currency to mine. Supported values:
 *
 *    aeon7 (use this for Aeon's new PoW)
 *    bbscoin (automatic switch with block version 3 to cryptonight_v7)
 *    bittube (uses cryptonight_bittube2 algorithm)
 *    freehaven
 *    graft
 *    haven (automatic switch with block version 3 to cryptonight_haven)
 *    intense
 *    masari
 *    monero (use this to support Monero's Oct 2018 fork)
 *    qrl - Quantum Resistant Ledger
 *    ryo
 *    turtlecoin
 *    plenteum
 *
 * Native algorithms which do not depend on any block versions:
 *
 *    # 256KiB scratchpad memory
 *    cryptonight_turtle
 *    # 1MiB scratchpad memory
 *    cryptonight_lite
 *    cryptonight_lite_v7
 *    cryptonight_lite_v7_xor (algorithm used by ipbc)
 *    # 2MiB scratchpad memory
 *    cryptonight
 *    cryptonight_gpu (for Ryo's 14th of Feb fork)
 *    cryptonight_superfast
 *    cryptonight_v7
 *    cryptonight_v8
 *    cryptonight_v8_half (used by masari and stellite)
 *    cryptonight_v8_reversewaltz (used by graft)
 *    cryptonight_v8_zelerius
 *    # 4MiB scratchpad memory
 *    cryptonight_bittube2
 *    cryptonight_haven
 *    cryptonight_heavy
 */

"currency" : "monero",

EOP

chown -R ${user}:${user} /home/${user}/.xmr/
rm -rf /tmp/xmr-stak
touch /install/.xmr-stak.lock
systemctl enable xmr
systemctl start xmr