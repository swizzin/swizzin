#!/usr/bin/env bash

# This file can be sourced so that only functions are available, and can be also invoked directly.
# therefore...
# - running `bash scripts/tests/basetest.sh "sonarr"` will do what you expect
# - doing `source scripts/test/basetest.sh` and then doing `check_service "sonarr"` in your other test will also work

check_service() {
    echo_progress_start "Checking $1 service is active"
    systemctl -q is-active "$1" || {
        systemctl status "$1"
        echo_warn "$1.service not running!"
        return 1
    }
    echo_progress_done
}

check_nginx() {
    echo_progress_start "Checking if $1 is reachable via nginx"
    master="$(_get_master_username)"
    password="$(_get_user_password "$master")"
    curl --user "${master}:${password}" -sfLk https://127.0.0.1/"$1" > /dev/null || {
        echo_warn "Querying https://127.0.0.1/$1 failed"
        echo
        return 1
    }
    echo_progress_done
}

# Checks a port or the port of an app suplied via $1
check_port() {
    if [ "$1" -eq "$1" ] 2> /dev/null; then
        port=$1
    else
        echo_info "$1 is not a port number, guessing off nginx installers"
        installer="/etc/swizzin/scripts/nginx/$1.sh"
        if [ -f "$installer" ]; then
            port="$(grep "proxy_pass" "$installer" | sed 's/.*://; s/;.*//')"
        else
            echo_warn "Couldn't guess port"
        fi

    fi

    echo_progress_start "Checking if port $port is reachable directly over HTTP"
    curl -sfLk http://127.0.0.1:"$port" > /dev/null || {
        curl -sLk http://127.0.0.1:"$port"
        echo_warn "Querying https://127.0.0.1:$port failed"
        echo
        return 1
    }
    echo_progress_done
}

evaluate_bad() {
    if [[ $bad == "true" ]]; then
        echo_error "Errors were encountered"
        exit 1
    else
        echo_success "No problems were encountered"
    fi
}

run_main() {
    if [[ -z $1 ]]; then
        echo_error "Need a parameter..."
        exit 1
    fi

    echo_info "Running default test for $1.\n
This test is likely to fail in case the item is not a standard service+nginx app"
    echo
    # run all functions, if one fails, mark as bad
    check_service "$1" || bad="true"
    check_nginx "$1" || bad="true"
    check_port "$1" || bad="true"

    evaluate_bad

}

# Run main _only_ when script is not being sourced, so that functions can be reused
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main "$@"
fi
