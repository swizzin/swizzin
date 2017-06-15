#!/usr/bin/env python
#
# Deluge hostlist id generator
#
#   deluge.addHost.py
#
#

import hashlib
import sys
import time

print hashlib.sha1(str(time.time())).hexdigest()
