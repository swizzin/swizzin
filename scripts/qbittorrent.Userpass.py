#!/usr/bin/python3
import sys
import hashlib
import base64
import uuid

password = sys.argv[1]
salt = uuid.uuid4()
salt_bytes = salt.bytes

password = str.encode(password)
hashed_password = hashlib.pbkdf2_hmac('sha512', password, salt_bytes, 100000, dklen=64)
b64_salt = base64.b64encode(salt_bytes).decode("utf-8")
b64_password = base64.b64encode(hashed_password).decode("utf-8")
password_string = "{salt}:{password}".format(salt=b64_salt,password=b64_password)
print(password_string)