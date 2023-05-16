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

svn co http://svn.code.sf.net/p/xmlrpc-c/code/advanced@$XMLRPC_REV $tpath >> $xlog 2>&1 || {
    svn co https://github.com/mirror/xmlrpc-c/trunk/advanced@$XMLRPC_REV $tpath >> $xlog 2>&1
}

cd $tpath >> $xlog 2>&1
cp -rf /etc/swizzin/sources/patches/rtorrent/xmlrpc-config.guess config.guess >> $xlog 2>&1
cp -rf /etc/swizzin/sources/patches/rtorrent/xmlrpc-config.sub config.sub >> $xlog 2>&1
