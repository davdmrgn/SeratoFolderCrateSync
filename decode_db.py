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
  l = 0
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
      l = l + 1
      print('Decoding {}: {}'.format(l, value[1][1]))
    elif re.match('(?!^u|^s|^b)' , key):
      value = value_binary.decode('utf-16-be')
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  return(output)

decoded_db = decode(data)

# print(decoded_db)

def encode(input):
  l = 0
  output = b''
  for line in input:
    key = line[0] #'vrsn'
    key_binary = key.encode('utf-8')
    if key == 'vrsn':
      value = line[1]
      value_binary = value.encode('utf-16-be')
      # length_binary = struct.pack('>I', len(value_binary))
      # output += (key_binary + length_binary + value_binary)
    elif key == 'otrk':
      otrk_values = line[1]
      l = l + 1
      print('Encoding {}: {}'.format(l, otrk_values[1][1]))
      otrk_output = b''
      for line in otrk_values:
        otrk_key = line[0]
        otrk_key_binary = otrk_key.encode('utf-8')
        otrk_value = line[1]
        if isinstance(otrk_value, bytes):
          otrk_value_binary = otrk_value
        else:
          otrk_value_binary = otrk_value.encode('utf-16-be')
        otrk_length_binary = struct.pack('>I', len(otrk_value_binary))
        value_binary += (otrk_key_binary + otrk_length_binary + otrk_value_binary)
    length_binary = struct.pack('>I', len(value_binary))
    output += (key_binary + length_binary + value_binary)
  print('Encoded {} files'.format(l))
  return(output)

encoded_db = encode(decoded_db)

new_serato_database = '/Users/dave/Documents/database V2 new'

print('Writing new database: ' + new_serato_database)
with open(new_serato_database, 'w+b') as new_db:
  new_db.write(encoded_db)


import io

def encode2(input):
  ...
  output_buffer = io.BytesIO()
  key_binary = 'vrsn'.encode('utf-8')  # Pre-encode outside the loop
  ...
  for line in input:
    key = line[0]
    ...
    if key == 'otrk':
      ...
      for line in otrk_values:
        otrk_key = line[0]
        otrk_key_binary = otrk_key_binary or otrk_key.encode('utf-8')  # Encode only if needed
        ...
        output_buffer.write(otrk_key_binary)
        ...
  return output_buffer.getvalue()
 