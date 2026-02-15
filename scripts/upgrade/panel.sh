#!/bin/bash
# Temporary upgrade script for the panel until panel becomes more self-sufficient

if [[ -f /install/.panel.lock ]]; then
    restart_needed=0
    if ! dpkg -s acl > /dev/null 2>&1; then
        echo_progress_start "Modifying ACLs for swizzin group to prevent panel issues"
        apt_install acl
        setfacl -m g:swizzin:rx /home/*
        echo_progress_done
        restart_needed=1
    fi
    sudo -u swizzin git -C /opt/swizzin fetch origin master >> ${log} 2>&1 || {
        echo_error "Failed to fetch latest commits for panel"
        exit 1
    }
    new_commits_count=$(sudo -u swizzin git -C /opt/swizzin rev-list HEAD..@{u} --count)
    if [[ $new_commits_count -gt 0 ]]; then
        echo_progress_start "Downloading latest panel commits"
        sudo -u swizzin git -C /opt/swizzin pull >> ${log} 2>&1 || { PANELRESET=1; }
        if [[ $PANELRESET == 1 ]]; then
            echo_progress_start "Downloading latest panel commits"
            echo_warn "Working around unclean git repo"
            sudo -u swizzin git -C /opt/swizzin fetch origin master >> ${log} 2>&1
            cp -a /opt/swizzin/core/custom /opt/swizzin/core/custom.tmp
            sudo -u swizzin git -C /opt/swizzin reset --hard origin/master >> ${log} 2>&1
            mv /opt/swizzin/core/custom.tmp/* /opt/swizzin/core/custom/ >> ${log} 2>&1
            rm -rf opt/swizzin/core/custom.tmp
        fi
        echo_progress_done "Commits pulled"
        restart_needed=1
    fi

    #shellcheck source=sources/functions/pyenv
    . /etc/swizzin/sources/functions/pyenv
    if ! python3_check_reqs panel /opt/swizzin/requirements.txt >> ${log} 2>&1; then
        echo_progress_start "Installing updated requirements for panel"
        /opt/.venv/swizzin/bin/pip install --upgrade pip wheel >> ${log} 2>&1
        /opt/.venv/swizzin/bin/pip install -r /opt/swizzin/requirements.txt >> ${log} 2>&1
        chown -R swizzin: /opt/.venv/swizzin
        echo_progress_done
        restart_needed=1
    fi

    if [[ $restart_needed -eq 1 ]]; then
        echo_progress_start "Restarting Panel"
        systemctl restart panel
        echo_progress_done "Done!"
    fi
fi
