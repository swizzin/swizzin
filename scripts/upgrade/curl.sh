#!/bin/bash
# Upgrade curl to bypass the bug in Debian 10. Can be used on any system however, but the benefit is to Buster users most

cd /tmp
version=$(basename $(curl -fsSLI -o /dev/null -w %{url_effective} https://github.com/curl/curl/releases/latest))

wget -O curl.zip https://github.com/curl/curl/releases/download/${version}/${version//_/.}.zip >> ${log} 2>&1 || {
    echo_error "There was an error downloading curl! Please check the log for more info"
    cd /tmp
    rm -rf curl*
    exit 1
}

unzip curl.zip >> $log 2>&1
rm curl.zip

cd curl-${version//_/.}
./configure --enable-versioned-symbols >> ${log} 2>&1 || {
    echo_error "There was an error configuring curl! Please check the log for more info"
    cd /tmp
    rm -rf curl*
    exit 1
}
make -j$(nproc) >> ${log} 2>&1 || {
    echo_error "There was an error compiling curl! Please check the log for more info"
    cd /tmp
    rm -rf curl*
    exit 1
}
make install >> ${log} 2>&1

echo "/usr/local/bin" >> /etc/ld.so.conf
ldconfig

echo_info "An up-to-date version of curl has been installed to /usr/local/bin. Please be aware that curl may show an older version of curl until you log out and back in"
