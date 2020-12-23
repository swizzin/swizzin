#!/usr/bin/env bash

warnmessage() {
    echo_warn "We would like to express our condolences to $(_os_codename) which has reached swizzin EOL.
You will not be receiving any new updates from this point on.
We urge you to migrate to a supported OS if/while you still have the chance.    
"
}

case "$(_os_codename)" in
    "xenial")
        warnmessage
        export SWIZ_GIT_CHECKOUT="eol-xenial"
        ;;
    "jessie")
        warnmessage
        export SWIZ_GIT_CHECKOUT="eol-jessie"
        ;;
    "bionic" | "focal" | "buster" | "stretch")
        echo_log_only "OS supported"
        ;;
    *)
        echo_error "Unknown OS codename $(_os_codename)\nHow the actual fuck did you do this"
        exit 1 # TODO maybe kill a bit better?
        ;;
esac
