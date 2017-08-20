#!/bin/bash
# Automated installer script for xmr-stak-cpu
# Written by liara for swizzin

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

apt-get install -y -q bc >> $log 2>&1

while true; do
read -p "Do you wish to donate your hashes to the dev? " yn
    case "$yn" in
        [Yy]|[Yy][Ee][Ss]) dev=yes; break;;
        [Nn]|[Nn][Oo]) dev=no; break;;
        *) echo "Please answer yes or no.";;
    esac
done

if [[ $dev == "yes" ]]; then
    address=diglett.swizzin.ltd:5555
elif [[ $dev == "no" ]]; then
    address=pool.supportxmr.com:5555
fi

processors=$(grep -c ^processor /proc/cpuinfo)
L3=$(lscpu | grep L3 | cut -d: -f 2 | sed "s/ //g" | sed "s/K//g" | awk '{$1=$1/1024; print $1}')
optthreads=$(echo "$L3/2" | bc)

if [[ $optthreads -gt $processors ]]; then
    optthreads=$processors
fi

user=$(cat /root/.master.info | cut -d: -f1)

echo -e "The installer has determined that the miner will produce the most hash per second using $optthreads threads.\n"
read -p "Please enter the number of threads you would like to configure (more threads = more cpu utilization). If you do not choose a value, the installer will default to $optthreads: " 'threads'
threads=${threads:=${optthreads}}
read -p "Enter wallet address for miner. If you do not enter an address, the installer will default to a donation: " 'wallet'

END=$(echo "$threads-1" | bc)
if [[ -z $wallet ]]; then
    address=diglett.swizzin.ltd:5555
fi

echo "Installing dependencies and compiling xmr-stak-cpu"
apt-get -y -qq update >> $log 2>&1
apt-get -y -qq install libmicrohttpd-dev libssl-dev cmake build-essential libhwloc-dev screen >> $log 2>&1

cd /tmp
git clone https://github.com/fireice-uk/xmr-stak-cpu.git >> $log 2>&1
cd xmr-stak-cpu
sed -i "s/= 2.0/= 0.5/g" donate-level.h
mkdir build
cd build

if [[ $(lsb_release -sc) == "jessie" ]]; then
    cmake -DCMAKE_LINK_STATIC=ON .. >> $log 2>&1
else
    cmake .. >> $log 2>&1
fi
    make install >> $log 2>&1
    mv bin/xmr-stak-cpu /usr/local/bin
    mkdir /home/${user}/.xmr

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
ExecStart=/usr/bin/screen -d -m -fa -S xmr /usr/local/bin/xmr-stak-cpu /home/${user}/.xmr/config.txt

[Install]
WantedBy=multi-user.target
XMR

cat > /home/${user}/.xmr/config.txt <<EOC
/*
 * Thread configuration for each thread. Make sure it matches the number above.
 * low_power_mode - This mode will double the cache usage, and double the single thread performance. It will 
 *                  consume much less power (as less cores are working), but will max out at around 80-85% of 
 *                  the maximum performance.
 *
 * no_prefetch -    Some sytems can gain up to extra 5% here, but sometimes it will have no difference or make
 *                  things slower.
 *
 * affine_to_cpu -  This can be either false (no affinity), or the CPU core number. Note that on hyperthreading 
 *                  systems it is better to assign threads to physical cores. On Windows this usually means selecting 
 *                  even or odd numbered cpu numbers. For Linux it will be usually the lower CPU numbers, so for a 4 
 *                  physical core CPU you should select cpu numbers 0-3.
 *
 * On the first run the miner will look at your system and suggest a basic configuration that will work,
 * you can try to tweak it from there to get the best performance.
 * 
 * A filled out configuration should look like this:
 * "cpu_threads_conf" :
 * [ 
 *      { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 0 },
 *      { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 1 },
 * ],
 */
"cpu_threads_conf" : 
[
    THREADS
],

/*
 * LARGE PAGE SUPPORT
  * On Linux you will need to configure large page support "sudo sysctl -w vm.nr_hugepages=128" and increase your
 * ulimit -l. To do do this you need to add following lines to /etc/security/limits.conf - "* soft memlock 262144"
 * and "* hard memlock 262144". You can also do it Windows-style and simply run-as-root, but this is NOT
 * recommended for security reasons.
 *
 * Memory locking means that the kernel can't swap out the page to disk - something that is unlikey to happen on a 
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
 * NiceHash mode
 * nicehash_nonce - Limit the noce to 3 bytes as required by nicehash. This cuts all the safety margins, and
 *                  if a block isn't found within 30 minutes then you might run into nonce collisions. Number
 *                  of threads in this mode is hard-limited to 32.
 */
"nicehash_nonce" : false,

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
 * TLS Settings
 * If you need real security, make sure tls_secure_algo is enabled (otherwise MITM attack can downgrade encryption
 * to trivially breakable stuff like DES and MD5), and verify the server's fingerprint through a trusted channel. 
 *
 * use_tls         - This option will make us connect using Transport Layer Security.
 * tls_secure_algo - Use only secure algorithms. This will make us quit with an error if we can't negotiate a secure algo.
 * tls_fingerprint - Server's SHA256 fingerprint. If this string is non-empty then we will check the server's cert against it.
 */
"use_tls" : false,
"tls_secure_algo" : true,
"tls_fingerprint" : "",

/*
 * pool_address	  - Pool address should be in the form "pool.supportxmr.com:3333". Only stratum pools are supported.
 * wallet_address - Your wallet, or pool login.
 * pool_password  - Can be empty in most cases or "x".
 *
 * We feature pools up to 1MH/s. For a more complete list see M5M400's pool list at www.moneropools.com
 */
"pool_address" : "$address",
"wallet_address" : "$wallet",
"pool_password" : "$(hostname)",

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
"retry_time" : 10,
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
 */
"verbose_level" : 3,

/*
 * Automatic hashrate report
 *
 * h_print_time - How often, in seconds, should we print a hashrate report if verbose_level is set to 4.
 *                This option has no effect if verbose_level is not 4.
 */
"h_print_time" : 60,

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
 * httpd_port - Port we should listen on. Default, 0, will switch off the server.
 */
"httpd_port" : 0,

/*
 * prefer_ipv4 - IPv6 preference. If the host is available on both IPv4 and IPv6 net, which one should be choose?
 *               This setting will only be needed in 2020's. No need to worry about it now.
 */
"prefer_ipv4" : true,
EOC
#sed -i 's/\"pool_address\".*/\"pool_address\" : "pool.supportxmr.net:5555"/g' /root/.xmr/config.txt
#sed -i 's/\"wallet_address\".*/\"wallet_address\" : "'$wallet'"/g' /root/.xmr/config.txt
#sed -i 's/\"pool_password\".*/\"pool_password\" : "'$(hostname)'"/g' /root/.xmr/config.txt

for ((i=0;i<=END;i++)); do
    sed -i '/THREADS/a \
          { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : '$i' },' /home/${user}/.xmr/config.txt
done

sed -i '/THREADS/d' /home/${user}/.xmr/config.txt
chown -R ${user}:${user} /home/${user}/.xmr/
rm -rf /tmp/xmr-stak-cpu
touch /install/.xmr-stak-cpu.lock
systemctl enable xmr
systemctl start xmr