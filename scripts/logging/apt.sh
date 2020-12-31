#!/usr/bin/env bash

paths+=('/var/log/apt/history.log')
paths+=('/var/log/dpkg.log')
version+=("$(apt --version | cut -d' ' -f2)")
