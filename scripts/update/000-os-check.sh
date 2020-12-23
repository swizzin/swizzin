#!/usr/bin/env bash

warnmessage() {
    name=$(_os_codename)
    echo_warn "${name^} is no longer a supported by swizzin.
You will not be receiving any new updates. Swizzin will continue to run as-is.
We URGE you to migrate to a supported release if/while you still have the chance."
}

case "$(_os_codename)" in
    "bionic" | "focal" | "buster" | "stretch")
        echo_log_only "OS supported"
        # No need to do anything
        ;;
    *)
        warnmessage
        SWIZ_GIT_CHECKOUT="eol-$(_os_codename)"
        export SWIZ_GIT_CHECKOUT
        ;;
esac
