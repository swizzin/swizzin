#!/bin/bash
#
# Create the symlink /etc/bash_completion.d/box if it does not exist and output a helpful echo
if [[ ! -e /etc/bash_completion.d/box ]]; then
    ln -s '/etc/swizzin/sources/bash_completion' '/etc/bash_completion.d/box'
    echo_info "Shell completions for the box command have been installed. They will be applied the next time you log into a bash shell"
fi

# Check to make sure the completion file /etc/swizzin/sources/bash_completion is set to 644
if [[ $(stat -c '%A' /etc/swizzin/sources/bash_completion) != '-rw-r--r--' ]]; then
    chmod 644 '/etc/swizzin/sources/bash_completion'
fi

rm -rf "$(swizdb path bash_completion)"
