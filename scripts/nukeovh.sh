#!/bin/bash

grsec=$(uname -a | grep -i grs)
if [[ -n $grsec ]]; then
    echo_info "Your server is currently running with kernel version: $(uname -r)\nWhile it is not required to switch, kernels with grsec are not recommend due to conflicts in the panel and other packages."
    if ask "Would you like swizzin to install the distribution kernel?" Y; then
        # echo_info "Your distribution's default kernel will be installed. A reboot will be required."
        if [[ $DISTRO == Ubuntu ]]; then
            apt-get install -q -y linux-image-generic >>"${log}" 2>&1
        elif [[ $DISTRO == Debian ]]; then
            arch=$(uname -m)
            if [[ $arch =~ ("i686"|"i386") ]]; then
                apt-get install -q -y linux-image-686 >>"${log}" 2>&1
            elif [[ $arch == x86_64 ]]; then
                apt-get install -q -y linux-image-amd64 >>"${log}" 2>&1
            fi
        fi
        mv /etc/grub.d/06_OVHkernel /etc/grub.d/25_OVHkernel
        update-grub >>"${log}" 2>&1
    else
        echo_warn "No changes to kernel will be performed"
    fi
fi