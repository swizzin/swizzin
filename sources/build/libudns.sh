#!/usr/bin/bash
# libudns Builder

udnslog=$1

source /etc/swizzin/sources/functions/utils
rm_if_exists $udnslog
touch $udnslog

rm_if_exists "/tmp/udns"
git clone -q https://github.com/shadowsocks/libudns /tmp/udns >> $udnslog 2>&1
cd /tmp/udns
./autogen.sh >> $udnslog 2>&1
./configure --prefix=/usr >> $udnslog 2>&1
make CFLAGS="-w -flto -O2 -fPIC" >> $udnslog 2>&1
make -s install >> $udnslog 2>&1
cd /tmp
rm -rf udns*
