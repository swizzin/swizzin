#!/usr/bin/bash
# rtorrent source file preperation

rlog=$1
elog=$2
tpath=$3
version=$4
udns=$5
rtorrentloc="https://github.com/rakshasa/rtorrent/archive/refs/tags/v$version.tar.gz"

source /etc/swizzin/sources/functions/utils
rm_if_exists $rlog
rm_if_exists $elog
rm_if_exists $tpath
touch $rlog
touch $elog
mkdir $tpath

curl -sL $rtorrentloc -o "$tpath-$version.tar.gz"
tar -xf "$tpath-$version.tar.gz" -C $tpath --strip-components=1 >> $rlog 2>&1
rm_if_exists "$tpath-$version.tar.gz"

cd $tpath >> $rlog 2>&1
# Look for custom source file patches based on the rtorrent version
if [[ -f /root/rtorrent-$version.patch ]]; then
    patch -p1 < /root/rtorrent-$version.patch >> $rlog 2>&1 || {
        echo "Something went wrong when patching rTorrent" >> $elog 2>&1
        rm_if_exists $tpath
        exit 1
    }
    echo "rTorrent patch found and applied!" >> $rlog 2>&1
else
    echo "No rTorrent patch found at /root/rtorrent-$version.patch" >> $rlog 2>&1
fi
# Apply tracker scape patch for rTorrent if udns is enabled
if [[ $udns == "true" ]]; then
    patch -p1 < /etc/swizzin/sources/patches/rtorrent/rtorrent-scrape-0.9.8.patch >> $rlog 2>&1
fi
# Apply lockfile-fix to all rtorrents
patch -p1 < /etc/swizzin/sources/patches/rtorrent/lockfile-fix.patch >> $rlog 2>&1
# Apply xmlrpc-fix to all rtorrents
patch -p1 < /etc/swizzin/sources/patches/rtorrent/xmlrpc-fix.patch >> $rlog 2>&1
# Use pkgconfig for cppunit if 0.9.6
if [[ $version == "0.9.6" ]]; then
    patch -p1 < /etc/swizzin/sources/patches/rtorrent/rtorrent-0.9.6.patch >> $rlog 2>&1
fi

# Generate source files for compile
./autogen.sh >> $rlog 2>&1

# Echo PASSED to elog if we make it this far
echo "PASSED" >> $elog 2>&1
