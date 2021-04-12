#!/bin/bash
#
# Set the correct permissions for the completion file and then create a symlink to the bash completion file.
if [ ! -e /etc/bash_completion.d/swizzin ]; then
    chmod 644 '/etc/swizzin/sources/bash_completion.d/swizzin'
    ln -s '/etc/swizzin/sources/bash_completion.d/swizzin' '/etc/bash_completion.d/swizzin'
    echo_info "Shell completions for the box command have been installed. They will apply when your shell is reloaded, then try pressing <tab> when you type 'box'." 
fi
