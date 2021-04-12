#!/bin/bash
#
# Set the correct permissions for the completion file and then create a symlink to the bash completion file.
chmod 644 '/etc/swizzin/sources/bash_completion.d/swizzin'
ln -fs '/etc/swizzin/sources/bash_completion.d/swizzin' '/etc/bash_completion.d/swizzin'
