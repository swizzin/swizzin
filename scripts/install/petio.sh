#!/usr/bin/env bash

apt_install mongodb

mkdir -p /opt/petio

useradd --system petio -d /opt/petio

cp /tmp/petio/petio-linux /opt/petio/petio

chmod +x /opt/petio/petio
chown -R petio: /opt/petio/petio

echo_info "Please paste the following credentials into the setup fields for mongo db"
