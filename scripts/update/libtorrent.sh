#!/bin/bash
# Update for new libtorrent package
# Author: liara
# Copyright (c) swizzin 2018

if islocked "deluge"; then
    if ! islocked "libtorrent"; then
        lock "libtorrent"
    fi
fi
