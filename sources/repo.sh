#!/bin/bash

case "$(_os_codename)" in
    "xenial" | "bionic" | "focal" | "buster" | "stretch")
        echo_log_only "OS supported"
        # No need to do anything special
        ;;
    *)
        name=$(_os_codename)
        echo_warn "${name^} is no longer a supported by swizzin.
You will not be receiving any new updates past the last supported commit. Swizzin will continue to run as-is.
We URGE you to migrate to a supported release if/while you still have the chance."
        SWIZ_GIT_CHECKOUT="eol-$(_os_codename)"
        export SWIZ_GIT_CHECKOUT
        ;;
esac

if [[ -L /etc/swizzin ]]; then
    echo_warn "Not updating /etc/swizzin as it is a symlink. Please consult your provider/maintainers in case you believe this is an error."
elif [[ -e /etc/swizzin/.dev.lock ]]; then
    echo_warn "Not updating /etc/swizzin as a dev lockfile is present."
elif [[ $1 == "--dev" ]]; then
    echo_warn "Not updating from git due to --dev flag"
else
    echo_progress_start "Updating swizzin local repository"
    {
        #shellcheck disable=SC2129
        git fetch --all --tags --prune -C /etc/swizzin >> $log 2>&1
        git fetch origin "${SWIZ_GIT_CHECKOUT:-master}" -C /etc/swizzin >> $log 2>&1
        git reset --hard origin/"${SWIZ_GIT_CHECKOUT:-master}" -C /etc/swizzin >> $log 2>&1
    } || {
        echo_error "Failed to update from git"
        exit 1
    }
    echo_progress_done "Local repository updated from ${SWIZ_GIT_CHECKOUT:-master}"
    echo_info "HEAD is now set to $(git log --pretty=format:'%h' -n1)"
fi
export SWIZ_REPO_SCRIPT_RAN=true
# source globals again in case changes were made
#shellcheck source=sources/globals.sh
. /etc/swizzin/sources/globals.sh
