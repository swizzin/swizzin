#!/bin/bash

# Create the symlink /etc/profile.d/debug if it does not exist and output a helpful echo
if [[ ! -e /etc/profile.d/debug ]]; then
    ln -s '/etc/swizzin/sources/functions/debug' '/etc/profile.d/debug'
    echo_info "Debug for installed services is available via the command debug service_name or debug_user service_name"
fi
