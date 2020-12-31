#!/usr/bin/env bash

paths+=(/etc/Ombi/Logs/*.txt)
commands+=("journalctl -u ombi")
