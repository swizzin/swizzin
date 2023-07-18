#!/bin/bash
# FIxes the removal of the skel that was done back in the past
if [[ ! -f /etc/skel/.bashrc ]]; then
    echo_info "Installing /etc/skel/.bashrc"
    cd /tmp
    apt-get download bash -q
    dpkg-deb -x bash* bash
    cp /tmp/bash/etc/skel -R /etc/
    rm -rf /tmp/bash*
    rm /etc/skel/.bashrc.bak

    for d in /home/*/; do
        newbashrc="/etc/skel/.bashrc"
        if [[ ! -f $d.bashrc ]]; then
            cp $newbashrc $d.bashrc
            echo_warn "Installed $d.bashrc. Re-open your terminal or run \`exec \"\$SHELL\"\` to apply the changes."
        else
            if [[ ! $(cmp --silent $d.bashrc $newbashrc) ]]; then
                cp $newbashrc $d.bashrc-default
                echo_warn "Previously, swizzin removed ${d}.bashrc. As the current one is different to the default one, a copy has been placed in your home directory. Please compare them and merge together as you desire."
            fi
        fi
    done
    echo_progress_done
fi
