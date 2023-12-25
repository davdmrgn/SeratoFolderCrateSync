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

print(decoded_db)





## Take Encode function from orginal script
def Encode(data):
  result = b''
  i = 0
  for line in data:
    try:
      key = line[0].encode('utf-8')
      if isinstance(line[1], list):
        sub_list = line[1][0]
        sub_key = sub_list[0].encode('utf-8')
        sub_value = sub_list[1].encode('utf-16-be')
        sub_length = struct.pack('>I', len(sub_value))
        value = (sub_key + sub_length + sub_value)
      else:
        value = line[1].encode('utf-16-be')
      length = struct.pack('>I', len(value))
      result += (key + length + value)
      i += 1
    except:
      logging.error('ENCODE ERROR: i: {}, key: {}, length: {}, value: {}'.format(i, key, length, value))
      break
  return(result)


def encode(input):
  output = b''
  for line in input:
    key = line[0] #'vrsn'
    key_binary = key.encode('utf-8')
    value = line[1]
    value_binary = value.encode('utf-16-be')
    length_binary = struct.pack('>I', len(value_binary))
    output += (key_binary + length_binary + value_binary)