#!/usr/bin/env bash

if check_installed rar; then
    apt_remove rar
else
    rm_if_exists /usr/bin/rar
fi

if check_installed unrar; then
    apt_remove unrar
else
    rm_if_exists /usr/bin/unrar
fi

rm /install/.rar.lock
