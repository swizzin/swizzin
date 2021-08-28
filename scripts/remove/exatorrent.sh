#!/bin/bash

for user in $(_get_user_list); do
    systemctl disable --now exatorrent@$user -q
done

rm -rf /opt/exatorrent
rm /etc/systemd/system/exatorrent@.service
systemctl daemon-reload
rm /install/.exatorrent.lock
