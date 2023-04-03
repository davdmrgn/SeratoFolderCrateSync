import configparser
import os
import re
import struct

homedir = os.path.expanduser('~')

config = configparser.ConfigParser()
config.read('config.txt')
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']

def encode(data):
  key = data[0].encode('utf-8')
  value = data[1].encode('utf-16-be')
  length = struct.pack('>I', len(value))
  return(key + length + value)

# data is an existing decoded crate

i = 0
x = b''
for line in data:
  key = line[0].encode('utf-8')
  if isinstance(line[1], list):
    value = encode(line[1][0])
    length = struct.pack('>I', len(value))
    x += (key + length + value)
  else:
    value = line[1].encode('utf-16-be')
    length = struct.pack('>I', len(value))
    x += (key + length + value)
  i += 1

file = library + '/Subcrates/This better work.crate'
with open(file, 'wb') as crate:
  crate.write(x)
