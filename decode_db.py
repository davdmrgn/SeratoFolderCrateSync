import configparser
import os
import io
import re
import struct
import time
from datetime import datetime
import logging
import shutil

homedir = os.path.expanduser('~')
music_path = os.path.join(homedir, 'Music')
database_path = os.path.join(music_path, '_Serato_')
serato_database = os.path.join(database_path, 'database V2')

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

def replace_path(input):
  output = []
  l = 0
  for item in input:
    key = item[0]
    if key == 'otrk':
      otrk_data = []
      otrk_item = item[1]
      for item in otrk_item:
        if item[0] == 'pfil':
          pfil_value = re.sub('/Google Drive/My Drive/', '/Music/', item[1])
          l = l + 1
          print('Replacing {}: {}'.format(l, pfil_value))
          otrk_data.append((item[0], pfil_value))
        else:
          otrk_data.append(item)
      output.append((key, otrk_data))
    else:
      output.append(item)
  return output

replaced_db = replace_path(decoded_db)

def encode(input):
  l = 0
  # output = b''
  output = io.BytesIO()
  for line in input:
    key = line[0] #'vrsn'
    key_binary = key.encode('utf-8')
    if key == 'vrsn':
      value = line[1]
      value_binary = value.encode('utf-16-be')
    elif key == 'otrk':
      otrk_values = line[1]
      l = l + 1
      print('Encoding {}: {}'.format(l, otrk_values[1][1]))
      value_binary = b''
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
    # output += (key_binary + length_binary + value_binary)
    output.write(key_binary + length_binary + value_binary)
  print('Encoded {} files'.format(l))
  return output.getvalue()
  # return output_buffer.getvalue()

encoded_db = encode(replaced_db)

new_serato_database = serato_database + ' new'

print('Writing new database: ' + new_serato_database)
with open(new_serato_database, 'w+b') as new_db:
  new_db.write(encoded_db)
