#!/usr/bin/env bash

if [[ -L /etc/swizzin ]]; then
    echo_warn "Not updating /etc/swizzin as it is a symlink. Please consult your provider/maintainers in case you believe this is an error."
elif [[ -e /etc/swizzin/.dev.lock ]]; then
    echo_warn "Not updating /etc/swizzin as a dev lockfile is present."
elif [[ $1 == "--dev" ]]; then
    echo_warn "Not updating from git due to --dev flag"
else
    echo_progress_start "Updating swizzin local repository"
    cd /etc/swizzin || exit
    git fetch --all --tags --prune
    git fetch origin "${SWIZ_GIT_CHECKOUT:-master}"
    git checkout -f "${SWIZ_GIT_CHECKOUT:-master}"
    git reset --hard origin/"${SWIZ_GIT_CHECKOUT:-master}"
    echo_info "HEAD is now set to $(git log --pretty=format:'%h' -n1)"
    echo_progress_done "Local repository updated from ${SWIZ_GIT_CHECKOUT:-master}"
fi
