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
  output = []
  i = 0
  while i < len(input):
    j = i + 4
    key_binary = input[i:j]
    key = key_binary.decode('utf-8')
    k = j + 4
    length_binary = input[j:k]
    length = struct.unpack('>I', length_binary)[0]
    value_binary = input[k:k + length]
    if key == 'otrk':
      value = decode(value_binary)
      # print(key, value)
    elif re.match('(?!^u|^s|^b)' , key):
      value = value_binary.decode('utf-16-be')
      # if key == 'vrsn':
      #   print(key, value)
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  return(output)

decoded_db = decode(data)
