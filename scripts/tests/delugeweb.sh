#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    check_service "deluge-web@$user" || {
        BAD=true
        continue
    }

    atleastonerunning=true

    extra_params="--user $user:$(_get_user_password "$user")"
    web_port=$(jq -r '.["port"]' < /home/"$user"/.config/deluge/web.conf | grep -e '^[0-9]*$')
    check_port_curl "$web_port" "$extra_params" || BAD=true
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once beause if the config works for one, it will work for all
    check_nginx "deluge" || BAD=true
    evaluate_bad "delugeweb"
else
    echo_warn "No deluge-web instance was running"
fi
