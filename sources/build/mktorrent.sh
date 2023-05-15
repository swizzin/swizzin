#!/usr/bin/bash
# mktorrent Builder

mklog=$1

source /etc/swizzin/sources/functions/utils
rm_if_exists $mklog
touch $mklog

cd /tmp
curl -sL https://github.com/Rudde/mktorrent/archive/v1.1.zip -o mktorrent.zip >> $mklog 2>&1
rm_if_exists "/tmp/mktorrent"
unzip -d mktorrent -j mktorrent.zip >> $mklog 2>&1
cd mktorrent
make >> $mklog 2>&1
make install PREFIX=/usr >> $mklog 2>&1
cd /tmp
rm -rf mktorrent*
