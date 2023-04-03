import configparser
import os
import re
import struct

homedir = os.path.expanduser('~')

config = configparser.ConfigParser()
config.read('config.txt')
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']

# data is an existing decoded crate
def encode(data):
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
      print('ERROR: i: {}, key: {}, length: {}, value: {}'.format(i, key, length, value))
      break
  return(result)

file = library + '/Subcrates/This better work4.crate'
with open(file, 'wb') as crate:
  crate.write(x)
