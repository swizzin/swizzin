#!/bin/bash
# FIxes the removal of the skel that was done back in the past
if [[ ! -f /etc/skel/.bashrc ]]; then 
    cd /tmp
    apt-get download bash
    dpkg-deb -x bash* bash
    cp /tmp/bash/etc/skel -R /etc/

    for d in /home/*/; do
        newbashrc="/etc/skel/.bashrc"
        if [[ ! -f $d/.bashrc ]]; then 
            cp $newbashrc $d/.bashrc
        else
            if [[ ! $(cpm --silent $d/.bashrc $newbashrc) ]]; then
                cp $newbashrc $d/.bashrc-default
                echo "Previously, swizzin removed ${d}/bashrc. As the current one is different to the default one, a copy has been placed in your home directory."
                echo "Please compare them and merge together as you desire."
            fi
        fi
    done

fi