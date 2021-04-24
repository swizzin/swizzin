#!/bin/bash
# Temporary upgrade script for the panel until panel becomes more self-sufficient

if [[ -f /install/.panel.lock ]]; then
    if ! dpkg -s acl > /dev/null 2>&1; then
        echo_progress_start "Modifying ACLs for swizzin group to prevent panel issues"
        apt_install acl
        setfacl -m g:swizzin:rx /home/*
        echo_progress_done
    fi
    if [ "$BOX_GIT_UPDATE" = 'false' ]; then
        echo_warn "Skipping panel update from git"
    else
        # cd /opt/swizzin
        #git reset HEAD --hard
        echo_progress_start "Pulling new commits"
        git pull -C /opt/swizzin >> ${log} 2>&1 || {
            echo_warn "Working around unclean git repo"
            git fetch origin master -C /opt/swizzin >> ${log} 2>&1
            cp -a core/custom core/custom.tmp
            git reset --hard origin/master -C /opt/swizzin >> ${log} 2>&1
            mv core/custom.tmp/* core/custom/ >> ${log} 2>&1
            rm -rf core/custom.tmp
        }
        echo_progress_done "Commits pulled"
        echo_progress_start "Checking pip for new depends"
        if ! /opt/.venv/swizzin/bin/python /opt/swizzin/tests/test_requirements.py >> ${log} 2>&1; then
            /opt/.venv/swizzin/bin/pip install -r /opt/swizzin/requirements.txt >> ${log} 2>&1
        fi
        echo_progress_done "Depends up-to-date"
        echo_progress_start "Restarting Panel"
        systemctl restart panel
        echo_progress_done "Done!"
    fi
fi
