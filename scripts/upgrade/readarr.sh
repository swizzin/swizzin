#!/bin/bash

if [[ ! -f /install/.readarr.lock ]]; then
    echo_error "Readarr not detected. Exiting!"
    exit 1
fi

box install readarr
