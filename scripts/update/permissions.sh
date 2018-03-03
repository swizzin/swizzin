#!/bin/bash

find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;