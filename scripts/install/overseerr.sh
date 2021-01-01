#!/usr/bin/env bash

# Overseer installer by flying sausages 2020 GPLv3

#shellcheck source=sources/functions/npm
. /etc/swizzin/sources/functions/npm

apt_install libsqlite3-dev sqlite3

npm_install #Install node 12 LTS and npm if they're not present or outdated

echo_progress_start "Installing yarn"
npm install -g yarn || {
    echo_error "Yarn failed to install"
    exit 1
}
echo_progress_done "Yarn installed"

echo_progress_start "Downloading and extracting source code"
dlurl="$(curl https://api.github.com/repos/sct/overseerr/releases/latest | jq .tarball_url -r)"
wget "$dlurl" -O /tmp/overseerr.tar.gz || {
    echo_error "Download failed"
    exit 1
}
mkdir -p /opt/overseerr
tar --strip-components=1 -C /opt/overseerr -xzvf /tmp/overseerr.tar.gz
echo_progress_done "Code extracted"

echo_progress_start "Installing via yarn"
npm install -g sqlite3 --build-from-source --sqlite=/usr/bin || {
    echo_warn "Failed to install sqlite"
    exit 1
}
yarn install --cwd /opt/overseerr || {
    echo_warn "Failed to install dependencies"
    exit 1
}
yarn --cwd /opt/overseerr build || {
    echo_warn "Failed to build overseerr sqlite"
    exit 1
}
# yarn cache clean
echo_progress_done "Dependencies installed"

touch /install/.overseerr.lock
