#!/usr/bin/env python
#
# Deluge password generator
#
#   deluge.password.py <password> <salt>
#
#

import hashlib
import sys

password = sys.argv[1].encode('utf-8')
salt = sys.argv[2].encode('utf-8')

s = hashlib.sha1()
s.update(salt)
s.update(password)

print(s.hexdigest())
