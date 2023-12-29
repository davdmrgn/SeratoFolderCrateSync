import os
import logging
import time
from datetime import datetime
import struct
import re
import configparser
import sys
import shutil
import io


# a = '/Volumes/Ten/Google Drive/Serato/_Serato_iMac/Subcrates/Crates 9%%DJ Tools.crate'
a = '/Users/dave/Music/_Serato_/Subcrates/Crates 9%%DJ Tools.crate'
with open(a, 'rb') as b:
  data = b.read()

def DecodeBinary(input):
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
    if re.match('^o', key):
      value = DecodeBinary(value_binary)
      l = l + 1
      terminal_width = os.get_terminal_size().columns - 20
      if len(value) != 1:
        print('Decoding {}: {}'.format(l, value[1][1][:terminal_width]), end='\033[K\r')
    elif re.match('(?!^u|^s|^b)' , key):
      value = value_binary.decode('utf-16-be')
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  return(output)

decoded_crate = DecodeBinary(data)

def Encode(input):
  l = 0
  output = io.BytesIO()
  for line in input:
    key = line[0]
    key_binary = key.encode('utf-8')
    if key == 'vrsn':
      value = line[1]
      value_binary = value.encode('utf-16-be')
    elif re.match('^o', key):
      o_values = line[1]
      l = l + 1
      if len(o_values) != 1:
        print('Encoding {}: {}'.format(l, o_values[1][1]))
      value_binary = b''
      for line in o_values:
        o_key = line[0]
        o_key_binary = o_key.encode('utf-8')
        o_value = line[1]
        if isinstance(o_value, bytes):
          o_value_binary = o_value
        else:
          o_value_binary = o_value.encode('utf-16-be')
        o_length_binary = struct.pack('>I', len(o_value_binary))
        value_binary += (o_key_binary + o_length_binary + o_value_binary)
    length_binary = struct.pack('>I', len(value_binary))
    output.write(key_binary + length_binary + value_binary)
  print('Encoded {} files'.format(l))
  return output.getvalue()

encoded_crate = Encode(decoded_crate)

print(encoded_crate)
