#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

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
