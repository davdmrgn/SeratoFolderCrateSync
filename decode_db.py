import configparser
import os
import re
import struct
import time
from datetime import datetime
import logging
import shutil

serato_database = '/Users/dave/Documents/database V2'

with open(serato_database, 'rb') as db:
  data = db.read()

def decode(input):
  i = 0
  while i < 2000:
    a = i
    b = i + 4
    key_binary = input[a:b]
    key = key_binary.decode('utf-8')
    c = b + 4
    length_binary = input[b:c]
    length = c + struct.unpack('>I', length_binary)[0]
    value_binary = input[c:length]
    if key == 'otrk':
      value = decode(value_binary)
    else:
      value = value_binary.decode('utf-16-be')
    print(key, length, value)
    i += length

decode(data)
