#!/usr/bin/bash
# libtorrent rakshasa source file preperation

llog=$1
elog=$2
tpath=$3
version=$4
udns=$5
libtorrentloc="https://github.com/rakshasa/libtorrent/archive/refs/tags/v${version}.tar.gz"

source /etc/swizzin/sources/functions/utils
rm_if_exists $llog
rm_if_exists $elog
rm_if_exists $tpath
touch $llog
touch $elog
mkdir $tpath

curl -sL $libtorrentloc -o "$tpath-$version.tar.gz"
tar -xf "$tpath-$version.tar.gz" -C $tpath --strip-components=1 >> $llog 2>&1
rm_if_exists "$tpath-$version.tar.gz"

cd $tpath >> $llog 2>&1

# Look for custom source file patches based on the libtorrent version
if [[ -f /root/libtorrent-rakshasa-$version.patch ]]; then
    patch -p1 < /root/libtorrent-rakshasa-$version.patch >> $llog 2>&1 || {
        echo "Something went wrong when patching libtorrent-rakshasa" >> $elog 2>&1
        rm_if_exists $tpath
        exit 1
    }
    echo "Libtorrent-rakshasa patch found and applied!" >> $llog 2>&1
else
    echo "No libtorrent-rakshasa patch found at /root/libtorrent-rakshasa-$version.patch" >> $llog 2>&1
fi

# Apply source file patches based on the libtorrent version
case $version in
    0.13.6)
        patch -p1 < /etc/swizzin/sources/patches/rtorrent/openssl.patch >> $llog 2>&1
        if pkg-config --atleast-version=1.14 cppunit; then
            patch -p1 < /etc/swizzin/sources/patches/rtorrent/cppunit-libtorrent.patch >> $llog 2>&1
        fi
        patch -p1 < /etc/swizzin/sources/patches/rtorrent/bencode-libtorrent.patch >> $llog 2>&1
        patch -p1 < /etc/swizzin/sources/patches/rtorrent/throttle-fix-0.13.6.patch >> $llog 2>&1
        ;;

    0.13.7)
        patch -p1 < /etc/swizzin/sources/patches/rtorrent/throttle-fix-0.13.7-8.patch >> $llog 2>&1
        patch -p1 < /etc/swizzin/sources/patches/rtorrent/openssl.patch >> $llog 2>&1
        ;;

    0.13.8)
        if [[ $udns == "true" ]]; then
            patch -p1 < /etc/swizzin/sources/patches/rtorrent/libtorrent-udns-0.13.8.patch >> $llog 2>&1
            patch -p1 < /etc/swizzin/sources/patches/rtorrent/libtorrent-scanf-0.13.8.patch >> $llog 2>&1
        fi
        patch -p1 < /etc/swizzin/sources/patches/rtorrent/throttle-fix-0.13.7-8.patch >> $llog 2>&1
        ;;
esac

# Generate source files for compile
./autogen.sh >> $llog 2>&1

# Echo PASSED to elog if we make it this far
echo "PASSED" >> $elog 2>&1
