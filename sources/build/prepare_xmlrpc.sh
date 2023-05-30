#!/usr/bin/bash
# xmlrpc-c source file preperation

xlog=$1
tpath=$2
XMLRPC_REV=2954

source /etc/swizzin/sources/functions/utils
rm_if_exists $xlog
rm_if_exists $tpath
touch $xlog
mkdir $tpath

# Retreive xmlrpc source code
svn co http://svn.code.sf.net/p/xmlrpc-c/code/advanced@$XMLRPC_REV $tpath >> $xlog 2>&1 || {
    svn co https://github.com/mirror/xmlrpc-c/trunk/advanced@$XMLRPC_REV $tpath >> $xlog 2>&1
}
# Change directory to xmlrpc temp path
cd $tpath >> $xlog 2>&1
# Patch latest CPU architectures, so configure works properly on ARM64
cp -rf /etc/swizzin/sources/patches/rtorrent/xmlrpc-config.guess config.guess >> $xlog 2>&1
cp -rf /etc/swizzin/sources/patches/rtorrent/xmlrpc-config.sub config.sub >> $xlog 2>&1
# Whipe any existing xmlrpc binaries
./configure >> $xlog 2>&1
make uninstall >> $xlog 2>&1
