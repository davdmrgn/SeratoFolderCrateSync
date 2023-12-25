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

# print(decoded_db)

def encode(input):
  output = b''
  for line in input:
    key = line[0] #'vrsn'
    key_binary = key.encode('utf-8')
    if key == 'vrsn':
      value = line[1]
      value_binary = value.encode('utf-16-be')
      length_binary = struct.pack('>I', len(value_binary))
      output += (key_binary + length_binary + value_binary)
    elif key == 'otrk':
      otrk_values = line[1]
      otrk_output = b''
      for line in otrk_values:
        otrk_key = line[0]
        otrk_key_binary = otrk_key.encode('utf-8')
        otrk_value = line[1]
        if isinstance(otrk_value, bytes):
          otrk_value_binary = otrk_value
        else:
          otrk_value_binary = otrk_value.encode('utf-16-be')
        length_binary = struct.pack('>I', len(otrk_value_binary))
        otrk_output += (otrk_key_binary + length_binary + otrk_value_binary)
      otrk_length_binary = struct.pack('>I', len(otrk_output))
      output += (key_binary + otrk_length_binary + otrk_output)
  return(output)

encoded_db = encode(decoded_db)

new_serato_database = '/Users/dave/Documents/database V2 new'

with open(new_serato_database, 'w+b') as new_db:
  new_db.write(encoded_db)
