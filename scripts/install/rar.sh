#!/usr/bin/env bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
install_rar

if which rar > /dev/null; then
    echo_success "Rar and UnRar installed"
elif which unrar > /dev/null; then
    echo_success "UnRar installed"
fi
