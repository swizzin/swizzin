#!/usr/bin/env bash

# This file can be sourced so that only functions are available, and can be also invoked directly.
# therefore...
# - running `bash scripts/tests/basetest.sh "sonarr"` will do what you expect
# - doing `source scripts/test/basetest.sh` and then doing `check_service "sonarr"` in your other test will also work

check_service() {
    echo_progress_start "Checking service is active"
    systemctl is-active "$1" || {
        echo_error "$1.service not running!"
        return 1
    }
    echo_progress_done
}

check_nginx() {
    echo_progress_start "Checking service is reachable via nginx"
    curl -sLk 127.0.0.1/"$1" || {
        echo_error "message"
        return 1
    }
    echo_progress_done
}

run_main() {
    if [[ -z $1 ]]; then
        echo_error "Need a parameter..."
        exit 1
    fi

    echo_info "Running default test for $1"
    echo
    # run all functions, if one fails, mark as bad
    check_service "$1" || bad="true"
    echo
    check_nginx "$1" || bad="true"
    echo

    if [[ $bad == "true" ]]; then
        echo_error "Errors were encountered"
        exit 1
    else
        echo_success "No errors were encountered"
    fi

}

# Run main _only_ when script is not being sourced, so that functions can be reused
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main "$@"
fi
