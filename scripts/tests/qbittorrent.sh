#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

#Check nginx only once beause if the config works for one, it will work for all
check_nginx "qbittorrent" || BAD=true

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "qbittorrent@$user" || {
        echo_warn "qbittorrent@$user is not enabled, skipping"
        continue
    }

    check_service "qbittorrent@$user" || {
        BAD=true
        continue
    }

    extra_params="--user $user:$(_get_user_password "$user")"
    confpath="/home/${user}/.config/qBittorrent/qBittorrent.conf"
    port=$(grep 'WebUI\\Port' "$confpath" | cut -d= -f2)
    check_port_curl "$port" "$extra_params" || BAD=true
done

evaluate_bad
