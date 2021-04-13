#!/bin/bash
#
# Set the correct permissions for the completion file and then create a symlink to the bash completion file.
if [ ! -e /etc/bash_completion.d/swizzin ]; then
    chmod 644 '/etc/swizzin/sources/bash_completion/swizzin'
    ln -s '/etc/swizzin/sources/bash_completion/swizzin' '/etc/bash_completion.d/swizzin'
    echo_info "Shell completions for the box command have been installed. They will be applied the next time you log into a bash shell"
fi
#
# Create our apps and upgrade lists for the arrays.
find "/etc/swizzin/scripts/install/" -type f -exec basename {} \; | sort | awk '{printf "%s ",$1 }' > /etc/swizzin/sources/bash_completion/completion.apps
find "/etc/swizzin/scripts/upgrade/" -type f -exec basename {} \; | sort | awk '{printf "%s ",$1 }' > /etc/swizzin/sources/bash_completion/completion.upgrade
